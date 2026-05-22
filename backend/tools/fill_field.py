from agno.tools import tool


@tool
def fill_field_normal(field_key: str, field_label: str, value: str) -> dict:
    """代填普通字段"""
    return {"field_key": field_key, "field_label": field_label, "value": value, "is_sensitive": False}


@tool(stop_after_tool_call=True)
def fill_field_sensitive(field_key: str, field_label: str, value: str) -> dict:
    """代填敏感字段（需用户授权）"""
    return {"field_key": field_key, "field_label": field_label, "value": value, "is_sensitive": True}
