"""Model loading with optimizations: fp16, torch.compile, warm-up, global cache."""

import os
import sys
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

from .config import MODEL_DIR, WARMUP_INPUT

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

    # Load model with optimizations
    _model = AutoModelForCausalLM.from_pretrained(
        model_path,
        dtype=torch.float16,            # Halve memory vs fp32
        device_map="auto",             # Auto-place on GPU
        trust_remote_code=True,
        low_cpu_mem_usage=True,        # Reduce host RAM during loading
    )
    _model.eval()

    # Apply torch.compile for faster inference (PyTorch 2.0+)
    if hasattr(torch, "compile"):
        try:
            print("[INFO] Applying torch.compile (mode=reduce-overhead)...",
                  file=sys.stderr)
            _model = torch.compile(
                _model,
                mode="reduce-overhead",  # Best for repeated inference calls
                fullgraph=False,         # CausalLM has dynamic shapes
            )
        except Exception as exc:
            print("[WARN] torch.compile failed, using uncompiled model: {}".format(exc),
                  file=sys.stderr)

    # Warm-up inference: eliminates torch.compile cold-start latency
    print("[INFO] Running warm-up inference...", file=sys.stderr)
    _warm_up()

    return _model, _tokenizer


def _warm_up():
    """Run a single warm-up inference to trigger compilation and CUDA init."""
    try:
        messages = [{"role": "user", "content": WARMUP_INPUT}]
        text = _tokenizer.apply_chat_template(
            messages,
            tokenize=False,
            add_generation_prompt=True,
            enable_thinking=False,
        )
        inputs = _tokenizer([text], return_tensors="pt").to(_model.device)
        with torch.inference_mode():
            _model.generate(
                **inputs,
                max_new_tokens=16,
                do_sample=False,
                pad_token_id=_tokenizer.pad_token_id,
                eos_token_id=_tokenizer.eos_token_id,
            )
        print("[INFO] Warm-up complete, model ready.", file=sys.stderr)
    except Exception as exc:
        print("[WARN] Warm-up failed (non-fatal): {}".format(exc), file=sys.stderr)
