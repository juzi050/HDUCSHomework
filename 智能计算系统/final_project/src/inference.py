"""Generate answer using greedy decoding for deterministic, fast output."""

import re

import torch

from .config import (
    MAX_NEW_TOKENS,
    TEMPERATURE,
    TOP_P,
    TOP_K,
    DO_SAMPLE,
    REPETITION_PENALTY,
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
    """Normalize generated text and remove exact repeats."""
    text = (answer or "").strip()

    # Filter out instruction leakage: remove lines that look like system prompt fragments
    if text:
        text = _filter_instruction_leakage(text)

    text = re.sub(r"[ \t\r\f\v]+", " ", text)
    raw_lines = [line.strip() for line in text.splitlines()]

    lines = []
    seen_sentences = set()
    for line in raw_lines:
        if not line:
            if lines and lines[-1]:
                lines.append("")
            continue
        cleaned = _dedupe_sentences(line, seen_sentences)
        if not cleaned:
            continue
        lines.append(cleaned)

    return "\n".join(lines).strip()


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


def _dedupe_sentences(line, seen_sentences):
    pieces = _split_sentences(line)
    kept = []
    for piece in pieces:
        key = _sentence_key(piece)
        if key and key in seen_sentences:
            continue
        if key:
            seen_sentences.add(key)
        kept.append(piece)
    return "".join(kept).strip()


def _split_sentences(line):
    return re.findall(r".+?[。！？；;!?]|.+$", line)


def _sentence_key(sentence):
    sentence = sentence.strip()
    if len(sentence) < 10 or _looks_like_formula(sentence):
        return ""
    key = re.sub(r"^[\d一二三四五六七八九十、.．\s-]+", "", sentence)
    key = re.sub(r"^[\u4e00-\u9fffA-Za-z/]{2,8}[:：]", "", key)
    key = re.sub(r"[，,。；;：:\s（）()、\"'“”‘’]", "", key.lower())
    if len(key) < 8:
        return ""
    return key


def _looks_like_formula(sentence):
    return bool(re.search(r"[=+\-*/^∑Σ√≤≥<>]|\\frac|\\sum|_[{a-zA-Z0-9]", sentence))
