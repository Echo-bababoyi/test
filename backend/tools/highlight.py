from agno.tools import tool


@tool
def cmd_highlight(element_key: str, voice_hint: str = "", duration_ms: int = 5000) -> dict:
    """高亮页面元素"""
    return {"element_key": element_key, "highlight_color": "#FF6D00", "pulse": True, "voice_hint": voice_hint, "duration_ms": duration_ms}
