"""RAG engine with local text snippets and a prebuilt book index.

The retriever uses lightweight lexical matching only. It has no network calls
and no dependency on vector databases or embedding models.
"""

import json
import math
import os
import re
import unicodedata
from collections import Counter

from .config import RAG_CONTEXT_COUNT, MAX_RAG_CHARS, MAX_RAG_TOTAL_CHARS

RADICAL_REPLACEMENTS = str.maketrans({
    0x2EA0: 0x6C11,  # 民
    0x2EC4: 0x897F,  # 西
    0x2EC5: 0x89C1,  # 见
    0x2EC6: 0x89D2,  # 角
    0x2EC9: 0x8D1D,  # 贝
    0x2ECB: 0x8F66,  # 车
    0x2ED3: 0x957F,  # 长
    0x2ED4: 0x95E8,  # 门
    0x2ED8: 0x9752,  # 青
    0x2EDB: 0x98CE,  # 风
    0x2EDC: 0x98DE,  # 飞
    0x2EDD: 0x98DF,  # 食
    0x2EE2: 0x9A6C,  # 马
    0x2EE3: 0x9AA8,  # 骨
    0x2EE6: 0x9E1F,  # 鸟
    0x2EE9: 0x9EC4,  # 黄
    0x2EEC: 0x9F50,  # 齐
    0x2EEE: 0x9F7F,  # 齿
    0x2EF0: 0x9F99,  # 龙
    0x2EDA: 0x9875,  # 页
})

# Course-specific domain keywords for matching.
DOMAIN_KEYWORDS = [
    # RNN / sequence models
    "RNN", "LSTM", "GRU", "循环神经网络", "长短期记忆", "门控循环单元",
    "隐状态", "hidden state", "字符级语言模型", "CharRNN",
    "更新门", "重置门", "遗忘门", "输入门", "输出门", "细胞状态",
    # Style transfer / CNN
    "风格迁移", "非实时风格迁移", "style transfer", "VGG", "VGG19",
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
    "网络层", "基本单元", "实现正确", "子网络测试",
    "计算量", "FLOPs", "乘加", "乘法", "加法",
    "前向传播时间", "推理时间",
    "梯度检查", "数值梯度", "梯度流",
    "数据增强", "正则化", "L1", "L2",
    "学习率", "learning rate", "学习率调度",
    "超参数", "hyperparameter", "alpha", "beta", "α", "β",
    "提高精度", "网络结构", "修改网络结构", "不改变网络结构",
    "功能调试", "精度调试", "正确性验证", "定位错误",
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
    # Chapter 5: 编程框架原理
    "编程框架", "计算图", "动态图", "静态图", "PyTorch", "TensorFlow",
    "拓扑排序", "算子注册", "算子实现", "分派器", "dispatch",
    "深度学习编译", "TorchDynamo", "TorchInductor", "TorchScript",
    "分布式训练", "参数服务器", "集合通信", "All-Reduce",
    "数据并行", "模型并行", "张量并行", "流水线并行", "混合并行",
    "同步通信", "异步通信", "GPipe", "DeepSpeed", "FSDP",
    "内存池", "内存分配", "即时分配",
    # Chapter 6-7: 深度学习处理器
    "深度学习处理器", "DLP", "智能处理器", "TPU", "GPU",
    "矩阵运算单元", "矩阵乘向量", "矩阵乘法单元", "脉动阵列",
    "内积单元", "乘法器", "加法树", "乘加器",
    "向量运算单元", "标量运算单元",
    "便笺存储器", "Scratchpad", "片上存储",
    "运算密度", "I/O复杂度", "Roofline Model",
    "SIMD", "SIMT", "向量处理器", "寒武纪", "MLU",
    "通用处理器", "CPU", "冯·诺依曼", "哈佛结构",
    "CISC", "RISC", "多发射", "超标量",
    "寄存器重命名", "乱序执行", "Tomasulo",
    "分支预测", "数据前递", "提交队列",
    "UMA", "NUMA", "分形计算模型",
    "指令集", "ISA", "load/store",
    "循环展开", "软件流水",
    "DMA", "双缓冲",
    "片上网络", "NoC", "互联",
    # Chapter 8: 调试与调优
    "功能调试", "精度调试", "性能调优", "profiling",
    "梯度检查", "数值梯度", "解析梯度",
    "算子融合", "混合精度", "损失缩放",
    "内存优化", "数据加载",
    # Chapter 9: 大模型计算系统
    "大模型", "LLM", "大语言模型",
    "算力墙", "存储墙", "通信墙",
    "BLOOM", "GPT", "LLaMA",
    "ZeRO", "重计算", "Gradient Checkpointing",
    "连续批处理", "KV-Cache", "模型压缩",
    "量化", "剪枝", "蒸馏",
    "NVLink", "InfiniBand", "RoCE",
]

