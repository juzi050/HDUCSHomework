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

    # Free GPU memory from generation
    del outputs
    if torch.cuda.is_available():
        torch.cuda.empty_cache()

    return _postprocess_answer(answer)


def _postprocess_answer(answer):
    """Normalize generated text, remove repeated sentences, and ensure closure."""
    text = (answer or "").strip()

    # Filter out instruction leakage: remove lines that look like system prompt fragments
    if text:
        text = _filter_instruction_leakage(text)

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


def _filter_instruction_leakage(text):
    """Remove lines that look like system prompt fragments leaked into output."""
    leakage_patterns = [
        r"^\s*回答规则[：:]",
        r"^\s*课程范围[：:]",
        r"^\s*格式[：:][\s]*$",
        r"^\s*禁止[：:]*\s*$",
        r"^\s*\d+[.、]\s*\d+[-~]\d+\s*汉字",
        r"^\s*最后一行必须",
        r"^\s*你是\S{2,6}课程助教",
    ]
    lines = text.splitlines()
    filtered = []
    for line in lines:
        stripped = line.strip()
        if not stripped:
            if filtered and filtered[-1]:
                filtered.append("")
            continue
        is_leak = False
        for pattern in leakage_patterns:
            if re.match(pattern, stripped):
                is_leak = True
                break
        if not is_leak:
            filtered.append(line)
    # Clean up trailing lone lines that are likely leakage fragments
    while filtered and re.match(r"^\s*(课程范围|回答规则|格式要求|禁止)[：:]*\s*$", filtered[-1].strip()):
        filtered.pop()
    return "\n".join(filtered).strip()


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
    # Fast path: O(1) exact match lookup
    if not hasattr(_is_seen_sentence, "_exact_set"):
        _is_seen_sentence._exact_set = set()
    exact_set = _is_seen_sentence._exact_set
    if key in exact_set:
        return True

    # Slow path: substring containment and fuzzy matching
    for old_key in seen_sentences:
        short, long = sorted((key, old_key), key=len)
        if len(short) >= 16 and short in long:
            return True
        # Only run expensive SequenceMatcher when lengths are within 30%
        len_ratio = len(short) / max(len(long), 1)
        if len_ratio >= 0.7 and SequenceMatcher(None, key, old_key).ratio() >= 0.94:
            return True

    exact_set.add(key)
    # Keep seen_sentences list capped to avoid unbounded growth
    if len(seen_sentences) > 60:
        seen_sentences[:] = seen_sentences[-40:]
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
    # Skip title-only lines and instruction fragments
    for line in reversed(lines):
        candidate = re.sub(r"^[一二三四五六七八九十\d、.．\s-]+", "", line)
        candidate = re.sub(r"^[\u4e00-\u9fffA-Za-z/]{2,8}[:：]", "", candidate).strip()
        candidate = candidate.rstrip("。；;，, ")
        # Filter out likely instruction leakage fragments
        if re.match(r"^(回答规则|课程范围|格式|禁止|最后|你是)", candidate):
            continue
        if len(candidate) >= 12 and candidate not in ("总结", "归纳", "结论"):
            return candidate
    return ""
