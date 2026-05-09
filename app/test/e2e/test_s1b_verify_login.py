"""
场景 1b：登录 · 验证码分支
能力等级：L2（代读短信验证码 + 代填，'登录'按钮用户亲按）

覆盖路径：
  - 主路径：唤醒 → 文字输入 → 复述确认 → 执行（导航+高亮+HITL授权+代填）→ 高亮"登录"按钮 → task_done
  - 分支 B：用户拒绝 read_sms 授权 → 代理中止，reply"好的，已取消"
  - 异常路径：授权超时（20s 无响应）→ 同拒绝路径

ASR 替代：text_input
TTS 验证：检查各阶段 tts_audio_base64 / voice_hint 非空
"""
import asyncio
import pytest
import pytest_asyncio

from conftest import (
    do_wake, do_text_input, do_confirm, do_permission_response, ts,
    FakeWs, make_handler,
)


@pytest.mark.asyncio
class TestScene1bVerifyLogin:

    # ------------------------------------------------------------------
    # 主路径
    # ------------------------------------------------------------------

    async def test_main_path_navigate_to_verify_page(self, session):
        """步骤 1-2：唤醒 + 文字输入 → 复述确认 → 跳转 /login/verify"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/login/face")

        reply = await do_text_input(handler, fake_ws, sid, "帮我用验证码登录")
        assert reply["payload"]["requires_confirmation"] is True
        print(f"  复述确认: '{reply['payload']['text']}'")

        await do_confirm(handler, fake_ws, sid, answer="yes")

        nav = await fake_ws.wait_for("cmd_navigate", timeout=60)
        assert nav["payload"]["target_route"] == "/login/verify", (
            f"应跳转 /login/verify，实际: {nav['payload']['target_route']}"
        )
        print(f"  PASS cmd_navigate → {nav['payload']['target_route']}")

    async def test_main_path_highlight_phone_input(self, session):
        """步骤 3：代理高亮手机号输入框"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/login/face")
        await do_text_input(handler, fake_ws, sid, "帮我用验证码登录")
        await do_confirm(handler, fake_ws, sid, answer="yes")

        await fake_ws.wait_for("cmd_navigate", timeout=60)
        hl = await fake_ws.wait_for("cmd_highlight", timeout=30)
        assert hl["payload"]["element_key"] == "input_phone", (
            f"应高亮 input_phone，实际: {hl['payload']['element_key']}"
        )
        assert hl["payload"]["voice_hint"], "cmd_highlight 应有 voice_hint"
        print(f"  PASS cmd_highlight(input_phone): hint='{hl['payload']['voice_hint']}'")

    async def test_main_path_hitl_permission_grant(self, session):
        """步骤 7-9：代理请求 read_sms 授权 → 用户同意 → 代填验证码"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/login/face")
        await do_text_input(handler, fake_ws, sid, "帮我用验证码登录")
        await do_confirm(handler, fake_ws, sid, answer="yes")

        # 等待 permission_request
        perm = await fake_ws.wait_for("permission_request", timeout=60)
        p = perm["payload"]
        assert p["permission_type"] == "read_sms", (
            f"权限类型应为 read_sms，实际: {p['permission_type']}"
        )
        assert p["description"], "permission_request 缺少说明文字"
        assert p["expires_in_ms"] > 0, "permission_request 缺少超时时长"
        print(f"  PASS permission_request(read_sms): '{p['description']}'")

        # 用户同意授权
        await do_permission_response(handler, fake_ws, sid,
                                     permission_id=p["permission_id"],
                                     granted=True)

        # 等待 cmd_fill_field（验证码代填）
        fill = await fake_ws.wait_for("cmd_fill_field", timeout=60)
        assert fill["payload"]["field_key"] == "input_verify_code", (
            f"应填验证码字段，实际: {fill['payload']['field_key']}"
        )
        assert fill["payload"]["value"], "验证码值不能为空"
        assert fill["payload"]["is_sensitive"] is False, "验证码字段不属于敏感字段"
        print(f"  PASS cmd_fill_field(input_verify_code): value='{fill['payload']['value']}'")

    async def test_main_path_highlight_login_button_and_done(self, session):
        """步骤 10-11：代理高亮'登录'按钮（止损点）→ task_done"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/login/face")
        await do_text_input(handler, fake_ws, sid, "帮我用验证码登录")
        await do_confirm(handler, fake_ws, sid, answer="yes")

        perm = await fake_ws.wait_for("permission_request", timeout=60)
        await do_permission_response(handler, fake_ws, sid,
                                     permission_id=perm["payload"]["permission_id"],
                                     granted=True)

        await fake_ws.wait_for("cmd_fill_field", timeout=60)

        hl_login = await fake_ws.wait_for("cmd_highlight", timeout=30)
        assert hl_login["payload"]["element_key"] == "btn_login", (
            f"应高亮登录按钮，实际: {hl_login['payload']['element_key']}"
        )
        print(f"  PASS cmd_highlight(btn_login)：止损点，代理不代按")

        done = await fake_ws.wait_for("task_done", timeout=30)
        assert done["payload"]["summary"]
        print(f"  PASS task_done: '{done['payload']['summary'][:40]}…'")

    # ------------------------------------------------------------------
    # 分支 B：用户拒绝 read_sms 授权
    # ------------------------------------------------------------------

    async def test_branch_b_user_denies_read_sms(self, session):
        """步骤 8-B：用户点'不行' → 代理中止，发 agent_reply('好的，已取消')"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/login/face")
        await do_text_input(handler, fake_ws, sid, "帮我用验证码登录")
        await do_confirm(handler, fake_ws, sid, answer="yes")

        perm = await fake_ws.wait_for("permission_request", timeout=60)
        await do_permission_response(handler, fake_ws, sid,
                                     permission_id=perm["payload"]["permission_id"],
                                     granted=False)

        cancel_reply = await fake_ws.wait_for("agent_reply", timeout=20)
        assert "取消" in cancel_reply["payload"]["text"], (
            f"拒绝授权后应回复包含'取消'，实际: {cancel_reply['payload']['text']}"
        )
        print(f"  PASS 分支 B 拒绝授权: '{cancel_reply['payload']['text']}'")

        # 中止后不应出现 cmd_fill_field
        await asyncio.sleep(2)
        fill_msgs = [m for m in fake_ws.sent if m["type"] == "cmd_fill_field"]
        assert not fill_msgs, "拒绝授权后不应出现 cmd_fill_field"
        print("  PASS 无 cmd_fill_field")

    # ------------------------------------------------------------------
    # 异常路径：授权超时
    # ------------------------------------------------------------------

    async def test_error_permission_timeout(self, session):
        """授权超时（不发 permission_response）→ 代理自动取消，发 agent_reply('好的，已取消')"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/login/face")
        await do_text_input(handler, fake_ws, sid, "帮我用验证码登录")
        await do_confirm(handler, fake_ws, sid, answer="yes")

        perm = await fake_ws.wait_for("permission_request", timeout=60)
        assert perm["payload"]["expires_in_ms"] == 20000

        # 不发 permission_response，等待超时（等 22 秒，比超时多 2 秒）
        # 注意：此 case 慢，默认 mark 为慢速测试
        cancel_reply = await fake_ws.wait_for("agent_reply", timeout=25)
        assert "取消" in cancel_reply["payload"]["text"], (
            f"超时后应回复包含'取消'，实际: {cancel_reply['payload']['text']}"
        )
        print(f"  PASS 授权超时: '{cancel_reply['payload']['text']}'")
