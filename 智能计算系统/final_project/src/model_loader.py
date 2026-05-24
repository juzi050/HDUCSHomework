"""Model loading with int8 quantization and SDPA attention.

Uses bitsandbytes int8 quantization when available (40-45% memory reduction),
falling back to fp16 with SDPA attention. Global cache avoids reloading.
"""

import os
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

from .config import MODEL_DIR

_model = None
_tokenizer = None


def load_model_and_tokenizer():
    """Load model once; cache globally for subsequent calls.

    The evaluator may import or call main.py multiple times. Global caching
    ensures the model is loaded only once, avoiding repeated I/O and GPU
    allocation overhead.
    """
    global _model, _tokenizer
    if _model is not None:
        return _model, _tokenizer

    # Compute model path relative to this file (robust against CWD changes)
    model_path = os.path.join(os.path.dirname(__file__), "..", MODEL_DIR)
    model_path = os.path.abspath(model_path)

    if not os.path.exists(model_path):
        raise FileNotFoundError(
            "Model directory not found: {}. "
            "Please download Qwen2.5-1.5B-Instruct into the model/ folder.".format(
                model_path)
        )

    # Load tokenizer
    _tokenizer = AutoTokenizer.from_pretrained(
        model_path,
        trust_remote_code=True,
        padding_side="left",       # Critical for decoder-only batch=1 generation
    )

    # Ensure pad_token is set (Qwen models may not have it by default)
    if _tokenizer.pad_token is None:
        _tokenizer.pad_token = _tokenizer.eos_token

    # Common kwargs for both int8 and fp16 paths
    common_kwargs = dict(
        device_map="auto",
        trust_remote_code=True,
        low_cpu_mem_usage=True,
        attn_implementation="sdpa",  # PyTorch 2.0+ built-in efficient attention
    )

    # Try int8 quantization first for maximum memory savings
    try:
        from transformers import BitsAndBytesConfig
        quantization_config = BitsAndBytesConfig(load_in_8bit=True)
        _model = AutoModelForCausalLM.from_pretrained(
            model_path,
            quantization_config=quantization_config,
            **common_kwargs,
        )
    except (ImportError, RuntimeError):
        _model = AutoModelForCausalLM.from_pretrained(
            model_path,
            dtype=torch.float16,
            **common_kwargs,
        )

    _model.eval()

    return _model, _tokenizer
