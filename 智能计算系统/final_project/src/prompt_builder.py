"""Build chat template messages: system prompt + RAG context + user question.

Uses the Qwen2.5 chat template format with RAG knowledge injected as a
second system message for high-priority context.
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

    # Inject RAG context as a second system message for high-priority grounding
    if rag_context:
        context_text = _format_rag_context(rag_context)
        rag_message = (
            "【重要指令】以下是课程教材中的权威知识片段。你必须严格依据"
            "以下资料回答问题，优先使用资料中的公式、数值和表述。"
            "如果资料中有明确信息，不要用自己的知识替换：\n\n"
            "{}".format(context_text)
        )
        messages.append({"role": "system", "content": rag_message})

    messages.append({"role": "user", "content": question})
    return messages


def _format_rag_context(rag_docs):
    """Format RAG documents into a compact context block."""
    parts = []
    for i, doc in enumerate(rag_docs, 1):
        parts.append("[资料{} 来源: {}]\n{}".format(
            i, doc["source"], doc["text"]
        ))
    return "\n\n---\n\n".join(parts)
