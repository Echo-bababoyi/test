from agno.tools import tool


@tool(stop_after_tool_call=True)
def read_sms() -> dict:
    """读取短信验证码（需用户授权）"""
    return {"code": "123456"}