TOPIC_PROFILES = {
    "style_transfer": {
        "query": ["风格迁移", "VGG", "VGG19", "Gram", "内容损失", "风格损失", "内容图", "风格图", "im2col"],
        "doc": ["风格迁移", "VGG19", "Gram矩阵", "内容损失", "风格损失", "总损失", "relu4_2", "ALPHA", "BETA"],
        "sources": ["style_transfer.txt"],
    },
    "rnn": {
        "query": ["RNN", "LSTM", "GRU", "CharRNN", "循环神经网络", "长短期记忆", "门控循环单元", "隐状态"],
        "doc": ["CharRNN", "RNN 单元", "LSTM 单元", "GRU 单元", "隐状态", "细胞状态", "困惑度", "训练配置"],
        "sources": ["rnn_experiment.txt"],
    },
    "transformer": {
        "query": ["Transformer", "注意力", "自注意力", "多头注意力", "Seq2Seq", "编码器", "解码器"],
        "doc": ["Transformer", "注意力机制", "自注意力", "自注意力层", "缩放点积注意力", "多头注意力", "编码器", "解码器", "位置编码", "注意力权重"],
        "sources": ["textbook_v2", "advanced_topics.txt"],
    },
    "processor": {
        "query": ["处理器", "DLP", "GPU", "TPU", "脉动阵列", "SIMD", "SIMT", "Scratchpad", "Roofline"],
        "doc": ["深度学习处理器", "矩阵运算单元", "脉动阵列", "便笺存储器", "片上存储", "Roofline", "SIMD", "SIMT"],
        "sources": ["textbook_v2", "advanced_topics.txt"],
    },
    "debug_tuning": {
        "query": ["调试", "调优", "性能", "精度", "梯度检查", "混合精度", "算子融合", "内存优化"],
        "doc": ["功能调试", "精度调试", "性能调优", "梯度检查", "算子融合", "混合精度", "内存优化", "数据加载"],
        "sources": ["textbook_v2", "advanced_topics.txt"],
    },
    "framework": {
        "query": ["PyTorch", "TensorFlow", "编程框架", "计算图", "动态图", "静态图", "算子", "分布式训练"],
        "doc": ["编程框架", "计算图", "动态图", "静态图", "PyTorch", "TensorFlow", "算子注册", "分派器", "All-Reduce"],
        "sources": ["textbook_v2", "advanced_topics.txt"],
    },
}

SOURCE_WEIGHTS = {
    "style_transfer.txt": 1.8,
    "rnn_experiment.txt": 1.8,
    "advanced_topics.txt": 1.15,
    "dl_fundamentals.txt": 1.3,
}


