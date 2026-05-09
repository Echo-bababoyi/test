"""
场景 4：超出能力范围
适用于：用户请求不属于浙里办服务 / 代理能力范围之外的需求

覆盖路径：
  - 主路径：说"帮我订火车票" → agent_out_of_scope（不执行任何工具）
  - 次路径：说"帮我改头像" → agent_out_of_scope（浙里办有但代理不会）
  - 验证：LLM 不执行任何场景工具；out_of_scope reply 包含合理的提示文字

ASR 替代：text_input（跳过 agent_wake 的复述确认，直接到 out_of_scope 分支）
"""
import pytest

from conftest import do_wake, ts


@pytest.mark.asyncio
class TestScene4OutOfScope:

    # ------------------------------------------------------------------
    # 主路径：浙里办无此服务
    # ------------------------------------------------------------------

    async def test_main_path_train_ticket(self, session):
        """说'帮我订火车票' → agent_out_of_scope，不执行任何工具"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/elder")

        await handler._dispatch({
            "type": "text_input",
            "payload": {"session_id": sid, "text": "帮我订火车票"},
            "ts": ts(),
        })
        await fake_ws.wait_for("asr_result", timeout=10)
        oos = await fake_ws.wait_for("agent_out_of_scope", timeout=30)
        p = oos["payload"]
        assert p["voice_hint"], "agent_out_of_scope 应有说明话术"
        assert p["scope_type"], "agent_out_of_scope 应有 scope_type"
        # 话术应提到该服务不可用，或者给出替代建议
        hint = p["voice_hint"]
        print(f"  PASS agent_out_of_scope: hint='{hint}'")

        # 确认没有任何场景执行消息
        exec_types = [m["type"] for m in fake_ws.sent
                      if m["type"] in ("cmd_navigate", "cmd_press_button",
                                       "cmd_fill_field", "cmd_highlight")]
        assert not exec_types, f"超出范围时不应有执行命令: {exec_types}"
        print("  PASS 无场景执行消息")

    # ------------------------------------------------------------------
    # 次路径：浙里办有但代理不会
    # ------------------------------------------------------------------

    async def test_secondary_path_change_avatar(self, session):
        """说'帮我改头像' → agent_out_of_scope，可附带指路信息"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/elder")

        await handler._dispatch({
            "type": "text_input",
            "payload": {"session_id": sid, "text": "帮我改头像"},
            "ts": ts(),
        })
        await fake_ws.wait_for("asr_result", timeout=10)
        oos = await fake_ws.wait_for("agent_out_of_scope", timeout=30)
        p = oos["payload"]
        assert p["voice_hint"], "agent_out_of_scope 应有说明话术"
        hint = p["voice_hint"]
        print(f"  PASS agent_out_of_scope(改头像): hint='{hint}'")

    # ------------------------------------------------------------------
    # 边界验证：状态应回到 idle
    # ------------------------------------------------------------------

    async def test_state_idle_after_out_of_scope(self, session):
        """out_of_scope 后状态应为 idle，面板保持开启可继续对话"""
        from backend.ws_handler import SessionState

        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/elder")

        await handler._dispatch({
            "type": "text_input",
            "payload": {"session_id": sid, "text": "帮我订外卖"},
            "ts": ts(),
        })
        await fake_ws.wait_for("asr_result", timeout=10)
        await fake_ws.wait_for("agent_out_of_scope", timeout=30)

        assert handler.state == SessionState.idle, (
            f"out_of_scope 后状态应为 idle，实际: {handler.state}"
        )
        print(f"  PASS 状态 = {handler.state}")
