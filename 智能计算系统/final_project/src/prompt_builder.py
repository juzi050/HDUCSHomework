"""Build chat template messages: system prompt + RAG context + user question.

Uses the Qwen2.5 chat template format with RAG knowledge injected as a
second system message for course context.
"""

from .config import SYSTEM_PROMPT


def build_prompt(question, rag_context=None, system_prompt=None):
    """Build the chat template messages for generation.

    Args:
        question: The user's question text.
        rag_context: List of dicts with 'text' and 'source' from RAGEngine.
        system_prompt: Override the default system prompt (optional).

    Returns:
        List of message dicts in OpenAI chat format.
    """
    if system_prompt is None:
        system_prompt = SYSTEM_PROMPT

    messages = [{"role": "system", "content": system_prompt}]

    # Inject RAG context as a second system message for course grounding.
    if rag_context:
        context_text = _format_rag_context(rag_context)
        rag_message = (
            "【重要指令】以下是课程教材中的权威知识片段。你必须严格依据"
            "以下资料回答问题，优先使用资料中的公式、数值和表述。"
            "如果资料中有明确信息，不要用自己的知识替换。"
            "请在内部区分题型，但不要额外输出题型标签；回答按"
            "结论、关键公式/步骤、影响分析组织，最多6个要点。"
            "请控制篇幅并在最后一行用“总结：”完整收尾：\n\n"
            "{}".format(context_text)
        )
        messages.append({"role": "system", "content": rag_message})

    messages.append({"role": "user", "content": question})
    return messages


def _format_rag_context(rag_docs):
    """Format RAG documents into a compact context block."""
    parts = []
    for i, doc in enumerate(rag_docs, 1):
        location = _format_location(doc)
        parts.append("[资料{} {}]\n{}".format(i, location, doc["text"]))
    return "\n\n---\n\n".join(parts)


def _format_location(doc):
    source = doc.get("source", "knowledge_base")
    page_start = doc.get("page_start")
    page_end = doc.get("page_end")
    section = doc.get("section")

    details = ["来源: {}".format(source)]
    if page_start:
        if page_end and page_end != page_start:
            details.append("页码: {}-{}".format(page_start, page_end))
        else:
            details.append("页码: {}".format(page_start))
    if section:
        details.append("章节: {}".format(section))
    return " ".join(details)
