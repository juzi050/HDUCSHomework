"""Configuration constants and system prompt for local course QA."""

# Model path (relative to main.py location)
MODEL_DIR = "model"

# Generation parameters
MAX_NEW_TOKENS = 640
TEMPERATURE = 0.7          # Ignored when do_sample=False
TOP_P = 0.9                # Ignored when do_sample=False
TOP_K = 50                 # Ignored when do_sample=False
DO_SAMPLE = False          # Greedy decode: fastest, deterministic
REPETITION_PENALTY = 1.12
NO_REPEAT_NGRAM_SIZE = 8

# RAG parameters
RAG_CONTEXT_COUNT = 3      # Number of knowledge snippets to use
MAX_RAG_CHARS = 1000       # Max characters per snippet
MAX_RAG_TOTAL_CHARS = 2400 # Max characters across all snippets

# System prompt: concise rules to reduce prompt tokens and template drift.
SYSTEM_PROMPT = """你是智能计算系统课程助教。用中文回答，优先依据后续【资料】中的公式、数值和表述；资料与通用知识冲突时以资料为准，资料未覆盖则说明“根据现有资料不确定”。

回答要求：
1. 先内部判断题型，不输出题型标签；原理题讲机制和公式，调优题给可操作措施，对比题按同一维度给结论。
2. 回答约240到380个汉字，最多6个要点，每个要点只讲一个不同信息点，避免模板化和重复改写。
3. 涉及实验、超参数或训练配置时给出课程资料中的具体数值。
4. 最后一行必须以“总结：”开头，用具体结论完整收束。

课程范围包括图像风格迁移、深度学习基础、CNN、RNN/LSTM/GRU、Transformer、大模型、PyTorch、深度学习处理器和调试调优。
"""
