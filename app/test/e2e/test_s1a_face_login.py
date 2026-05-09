"""
场景 1a：登录 · 刷脸分支
能力等级：L1（纯语音引导 + 视觉高亮，代理不填任何字段）

覆盖路径：
  - 主路径：唤醒 → 说需求 → 复述确认 → 执行（导航+高亮）→ task_done
  - 分支 A：用户拒绝复述确认（点"不是"）→ 代理不执行
  - 异常路径 E：ASR 没听清 → agent_error(asr_unclear)

ASR 替代：用 text_input 消息模拟语音输入
TTS 验证：检查 agent_reply.tts_audio_base64 非空，气泡文字非空
"""
import pytest
import pytest_asyncio

from conftest import (
    do_wake, do_text_input, do_confirm, ts,
    FakeWs, make_handler,
)


@pytest.mark.asyncio
class TestScene1aFaceLogin:

    # ------------------------------------------------------------------
    # 主路径
    # ------------------------------------------------------------------

    async def test_main_path_wake_and_greeting(self, session):
        """P1/P2 + 步骤1：唤醒代理 → agent_ready（面板打开，状态=listening）"""
        handler, fake_ws, sid = session

        ready = await do_wake(handler, fake_ws, sid, current_page="/elder")

        assert ready["type"] == "agent_ready"
        payload = ready["payload"]
        assert payload["greeting"], "agent_ready 缺少问候语"
        # draft 相关：当前页 /elder 不在草稿页列表，has_draft 应为 False
        assert payload["has_draft"] is False
        print(f"  PASS agent_ready: greeting='{payload['greeting']}'")

    async def test_main_path_text_input_and_reply(self, session):
        """步骤 2-4：text_input('帮我登录') → asr_result + agent_thinking + agent_reply(复述确认)"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid)

        reply = await do_text_input(handler, fake_ws, sid, "帮我登录")

        assert reply["type"] == "agent_reply"
        p = reply["payload"]
        assert p["requires_confirmation"] is True, "刷脸登录意图应要求复述确认"
        assert p["text"], "agent_reply.text 不能为空（复述话术）"
        assert p["tts_audio_base64"], "TTS 音频不能为空（替代语音播报验证）"
        print(f"  PASS agent_reply: text='{p['text']}'")

    async def test_main_path_confirm_and_execute(self, session):
        """步骤 5-12：用户点'对的' → 执行阶段（导航+高亮+task_done）"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid)
        await do_text_input(handler, fake_ws, sid, "帮我登录")
        await do_confirm(handler, fake_ws, sid, answer="yes")

        # 等待 cmd_navigate 到 /login
        nav_login = await fake_ws.wait_for("cmd_navigate", timeout=60)
        assert nav_login["payload"]["target_route"] == "/login", (
            f"首次导航应跳 /login，实际: {nav_login['payload']['target_route']}"
        )
        assert nav_login["payload"]["voice_hint"], "cmd_navigate 应有 voice_hint"
        print(f"  PASS cmd_navigate → {nav_login['payload']['target_route']}")

        # 等待 cmd_highlight（同意条款勾选框）
        hl_terms = await fake_ws.wait_for("cmd_highlight", timeout=30)
        assert hl_terms["payload"]["element_key"], "cmd_highlight 缺少 element_key"
        print(f"  PASS cmd_highlight: element='{hl_terms['payload']['element_key']}'")

        # 等待 task_done（场景执行完毕后的最终消息）
        done = await fake_ws.wait_for("task_done", timeout=60)
        assert done["payload"]["summary"], "task_done 缺少 summary"
        assert done["payload"]["voice_hint"], "task_done 缺少 voice_hint"
        print(f"  PASS task_done: summary='{done['payload']['summary'][:40]}…'")

    # ------------------------------------------------------------------
    # 分支 A：用户拒绝复述确认
    # ------------------------------------------------------------------

    async def test_branch_a_user_rejects_confirmation(self, session):
        """步骤 5-B：用户点'不是' → 代理不执行任何操作，状态回 listening/idle"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid)
        await do_text_input(handler, fake_ws, sid, "帮我登录")

        baseline_sent = len(fake_ws.sent)
        await do_confirm(handler, fake_ws, sid, answer="no")

        # 拒绝后不应出现 cmd_navigate / cmd_highlight / task_done
        import asyncio
        await asyncio.sleep(2)  # 短暂等待，确认没有后续消息
        new_msgs = fake_ws.sent[baseline_sent:]
        bad_types = [m["type"] for m in new_msgs
                     if m["type"] in ("cmd_navigate", "cmd_highlight", "task_done")]
        assert not bad_types, f"拒绝确认后不应出现执行消息: {bad_types}"
        print("  PASS 分支 A：拒绝确认后无执行消息")

    # ------------------------------------------------------------------
    # 异常路径 E：ASR 没听清（发 audio_end 但没有 audio_chunk）
    # ------------------------------------------------------------------

    async def test_error_asr_unclear(self, session):
        """步骤 2-E：发 audio_end（无 audio_chunk）→ agent_error(asr_unclear)"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid)

        # 不发 audio_chunk，直接发 audio_end
        await handler._dispatch({
            "type": "audio_end",
            "payload": {"session_id": sid},
            "ts": ts(),
        })

        err = await fake_ws.wait_for("agent_error", timeout=15)
        assert err["payload"]["error_code"] == "asr_unclear", (
            f"错误码应为 asr_unclear，实际: {err['payload']['error_code']}"
        )
        assert err["payload"]["voice_hint"], "agent_error 应有 voice_hint"
        print(f"  PASS agent_error(asr_unclear): hint='{err['payload']['voice_hint']}'")
