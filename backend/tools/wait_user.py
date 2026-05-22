from agno.tools import tool


@tool(stop_after_tool_call=True)
def cmd_wait_user(reason: str = "") -> dict:
    """引导步骤的终止工具。调用后等待用户的实际操作（点击高亮元素 / 跳页 / 超时），
    然后由后端自动续传下一步。reason 用于日志，不发前端。"""
    return {"reason": reason}