class RAGEngine:
    """Simple local retriever for course material."""

    def __init__(self, knowledge_base_dir=None):
        """Initialize the RAG engine.

        Args:
            knowledge_base_dir: Path to knowledge base directory. If omitted,
                uses the built-in knowledge_base/ directory.
        """
        if knowledge_base_dir is None:
            knowledge_base_dir = os.path.join(
                os.path.dirname(__file__), "..", "knowledge_base"
            )
        self.kb_dir = os.path.abspath(knowledge_base_dir)
        self.documents = []
        self.idf = {}
        self.avg_doc_len = 1.0
        self._load_knowledge_base()
        self._prepare_statistics()

    def _load_knowledge_base(self):
        """Load text files and JSONL snippets from the knowledge base."""
        if not os.path.isdir(self.kb_dir):
            return

        for fname in sorted(os.listdir(self.kb_dir)):
            fpath = os.path.join(self.kb_dir, fname)
            if fname.endswith(".txt"):
                self._load_text_file(fpath, fname)
            elif fname.endswith(".jsonl"):
                self._load_jsonl_file(fpath, fname)

    def _load_text_file(self, fpath, fname):
        try:
            with open(fpath, "r", encoding="utf-8") as f:
                content = self._normalize_text(f.read())
        except Exception:
            return

        current_lines = []
        current_section = ""
        for raw_line in content.splitlines():
            line = raw_line.strip()
            if not line:
                if current_lines:
                    current_lines.append("")
                continue

            if self._is_section_heading(line) and current_lines:
                self._append_text_blocks(fname, current_section, current_lines)
                current_lines = []

            if self._is_section_heading(line):
                current_section = self._guess_section(line)
            current_lines.append(line)

        if current_lines:
            self._append_text_blocks(fname, current_section, current_lines)

    def _append_text_blocks(self, fname, section, lines):
        paragraphs = re.split(r"\n\s*\n", "\n".join(lines).strip())
        current = ""
        for para in paragraphs:
            para = para.strip()
            if not para:
                continue
            if current and len(current) + len(para) + 2 > MAX_RAG_CHARS:
                self._append_text_document(fname, section, current)
                current = para
            else:
                current = "{}\n\n{}".format(current, para) if current else para
        if current:
            self._append_text_document(fname, section, current)

    def _append_text_document(self, fname, section, text):
        if len(text) <= 50:
            return
        self.documents.append({
            "text": text,
            "source": fname,
            "section": section or self._guess_section(text),
            "page_start": None,
            "page_end": None,
            "weight": self._source_weight(fname),
        })

    def _load_jsonl_file(self, fpath, fname):
        try:
            with open(fpath, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        item = json.loads(line)
                    except ValueError:
                        continue
                    text = self._normalize_text(item.get("text", "")).strip()
                    if len(text) <= 50:
                        continue
                    self.documents.append({
                        "text": text,
                        "source": item.get("source") or fname,
                        "section": item.get("section") or "",
                        "page_start": item.get("page_start"),
                        "page_end": item.get("page_end"),
                        "weight": self._source_weight(item.get("source") or fname),
                    })
        except Exception:
            return

    def _prepare_statistics(self):
        doc_freq = Counter()
        total_terms = 0
        for doc in self.documents:
            terms = Counter(self._tokenize(doc["text"]))
            doc["terms"] = terms
            doc["term_total"] = max(sum(terms.values()), 1)
            total_terms += doc["term_total"]
            doc["compact"] = self._compact_text(doc["text"])
            doc_freq.update(terms.keys())

        total_docs = max(len(self.documents), 1)
        self.avg_doc_len = max(total_terms / total_docs, 1.0)
        self.idf = {
            term: math.log((1 + total_docs) / (1 + freq)) + 1.0
            for term, freq in doc_freq.items()
        }

    def retrieve(self, question, context_count=None):
        """Retrieve relevant knowledge snippets for a question."""
        if context_count is None:
            context_count = RAG_CONTEXT_COUNT

        if not self.documents:
            return []

        query_terms = Counter(self._tokenize(question))
        found_keywords = self._extract_keywords(question)
        found_phrases = self._extract_question_phrases(question)
        found_topics = self._detect_topics(question)
        if not query_terms and not found_keywords:
            return []

        candidates = []
        for doc in self.documents:
            relevance = self._compute_relevance(
                query_terms, found_keywords, found_phrases, found_topics, doc
            )
            if relevance > 0:
                candidates.append((relevance, doc))

        candidates.sort(key=lambda item: item[0], reverse=True)
        return self._build_results(candidates, context_count)

    def _compute_relevance(self, query_terms, found_keywords, found_phrases, found_topics, doc):
        relevance = 0.0
        k1 = 1.4
        b = 0.75
        doc_len = doc.get("term_total", 1)
        for term, query_freq in query_terms.items():
            doc_freq = doc["terms"].get(term, 0)
            if not doc_freq:
                continue
            term_weight = self.idf.get(term, 1.0)
            length_factor = k1 * (1.0 - b + b * doc_len / self.avg_doc_len)
            relevance += term_weight * doc_freq * (k1 + 1.0) / (
                doc_freq + length_factor
            )
            if query_freq > 1:
                relevance += 0.15 * min(query_freq, 3) * term_weight

        doc_compact = doc["compact"]
        for kw in found_keywords:
            kw_compact = self._compact_text(kw)
            if kw_compact and kw_compact in doc_compact:
                relevance += 4.0 + min(len(kw_compact), 12) * 0.35

        for phrase in found_phrases:
            if phrase in doc_compact:
                relevance += 3.0 + min(len(phrase), 12) * 0.25

        relevance += self._topic_bonus(found_topics, doc)
        return relevance * doc.get("weight", 1.0)

    def _detect_topics(self, text):
        text_compact = self._compact_text(text)
        topics = []
        for topic, profile in TOPIC_PROFILES.items():
            for marker in profile["query"]:
                marker_compact = self._compact_text(marker)
                if marker_compact and marker_compact in text_compact:
                    topics.append(topic)
                    break
        return topics

    def _topic_bonus(self, found_topics, doc):
        if not found_topics:
            return 0.0

        source = doc.get("source", "").lower()
        doc_compact = doc["compact"]
        bonus = 0.0
        for topic in found_topics:
            profile = TOPIC_PROFILES[topic]
            if source in profile.get("sources", []):
                bonus += 3.0
            hits = 0
            for marker in profile["doc"]:
                marker_compact = self._compact_text(marker)
                if marker_compact and marker_compact in doc_compact:
                    hits += 1
            if hits:
                bonus += min(4.0, 1.2 + hits * 0.6)
        return bonus

    def _build_results(self, candidates, context_count):
        results = []
        used_chars = 0
        seen = set()
        source_without_page_counts = Counter()

        for _, doc in candidates:
            if len(results) >= context_count or used_chars >= MAX_RAG_TOTAL_CHARS:
                break

            text = doc["text"]
            source = doc["source"]
            page_start = doc.get("page_start")
            dedupe_key = (doc["source"], doc.get("page_start"), text[:80])
            if dedupe_key in seen:
                continue

            source_limit = 2 if source.endswith(".txt") else 1
            if page_start is None and source_without_page_counts[source] >= source_limit:
                continue

            seen.add(dedupe_key)

            remaining = MAX_RAG_TOTAL_CHARS - used_chars
            limit = min(MAX_RAG_CHARS, remaining)
            if limit <= 120:
                break
            if len(text) > limit:
                suffix = "..."
                text = text[:limit - len(suffix)].rstrip() + suffix

            used_chars += len(text)
            if page_start is None:
                source_without_page_counts[source] += 1
            results.append({
                "text": text,
                "source": source,
                "section": doc.get("section") or "",
                "page_start": page_start,
                "page_end": doc.get("page_end"),
            })

        return results

    def _extract_keywords(self, text):
        """Extract course keywords found in the question."""
        found = []
        text_norm = self._compact_text(text)
        for kw in DOMAIN_KEYWORDS:
            kw_norm = self._compact_text(kw)
            if kw_norm and kw_norm in text_norm:
                found.append(kw)
        return found

    def _extract_question_phrases(self, text):
        phrases = set()
        normalized = self._normalize_text(text)
        for run in re.findall(r"[\u4e00-\u9fff]{4,}", normalized):
            max_size = min(8, len(run))
            for size in range(4, max_size + 1):
                for start in range(0, len(run) - size + 1, 2):
                    phrases.add(run[start:start + size])
        return phrases

    def _tokenize(self, text):
        text = self._normalize_text(text).lower()
        tokens = re.findall(r"[a-z0-9]+(?:[-_][a-z0-9]+)*", text)
        for run in re.findall(r"[\u4e00-\u9fff]+", text):
            tokens.extend(run)
            tokens.extend(run[i:i + 2] for i in range(len(run) - 1))
        return tokens

    def _compact_text(self, text):
        return re.sub(r"\s+", "", self._normalize_text(text).lower())

    def _normalize_text(self, text):
        text = unicodedata.normalize("NFKC", text or "")
        text = text.translate(RADICAL_REPLACEMENTS)
        text = text.replace("α", " alpha ").replace("β", " beta ")
        text = text.replace("γ", " gamma ").replace("δ", " delta ")
        text = text.replace("ε", " epsilon ")
        return re.sub(r"[ \t\r\f\v]+", " ", text)

    def _guess_section(self, text):
        for line in text.splitlines():
            line = line.strip()
            if line.startswith("【") and line.endswith("】"):
                return line.strip("【】")
            if line.startswith("==="):
                return line.strip("= ").strip()
        return ""

    def _is_section_heading(self, line):
        return (
            (line.startswith("【") and line.endswith("】"))
            or (line.startswith("===") and line.endswith("==="))
        )

    def _source_weight(self, source):
        return SOURCE_WEIGHTS.get(source, 1.0)
