"""RAG engine: keyword-based retrieval with zero external dependencies.

Uses domain-specific keyword matching combined with difflib fuzzy matching
to retrieve relevant course knowledge snippets. No vector DB or embedding
model needed, keeping memory footprint minimal.
"""

import os
import re
from difflib import SequenceMatcher

from .config import RAG_TOP_K, MAX_RAG_CHARS

# Course-specific domain keywords for matching
DOMAIN_KEYWORDS = [
    # RNN / sequence models
    "RNN", "LSTM", "GRU", "循环神经网络", "长短期记忆", "门控循环单元",
    "隐状态", "hidden state", "字符级语言模型", "CharRNN",
    "更新门", "重置门", "遗忘门", "输入门", "输出门", "细胞状态",
    # Style transfer / CNN
    "风格迁移", "style transfer", "VGG", "VGG19",
    "卷积", "convolution", "im2col", "img2col",
    "Gram矩阵", "Gram matrix", "内容损失", "content loss",
    "风格损失", "style loss", "内容图", "风格图",
    "最大池化", "max pooling", "平均池化", "全连接层",
    "边界扩充", "padding", "卷积步长", "stride",
    # Deep learning fundamentals
    "反向传播", "backpropagation", "正向传播", "前向传播",
    "损失函数", "loss function", "交叉熵", "均方误差",
    "优化器", "Adam", "SGD", "随机梯度下降",
    "激活函数", "ReLU", "tanh", "sigmoid", "softmax",
    "归一化", "LayerNorm", "BatchNorm", "层归一化", "批归一化",
    "Dropout", "残差连接", "residual", "残差网络",
    "权重绑定", "weight tying", "权重衰减",
    "困惑度", "perplexity", "准确率",
    "n-gram", "N-gram",
    # Neural network architecture & debugging
    "感知机", "多层感知机", "MLP",
    "计算量", "FLOPs", "乘加", "乘法", "加法",
    "前向传播时间", "推理时间",
    "梯度检查", "数值梯度", "梯度流",
    "数据增强", "正则化", "L1", "L2",
    "学习率", "learning rate", "学习率调度",
    "超参数", "hyperparameter", "alpha", "beta",
    # Deep learning processors
    "深度学习处理器", "TPU", "GPU", "DLP",
    "矩阵运算单元", "向量单元", "标量单元",
    # Transformer / large models
    "Transformer", "注意力机制", "attention",
    "自注意力", "self-attention", "多头注意力",
    "Seq2Seq", "编码器", "解码器",
    "嵌入层", "Embedding",
    "PyTorch", "TensorFlow", "编程框架",
    "计算图", "动态图", "静态图",
    # Model evaluation
    "过拟合", "欠拟合", "交叉验证",
    "图像分类", "目标检测", "图像生成",
    # Training
    "epoch", "batch", "迭代", "收敛",
]


class RAGEngine:
    """Simple keyword + fuzzy matching retrieval engine."""

    def __init__(self, knowledge_base_dir=None):
        """Initialize the RAG engine.

        Args:
            knowledge_base_dir: Path to knowledge base directory.
                If None, uses the built-in knowledge_base/ directory relative
                to this source file.
        """
        if knowledge_base_dir is None:
            knowledge_base_dir = os.path.join(
                os.path.dirname(__file__), "..", "knowledge_base"
            )
        self.kb_dir = os.path.abspath(knowledge_base_dir)
        self.documents = []
        self._load_knowledge_base()

    def _load_knowledge_base(self):
        """Load all .txt and .json files from the knowledge base directory."""
        if not os.path.isdir(self.kb_dir):
            return

        for fname in sorted(os.listdir(self.kb_dir)):
            if not fname.endswith((".txt", ".json")):
                continue
            fpath = os.path.join(self.kb_dir, fname)
            try:
                with open(fpath, "r", encoding="utf-8") as f:
                    content = f.read()
            except Exception:
                continue

            # Split into paragraphs for granular retrieval
            paragraphs = re.split(r"\n\n+", content.strip())
            for para in paragraphs:
                para = para.strip()
                if len(para) > 50:  # Skip very short fragments
                    self.documents.append({
                        "text": para,
                        "source": fname,
                    })

    def retrieve(self, question, top_k=None):
        """Retrieve the most relevant knowledge snippets for a question.

        Args:
            question: The question text.
            top_k: Number of snippets to return (default: RAG_TOP_K).

        Returns:
            List of dicts with 'text' and 'source' keys.
        """
        if top_k is None:
            top_k = RAG_TOP_K

        if not self.documents:
            return []

        # Extract domain keywords from the question
        found_keywords = self._extract_keywords(question)

        # Score each document
        q_lower = question.lower()
        scored = []
        for doc in self.documents:
            doc_lower = doc["text"].lower()

            # Base score: fuzzy sequence similarity
            score = SequenceMatcher(None, q_lower, doc_lower).ratio()

            # Bonus for keyword matches
            for kw in found_keywords:
                if kw.lower() in doc_lower:
                    score += 0.15

            scored.append((score, doc))

        # Sort by score descending, return top_k
        scored.sort(key=lambda x: x[0], reverse=True)

        results = []
        for _, doc in scored[:top_k]:
            # Truncate long snippets
            text = doc["text"]
            if len(text) > MAX_RAG_CHARS:
                text = text[:MAX_RAG_CHARS] + "..."
            results.append({"text": text, "source": doc["source"]})

        return results

    def _extract_keywords(self, text):
        """Extract domain-specific keywords found in the text."""
        found = []
        for kw in DOMAIN_KEYWORDS:
            if kw.lower() in text.lower():
                found.append(kw)
        return found
