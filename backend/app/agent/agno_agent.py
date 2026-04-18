"""
Step 3：硬编码规则调度 + Agno Agent 骨架（无真实 LLM）。
Step 4 接入 DeepSeek 后，只需替换 build_agent() 中的 model 参数，
hardcoded_dispatch 整体移除。
"""

from __future__ import annotations

from agno.agent import Agent

from app.agent.prompts import AGENT_SYSTEM_PROMPT
from app.agent.tools import explain_term, navigate_to, switch_mode

# Step 4 前不传 model，agent 对象仅作工具注册中心
_agent: Agent | None = None


def get_agent() -> Agent:
    global _agent
    if _agent is None:
        _agent = Agent(
            name="小浙",
            model=None,
            tools=[navigate_to, explain_term, switch_mode],
            instructions=AGENT_SYSTEM_PROMPT,
            markdown=False,
        )
    return _agent


# ── 硬编码关键词规则（Step 3 专用，Step 4 删除） ──────────────────────────────

_EXPLAIN_TERMS: dict[str, str] = {
    "灵活就业": "没有固定单位、自己给自己交社保的人，比如开小店的、跑外卖的",
    "城乡居民": "没有工作单位的农村居民或城市居民，参加居民养老保险或居民医保",
    "社保": "社会保险的简称，包括养老、医疗、失业、工伤、生育五种保险",
}


def hardcoded_dispatch(user_text: str) -> dict | None:
    """
    关键词匹配规则调度，返回 tool 结果 dict 或 None。
    返回 dict 格式与 navigate_to / explain_term / switch_mode 一致：
      {"intent_type": str, "params": dict, "reason": str}
    """
    t = user_text

    # 养老金 / 退休
    if any(k in t for k in ("养老金", "退休金", "退休")):
        return navigate_to.entrypoint(
            path="/service/pension-query",
            reason="帮您打开养老金查询页面",
        )

    # 医保 / 社保缴费
    if any(k in t for k in ("医保", "社保", "缴费", "交保险")):
        return navigate_to.entrypoint(
            path="/service/social-insurance",
            reason="帮您打开社保缴费页面",
        )

    # 切长辈版
    if any(k in t for k in ("长辈版", "大字", "看不清", "老年版", "老人版")):
        return switch_mode.entrypoint(
            mode="elder",
            reason="帮您切换到大字长辈版",
        )

    # 切标准版
    if any(k in t for k in ("标准版", "普通版", "常规版", "小字")):
        return switch_mode.entrypoint(
            mode="standard",
            reason="帮您切换回标准版",
        )

    # 术语解释
    for term, explanation in _EXPLAIN_TERMS.items():
        if term in t:
            return explain_term.entrypoint(term=term, explanation=explanation)

    # 泛化触发：含"什么是""看不懂""不明白"等
    if any(k in t for k in ("什么是", "什么叫", "看不懂", "不明白", "不知道")):
        return explain_term.entrypoint(
            term="这个词",
            explanation="请把您不明白的词说给我听，我来解释。",
        )

    return None
