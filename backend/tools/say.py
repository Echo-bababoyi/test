from agno.tools import tool


@tool
def cmd_say(voice_hint: str) -> dict:
    """纯语音提示，不操作页面（引导级核心工具）"""
    return {"voice_hint": voice_hint}
