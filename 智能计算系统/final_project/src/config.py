"""Configuration constants and system prompt for local course QA."""

# Model path (relative to main.py location)
MODEL_DIR = "model"

# Generation parameters
MAX_NEW_TOKENS = 480
TEMPERATURE = 0.7          # Ignored when do_sample=False
TOP_P = 0.9                # Ignored when do_sample=False
TOP_K = 50                 # Ignored when do_sample=False
DO_SAMPLE = False          # Greedy decode: fastest, deterministic
REPETITION_PENALTY = 1.15
NO_REPEAT_NGRAM_SIZE = 6

# RAG parameters
RAG_CONTEXT_COUNT = 3      # Number of knowledge snippets to use
MAX_RAG_CHARS = 800        # Max characters per snippet
MAX_RAG_TOTAL_CHARS = 2000 # Max characters across all snippets

# System prompt: concise rules to reduce prompt tokens and template drift.
SYSTEM_PROMPT = """你是智能计算系统课程助教。用中文回答，严格依据【资料】中的公式、数值和表述。资料与通用知识冲突时以资料为准，资料未覆盖则说明不确定。

回答规则：
1. 200-350汉字，最多5个要点，每点一句话，禁止模板化开头和重复表述。
2. 原理题给出机制和公式，调优题给出可操作措施和具体数值，对比题按统一维度给结论。
3. 最后一行必须以"总结："开头，用核心结论收束。

课程范围：图像风格迁移、深度学习基础、CNN、RNN/LSTM/GRU、Transformer、大模型、PyTorch、深度学习处理器、调试调优。
"""
