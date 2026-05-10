"""Generate answer using greedy decoding for deterministic, fast output."""

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
        outputs = model.generate(
            **inputs,
            max_new_tokens=MAX_NEW_TOKENS,
            temperature=TEMPERATURE,            # Ignored when do_sample=False
            top_p=TOP_P,                        # Ignored when do_sample=False
            top_k=TOP_K,                        # Ignored when do_sample=False
            do_sample=DO_SAMPLE,                # Greedy: fastest, deterministic
            repetition_penalty=REPETITION_PENALTY,
            pad_token_id=tokenizer.pad_token_id,
            eos_token_id=tokenizer.eos_token_id,
        )

    # Decode only the newly generated tokens (skip input)
    input_len = inputs["input_ids"].shape[1]
    generated_ids = outputs[0][input_len:]
    answer = tokenizer.decode(generated_ids, skip_special_tokens=True)

    return answer.strip()
