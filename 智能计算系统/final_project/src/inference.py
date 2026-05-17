"""Generate answer using greedy decoding for deterministic, fast output."""

import re
from difflib import SequenceMatcher

import torch

from .config import (
    MAX_NEW_TOKENS,
    TEMPERATURE,
    TOP_P,
    TOP_K,
    DO_SAMPLE,
    REPETITION_PENALTY,
    NO_REPEAT_NGRAM_SIZE,
)


def generate_answer(model, tokenizer, inputs):
    """Run model.generate with greedy decoding.

    Args:
        model: The loaded HuggingFace CausalLM model.
        tokenizer: The loaded tokenizer.
        inputs: Tokenized inputs dict with 'input_ids' and 'attention_mask'.

    Returns:
        Decoded answer string (whitespace stripped).
    """
    with torch.inference_mode():
        generate_kwargs = {
            "max_new_tokens": MAX_NEW_TOKENS,
            "do_sample": DO_SAMPLE,
            "repetition_penalty": REPETITION_PENALTY,
            "no_repeat_ngram_size": NO_REPEAT_NGRAM_SIZE,
            "pad_token_id": tokenizer.pad_token_id,
            "eos_token_id": tokenizer.eos_token_id,
        }
        # Only pass sampling params when actually sampling
        if DO_SAMPLE:
            generate_kwargs["temperature"] = TEMPERATURE
            generate_kwargs["top_p"] = TOP_P
            generate_kwargs["top_k"] = TOP_K

        outputs = model.generate(**inputs, **generate_kwargs)

    # Decode only the newly generated tokens (skip input)
    input_len = inputs["input_ids"].shape[1]
    generated_ids = outputs[0][input_len:]
    answer = tokenizer.decode(generated_ids, skip_special_tokens=True)

    return _postprocess_answer(answer)


def _postprocess_answer(answer):
    """Normalize generated text, remove repeated sentences, and ensure closure."""
    text = (answer or "").strip()
    if not text:
        return "总结：根据现有资料暂时无法形成可靠回答。"

    text = re.sub(r"[ \t\r\f\v]+", " ", text)
    raw_lines = [line.strip() for line in text.splitlines()]

    lines = []
    seen_sentences = []
    seen_titles = set()
    saw_summary = False
    for line in raw_lines:
        if not line:
            if lines and lines[-1]:
                lines.append("")
            continue
        if _is_repeated_title(line, seen_titles):
            continue
        cleaned = _dedupe_sentences(line, seen_sentences)
        if not cleaned:
            continue
        lines.append(cleaned)
        if cleaned.startswith("总结："):
            saw_summary = True
            break

    text = "\n".join(lines).strip()
    if saw_summary:
        text = _keep_first_summary(text)
    elif not _has_summary_line(text):
        summary = _build_fallback_summary(text)
        text = text.rstrip("。；;，, \n")
        text = "{}\n总结：{}".format(text, summary)
    return text


def _has_summary_line(text):
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    return bool(lines and lines[-1].startswith("总结："))


def _is_repeated_title(line, seen_titles):
    title = line.strip()
    if not re.fullmatch(r"[一二三四五六七八九十\d、.．\s-]*[\u4e00-\u9fffA-Za-z/]{2,12}[:：]", title):
        return False
    key = re.sub(r"[\s\d一二三四五六七八九十、.．-]+", "", title)
    if key in seen_titles:
        return True
    seen_titles.add(key)
    return False


def _dedupe_sentences(line, seen_sentences):
    pieces = _split_sentences(line)
    kept = []
    for piece in pieces:
        key = _sentence_key(piece)
        if key and _is_seen_sentence(key, seen_sentences):
            continue
        if key:
            seen_sentences.append(key)
        kept.append(piece)
    return "".join(kept).strip()


def _split_sentences(line):
    return re.findall(r".+?[。！？；;!?]|.+$", line)


def _sentence_key(sentence):
    sentence = sentence.strip()
    if len(sentence) < 14 or _looks_like_formula(sentence):
        return ""
    key = re.sub(r"^[\d一二三四五六七八九十、.．\s-]+", "", sentence)
    key = re.sub(r"^[\u4e00-\u9fffA-Za-z/]{2,8}[:：]", "", key)
    key = re.sub(r"[，,。；;：:\s（）()、\"'“”‘’]", "", key.lower())
    if len(key) < 10:
        return ""
    return key


def _is_seen_sentence(key, seen_sentences):
    for old_key in seen_sentences:
        if key == old_key:
            return True
        short, long = sorted((key, old_key), key=len)
        if len(short) >= 16 and short in long:
            return True
        if SequenceMatcher(None, key, old_key).ratio() >= 0.94:
            return True
    return False


def _looks_like_formula(sentence):
    return bool(re.search(r"[=+\-*/^∑Σ√≤≥<>]|\\frac|\\sum", sentence))


def _keep_first_summary(text):
    lines = []
    for line in text.splitlines():
        lines.append(line)
        if line.strip().startswith("总结："):
            break
    return "\n".join(lines).strip()


def _build_fallback_summary(text):
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    for line in reversed(lines):
        line = re.sub(r"^[一二三四五六七八九十\d、.．\s-]+", "", line)
        line = re.sub(r"^[\u4e00-\u9fffA-Za-z/]{2,8}[:：]", "", line).strip()
        line = line.rstrip("。；;，, ")
        if len(line) >= 8 and line != "总结":
            return line
    return "根据上文可得出这一题的核心结论。"
