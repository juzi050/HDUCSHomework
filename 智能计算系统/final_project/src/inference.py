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

    return _postprocess_answer(answer)


def _postprocess_answer(answer):
    """Normalize generated text and add a minimal complete ending if needed."""
    text = (answer or "").strip()
    if not text:
        return "总结：根据现有资料暂时无法形成可靠回答。"

    text = re.sub(r"[ \t\r\f\v]+", " ", text)
    raw_lines = [line.strip() for line in text.splitlines()]

    lines = []
    previous = None
    for line in raw_lines:
        if not line:
            if lines and lines[-1]:
                lines.append("")
            continue
        if line == previous:
            continue
        lines.append(line)
        previous = line

    text = "\n".join(lines).strip()
    if not _has_summary_line(text):
        text = text.rstrip("。；;，, \n")
        text = "{}\n总结：以上要点概括了问题的核心结论和主要依据。".format(text)
    return text


def _has_summary_line(text):
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    return bool(lines and lines[-1].startswith("总结："))
