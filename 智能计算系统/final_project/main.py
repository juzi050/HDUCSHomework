#!/usr/bin/env python3
"""Intelligent Computing System Final Project local QA entry point.

Usage:
    python main.py "question text"
    python main.py "question text" "path/to/knowledge_base"

The runner invokes this script with the question as sys.argv[1] and an
optional knowledge base path as sys.argv[2]. The answer is written to stdout
and must not be empty.
"""

import sys
import time
import gc

# Add the project root to sys.path so relative imports work when run as script
import os
_project_root = os.path.dirname(os.path.abspath(__file__))
if _project_root not in sys.path:
    sys.path.insert(0, _project_root)

import torch

from src.config import SYSTEM_PROMPT
from src.model_loader import load_model_and_tokenizer
from src.rag_engine import RAGEngine
from src.prompt_builder import build_prompt
from src.inference import generate_answer


def main():
    # Parse command-line arguments
    if len(sys.argv) < 2:
        raise SystemExit("Usage: python main.py <question> [knowledge_base_path]")

    question = sys.argv[1]
    kb_path = sys.argv[2] if len(sys.argv) >= 3 else None

    start_time = time.perf_counter()

    # Load model (lazy, global cache: first call loads, subsequent calls reuse)
    print("[INFO] Loading model...", file=sys.stderr)
    model, tokenizer = load_model_and_tokenizer()

    # Initialize RAG engine (supports external knowledge base path)
    print("[INFO] Initializing knowledge base...", file=sys.stderr)
    rag = RAGEngine(knowledge_base_dir=kb_path)

    # Retrieve relevant course knowledge
    rag_context = rag.retrieve(question)
    if rag_context:
        print("[INFO] Retrieved {} knowledge snippets.".format(len(rag_context)),
              file=sys.stderr)

    # Build chat prompt
    messages = build_prompt(
        question=question,
        rag_context=rag_context,
    )

    # Apply chat template
    text = tokenizer.apply_chat_template(
        messages,
        tokenize=False,
        add_generation_prompt=True,
        enable_thinking=False,  # Disable Qwen3 thinking mode for faster QA
    )
    inputs = tokenizer([text], return_tensors="pt").to(model.device)

    # Generate answer
    print("[INFO] Generating answer...", file=sys.stderr)
    answer = generate_answer(model, tokenizer, inputs)

    # Free input tensors and GPU memory
    del inputs
    gc.collect()
    if torch.cuda.is_available():
        torch.cuda.empty_cache()

    elapsed = time.perf_counter() - start_time
    print("[INFO] Inference completed in {:.2f}s".format(elapsed), file=sys.stderr)

    # Output answer to stdout (and ONLY the answer)
    if not answer:
        # Never output an empty answer — the evaluator considers it a failure
        answer = "抱歉，我暂时无法回答这个问题。"

    print(answer, end="", flush=True)


if __name__ == "__main__":
    main()
