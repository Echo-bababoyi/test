from agno.tools import tool


@tool
def cmd_press_button(button_key: str, button_label: str, voice_hint: str = "") -> dict:
    """代按非确定性按钮（如"查询"）"""
    return {"button_key": button_key, "button_label": button_label, "is_deterministic": False, "voice_hint": voice_hint}
