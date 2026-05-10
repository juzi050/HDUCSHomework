"""Configuration constants and system prompt for the leaderboard competition."""

# Model path (relative to main.py location)
MODEL_DIR = "model"

# Generation parameters
MAX_NEW_TOKENS = 512
TEMPERATURE = 0.7          # Ignored when do_sample=False
TOP_P = 0.9                # Ignored when do_sample=False
TOP_K = 50                 # Ignored when do_sample=False
DO_SAMPLE = False          # Greedy decode: fastest, deterministic
REPETITION_PENALTY = 1.05

# RAG parameters
RAG_TOP_K = 3              # Number of knowledge snippets to retrieve
MAX_RAG_CHARS = 1500       # Max characters per RAG snippet

# Warm-up input (eliminates torch.compile cold-start latency)
WARMUP_INPUT = "你好"

# System prompt: modular sections for clarity
SYSTEM_PROMPT = """你是一位智能计算系统课程的专家助教。请根据以下规则回答学生的问题：

【回答规则】
1. 使用中文回答，保持专业性和准确性
2. 如果问题涉及卷积神经网络（CNN）、循环神经网络（RNN/LSTM/GRU）、风格迁移、VGG19、深度学习处理器等内容，请引用课程教材中的具体知识和细节
3. 如果问题涉及算法原理或公式，请给出清晰的公式或伪代码说明
4. 如果问题涉及超参数或训练配置，请给出课程实验中的具体数值
5. 回答长度适中，直接回答问题的核心，避免冗余
6. 如果问题问到课程实验中用到的具体实现细节，请优先从课程代码和实验报告中引用
7. 不确定的内容请明确说明"根据现有知识不确定"，不要编造

【课程背景】
本课程以"图像风格迁移"为驱动范例，涵盖深度学习基础（机器学习、神经网络、反向传播）、深度学习应用（CNN、RNN/LSTM/GRU、Transformer、大模型）、编程框架（PyTorch）以及深度学习处理器架构等内容。课程实验包括字符级RNN文本生成和基于VGG19的图像风格迁移。
"""
