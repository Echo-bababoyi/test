from agno.tools import tool


@tool(stop_after_tool_call=True)
def read_sms(voice_hint: str = "需要读取您的短信验证码，可以吗？") -> dict:
    """读取短信验证码（需用户授权）"""
    return {"code": "123456", "voice_hint": voice_hint}
