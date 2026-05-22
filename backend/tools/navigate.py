from agno.tools import tool


@tool
def cmd_navigate(target_route: str) -> dict:
    """导航到指定页面"""
    return {"target_route": target_route, "transition": "push"}
