"""Model loading with fp16 and a process-local cache."""

import os
import sys
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
        print("[ERROR] Model directory not found: {}".format(model_path),
              file=sys.stderr)
        raise FileNotFoundError(
            "Model directory not found: {}. "
            "Please download Qwen2.5-1.5B-Instruct into the model/ folder.".format(
                model_path)
        )

    print("[INFO] Loading tokenizer from {}".format(model_path), file=sys.stderr)

    # Load tokenizer
    _tokenizer = AutoTokenizer.from_pretrained(
        model_path,
        trust_remote_code=True,
        padding_side="left",       # Critical for decoder-only batch=1 generation
    )

    # Ensure pad_token is set (Qwen models may not have it by default)
    if _tokenizer.pad_token is None:
        _tokenizer.pad_token = _tokenizer.eos_token

    print("[INFO] Loading model (fp16, device_map=auto)...", file=sys.stderr)

    # Load model with moderate memory use.
    _model = AutoModelForCausalLM.from_pretrained(
        model_path,
        dtype=torch.float16,            # Halve memory vs fp32
        device_map="auto",             # Auto-place on GPU
        trust_remote_code=True,
        low_cpu_mem_usage=True,        # Reduce host RAM during loading
    )
    _model.eval()

    return _model, _tokenizer
