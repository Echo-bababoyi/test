"""
agno Agent 实例 + 调度逻辑。

Step 3：hardcoded_dispatch（关键词规则）。
Step 4：llm_dispatch（DeepSeek-V3 via OpenAILike）。
USE_LLM=false 时自动回退 hardcoded_dispatch（无网 / 限流 fallback）。
"""

from __future__ import annotations

import json
import logging

from agno.agent import Agent
from agno.models.openai import OpenAILike

from app.agent.prompts import AGENT_SYSTEM_PROMPT
from app.agent.tools import explain_term, navigate_to, switch_mode
from app.config import DEEPSEEK_API_KEY, USE_LLM

logger = logging.getLogger(__name__)

# ── 工具结果格式约定 ───────────────────────────────────────────────────────────
# 每个 @tool 函数返回:
# {"intent_type": str, "params": dict, "reason": str}

# ── Agent 单例（LLM 接入后使用） ──────────────────────────────────────────────

_agent: Agent | None = None


def get_agent() -> Agent:
    global _agent
    if _agent is None:
        model = OpenAILike(
            id="deepseek-chat",
            name="DeepSeek-V3",
            api_key=DEEPSEEK_API_KEY or "not-provided",
            base_url="https://api.deepseek.com/v1",
        )
        _agent = Agent(
            name="小浙",
            model=model,
            tools=[navigate_to, explain_term, switch_mode],
            instructions=AGENT_SYSTEM_PROMPT,
            markdown=False,
            add_history_to_context=True,
            num_history_runs=5,
        )
    return _agent


# ── LLM 调度（Step 4） ────────────────────────────────────────────────────────

async def llm_dispatch(user_text: str, session_id: str) -> dict:
    """
    调用 DeepSeek-V3，解析 RunOutput 返回结构化结果。

    返回:
      {
        "tool_result": dict | None,   # 工具调用结果（NavigateTo / SwitchMode / ExplainTerm）
        "agent_text": str,            # agent 文本回复
        "usage": {"input": int, "output": int, "total": int},
      }
    """
    agent = get_agent()
    run_output = await agent.arun(user_text, session_id=session_id)

    # token 用量
    usage = {"input": 0, "output": 0, "total": 0}
    if run_output.metrics:
        m = run_output.metrics
        usage = {
            "input": m.input_tokens,
            "output": m.output_tokens,
            "total": m.total_tokens,
        }
    logger.info(
        "LLM usage session=%s input=%d output=%d total=%d",
        session_id, usage["input"], usage["output"], usage["total"],
    )

    # 工具调用结果（取第一个有效工具结果）
    # agno 把 tool 返回值序列化为 Python repr 字符串（单引号），用 ast.literal_eval 解析
    import ast
    tool_result: dict | None = None
    if run_output.tools:
        for tool_exec in run_output.tools:
            if tool_exec.result and not tool_exec.tool_call_error:
                try:
                    parsed = ast.literal_eval(tool_exec.result)
                    if isinstance(parsed, dict) and "intent_type" in parsed:
                        tool_result = parsed
                        logger.info(
                            "tool_call session=%s tool=%s result=%s",
                            session_id, tool_exec.tool_name, parsed,
                        )
                        break
                except (ValueError, SyntaxError):
                    pass

    agent_text: str = str(run_output.content or "")

    return {
        "tool_result": tool_result,
        "agent_text": agent_text,
        "usage": usage,
    }


# ── 硬编码关键词规则（Step 3 fallback，永久保留） ─────────────────────────────

_EXPLAIN_TERMS: dict[str, str] = {
    "灵活就业": "没有固定单位、自己给自己交社保的人，比如开小店的、跑外卖的",
    "城乡居民": "没有工作单位的农村居民或城市居民，参加居民养老保险或居民医保",
    "社保": "社会保险的简称，包括养老、医疗、失业、工伤、生育五种保险",
    "生育保险": "职工生育时由单位缴纳的保险，报销生育医疗费用，发放生育津贴",
}


def hardcoded_dispatch(user_text: str) -> dict | None:
    """
    关键词规则调度（fallback）。
    返回格式同 @tool 函数：{"intent_type": str, "params": dict, "reason": str}
    """
    t = user_text

    if any(k in t for k in ("养老金", "退休金", "退休")):
        return navigate_to.entrypoint(path="/service/pension-query", reason="帮您打开养老金查询页面")

    if any(k in t for k in ("医保", "缴费", "交保险")):
        return navigate_to.entrypoint(path="/service/social-insurance", reason="帮您打开社保缴费页面")

    if any(k in t for k in ("社保",)) and not any(k in t for k in ("什么是", "什么叫")):
        return navigate_to.entrypoint(path="/service/social-insurance", reason="帮您打开社保缴费页面")

    if any(k in t for k in ("长辈版", "大字", "看不清", "老年版", "老人版")):
        return switch_mode.entrypoint(mode="elder", reason="帮您切换到大字长辈版")

    if any(k in t for k in ("标准版", "普通版", "常规版", "小字")):
        return switch_mode.entrypoint(mode="standard", reason="帮您切换回标准版")

    for term, explanation in _EXPLAIN_TERMS.items():
        if term in t:
            return explain_term.entrypoint(term=term, explanation=explanation)

    if any(k in t for k in ("什么是", "什么叫", "看不懂", "不明白", "不知道")):
        return explain_term.entrypoint(term="这个词", explanation="请把您不明白的词说给我听，我来解释。")

    return None


# ── 统一入口（ws_handler 调用此函数） ─────────────────────────────────────────

async def dispatch(user_text: str, session_id: str) -> dict:
    """
    主调度入口。USE_LLM=true 时走 LLM，失败则 fallback 到硬编码规则。

    返回格式同 llm_dispatch。
    """
    if USE_LLM:
        try:
            return await llm_dispatch(user_text, session_id)
        except Exception as exc:
            logger.warning(
                "LLM dispatch failed (session=%s), falling back to hardcoded. error=%s",
                session_id, exc,
            )

    # fallback
    tool_result = hardcoded_dispatch(user_text)
    return {
        "tool_result": tool_result,
        "agent_text": "",
        "usage": {"input": 0, "output": 0, "total": 0},
    }
