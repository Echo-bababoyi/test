from agno.tools import tool


@tool(stop_after_tool_call=True)
def cmd_ask_user(question: str, options: list[str] | None = None) -> dict:
    """向用户提问并暂停，等用户回答后由后端自动续传。
    options 非空时前端渲染为选择按钮（适合"本人/配偶/子女"这类有限选项）；
    为空时让用户自由输入文字（如身份证号）。question 会播报 + 入聊天气泡。"""
    return {"question": question, "options": options or []}
