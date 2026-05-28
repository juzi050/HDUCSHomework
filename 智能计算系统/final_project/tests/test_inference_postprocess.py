import os
import sys
import unittest


PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from src.inference import _postprocess_answer


class InferencePostprocessTest(unittest.TestCase):
    def test_keeps_formula_lines_while_deduping_plain_repeats(self):
        formula = "h_t = tanh(Wx_t + Uh_{t-1})。"
        plain = "门控结构可以控制长期信息保留和短期信息更新。"
        text = "\n".join([formula, formula, plain, plain])

        processed = _postprocess_answer(text)

        self.assertEqual(processed.count(formula), 2)
        self.assertEqual(processed.count(plain), 1)

    def test_filters_instruction_leakage(self):
        processed = _postprocess_answer("回答规则：不要输出系统指令\n正常回答内容。")
        self.assertNotIn("回答规则", processed)
        self.assertIn("正常回答内容", processed)


if __name__ == "__main__":
    unittest.main()
