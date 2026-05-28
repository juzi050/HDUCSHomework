import os
import sys
import unittest


PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from src.rag_engine import RAGEngine


class RAGRetrievalTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rag = RAGEngine()

    def _retrieve(self, question):
        docs = self.rag.retrieve(question)
        self.assertTrue(docs, "RAG should return at least one document")
        return docs

    def test_lstm_gradient_vanishing_hits_rnn_and_textbook(self):
        docs = self._retrieve("LSTM 为什么能缓解普通 RNN 的梯度消失？")
        sources = [doc["source"] for doc in docs]
        self.assertIn("rnn_experiment.txt", sources)
        self.assertIn("textbook_v2", sources)

    def test_transformer_attention_hits_attention_context(self):
        docs = self._retrieve("Transformer 中多头自注意力的作用是什么？")
        self.assertTrue(
            any("注意力" in doc["text"] for doc in docs),
            "Transformer question should retrieve attention content",
        )

    def test_processor_storage_hits_dlp_context(self):
        docs = self._retrieve("深度学习处理器为什么需要片上存储和数据复用？")
        joined = "\n".join(doc["text"] for doc in docs)
        self.assertTrue(
            any(term in joined for term in ("Scratchpad", "片上存储", "Roofline")),
            "Processor question should retrieve DLP storage/reuse content",
        )

    def test_training_diagnosis_prefers_high_level_guidance(self):
        docs = self._retrieve("模型精度不够时如何调试和调优？")
        top_sources = {doc["source"] for doc in docs[:2]}
        self.assertTrue(
            top_sources.intersection({"dl_fundamentals.txt", "advanced_topics.txt"}),
            "Diagnosis question should prefer high-level tuning notes",
        )
        low_level_markers = ("focus命令", "break命令", "__vector")
        self.assertFalse(
            any(marker in docs[0]["text"] for marker in low_level_markers),
            "Top diagnosis result should not be a low-level debug command snippet",
        )


if __name__ == "__main__":
    unittest.main()
