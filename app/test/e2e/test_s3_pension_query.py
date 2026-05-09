"""
场景 3：养老金查询
能力等级：L1-L2 全链路（纯查询，代理可独立完成，无确定性操作）

覆盖路径：
  - 主路径：唤醒 → 确认 → 导航 → cmd_press_button（非确定性）→ 前端发 query_result_ready → agent_reply（双通道播报）→ task_done
  - N4-1 风险验证：cmd_press_button 消息格式检查（is_deterministic=false）

ASR 替代：text_input
TTS 验证：agent_reply.tts_audio_base64 非空

注：cmd_press_button 实际触发效果（是否使 ElevatedButton 响应）须在真机验证（N4-1）。
"""
import pytest

from conftest import (
    do_wake, do_text_input, do_confirm, ts,
)


@pytest.mark.asyncio
class TestScene3PensionQuery:

    # ------------------------------------------------------------------
    # 主路径
    # ------------------------------------------------------------------

    async def test_main_path_navigate_to_pension_query(self, session):
        """步骤 1-5：唤醒 → 确认 → 跳转 /service/pension-query"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/elder")

        reply = await do_text_input(handler, fake_ws, sid, "帮我查养老金")
        assert reply["payload"]["requires_confirmation"] is True
        print(f"  复述确认: '{reply['payload']['text']}'")

        await do_confirm(handler, fake_ws, sid, answer="yes")

        nav = await fake_ws.wait_for("cmd_navigate", timeout=60)
        assert nav["payload"]["target_route"] == "/service/pension-query", (
            f"应跳转 /service/pension-query，实际: {nav['payload']['target_route']}"
        )
        print(f"  PASS cmd_navigate → {nav['payload']['target_route']}")

    async def test_main_path_press_query_button(self, session):
        """步骤 6：代理代按'查询'按钮（非确定性操作）"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/elder")
        await do_text_input(handler, fake_ws, sid, "帮我查养老金")
        await do_confirm(handler, fake_ws, sid, answer="yes")
        await fake_ws.wait_for("cmd_navigate", timeout=60)

        btn = await fake_ws.wait_for("cmd_press_button", timeout=30)
        b = btn["payload"]
        assert b["button_key"] == "btn_query", (
            f"应按 btn_query，实际: {b['button_key']}"
        )
        assert b["is_deterministic"] is False, (
            "查询按钮应标记 is_deterministic=False（非确定性操作）"
        )
        assert b["voice_hint"], "cmd_press_button 应有 voice_hint"
        print(f"  PASS cmd_press_button: key='{b['button_key']}' is_deterministic=False")
        print("  N4-1 须真机验证：cmd_press_button 是否实际触发 ElevatedButton")

    async def test_main_path_query_result_dual_channel(self, session):
        """步骤 7：前端发 query_result_ready → 后端生成播报话术 → agent_reply（双通道）"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/elder")
        await do_text_input(handler, fake_ws, sid, "帮我查养老金")
        await do_confirm(handler, fake_ws, sid, answer="yes")
        await fake_ws.wait_for("cmd_navigate", timeout=60)
        await fake_ws.wait_for("cmd_press_button", timeout=30)

        # 模拟前端在查询结果渲染后发 query_result_ready
        await handler._dispatch({
            "type": "query_result_ready",
            "payload": {
                "page_id": "pension_query",
                "result_fields": {
                    "month": "2026年4月",
                    "amount": "3280",
                    "unit": "元",
                },
            },
            "ts": ts(),
        })

        # 后端应生成播报话术并回复
        reply = await fake_ws.wait_for("agent_reply", timeout=30)
        text = reply["payload"]["text"]
        assert "3280" in text or "养老" in text or "到账" in text, (
            f"播报话术应包含查询结果关键信息，实际: '{text}'"
        )
        assert reply["payload"]["tts_audio_base64"], "双通道播报：TTS 不能为空"
        print(f"  PASS agent_reply(双通道): '{text}'")
        print("  N4-5 须真机验证：语音播报与屏幕结果卡片是否同步渲染")

    async def test_main_path_task_done_after_query(self, session):
        """步骤 8：task_done 后面板关闭（_scheduleAutoDismiss）"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/elder")
        await do_text_input(handler, fake_ws, sid, "帮我查养老金")
        await do_confirm(handler, fake_ws, sid, answer="yes")
        await fake_ws.wait_for("cmd_navigate", timeout=60)
        await fake_ws.wait_for("cmd_press_button", timeout=30)

        await handler._dispatch({
            "type": "query_result_ready",
            "payload": {
                "page_id": "pension_query",
                "result_fields": {"month": "2026年4月", "amount": "3280", "unit": "元"},
            },
            "ts": ts(),
        })

        await fake_ws.wait_for("agent_reply", timeout=30)
        done = await fake_ws.wait_for("task_done", timeout=20)
        assert done["payload"]["summary"], "task_done 缺少 summary"
        print(f"  PASS task_done: '{done['payload']['summary'][:40]}…'")
        print("  N4-2 须真机验证：面板在 TTS 播完 +1s 后关闭，不提前关闭")
