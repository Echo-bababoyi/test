from agno.tools import tool


@tool(
    name="navigate_to",
    description=(
        "跳转到应用中的某个页面。"
        "path 必须是有效路由，如 /elder、/my、/search、"
        "/service/social-insurance、/service/pension-query。"
        "reason 是给用户看的口语说明，如'帮您打开养老金查询页面'。"
    ),
)
def navigate_to(path: str, reason: str) -> dict:
    """导航到指定页面，返回 intent 结构供调用方构造 intent_proposal。"""
    return {
        "intent_type": "NavigateTo",
        "params": {"path": path},
        "reason": reason,
    }


@tool(
    name="explain_term",
    description=(
        "用通俗语言解释应用里的专业术语。"
        "term 是术语名称，explanation 是面向老年用户的口语化解释，"
        "不超过 50 字。"
    ),
)
def explain_term(term: str, explanation: str) -> dict:
    """解释术语，返回 agent_utterance 文本结构。"""
    return {
        "intent_type": "ExplainTerm",
        "params": {"term": term, "explanation": explanation},
        "reason": f"解释「{term}」",
    }


@tool(
    name="switch_mode",
    description=(
        "切换应用的显示模式。"
        "mode 只能是 'standard'（标准版，蓝色主题）"
        "或 'elder'（长辈版，橙色大字）。"
        "reason 是给用户看的口语说明。"
    ),
)
def switch_mode(mode: str, reason: str) -> dict:
    """切换模式，返回 intent 结构供调用方构造 intent_proposal。"""
    if mode not in ("standard", "elder"):
        raise ValueError(f"mode 只能是 'standard' 或 'elder'，收到: {mode!r}")
    return {
        "intent_type": "SwitchMode",
        "params": {"mode": mode},
        "reason": reason,
    }
