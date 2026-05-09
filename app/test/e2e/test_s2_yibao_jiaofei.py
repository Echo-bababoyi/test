"""
场景 2：医保缴费
能力等级：L2-L3（代填非敏感字段；敏感字段单独授权；"去支付"按钮用户亲按）

覆盖路径：
  - 主路径：唤醒 → 确认 → 导航+代填三个字段（非敏感）→ HITL授权（身份证）→ 代填身份证（脱敏）→ 高亮"去支付"→ task_done
  - 分支 C：用户拒绝身份证号授权 → 代理中止

ASR 替代：text_input
TTS 验证：voice_hint 非空；is_sensitive 字段为 True 时前端须脱敏显示（此处验证字段值）
"""
import asyncio
import pytest

from conftest import (
    do_wake, do_text_input, do_confirm, do_permission_response,
)


@pytest.mark.asyncio
class TestScene2YibaoJiaofei:

    # ------------------------------------------------------------------
    # 主路径
    # ------------------------------------------------------------------

    async def test_main_path_navigate_to_yibao(self, session):
        """步骤 1-5：唤醒 → 确认 → 跳转 /service/yibao-jiaofei"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/elder")

        reply = await do_text_input(handler, fake_ws, sid, "帮我缴医保")
        assert reply["payload"]["requires_confirmation"] is True
        print(f"  复述确认: '{reply['payload']['text']}'")

        await do_confirm(handler, fake_ws, sid, answer="yes")

        nav = await fake_ws.wait_for("cmd_navigate", timeout=60)
        assert nav["payload"]["target_route"] == "/service/yibao-jiaofei", (
            f"应跳转 /service/yibao-jiaofei，实际: {nav['payload']['target_route']}"
        )
        print(f"  PASS cmd_navigate → {nav['payload']['target_route']}")

    async def test_main_path_fill_non_sensitive_fields(self, session):
        """步骤 6-8：代填缴费对象、缴费年度、缴费金额（均非敏感字段）"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/elder")
        await do_text_input(handler, fake_ws, sid, "帮我缴医保")
        await do_confirm(handler, fake_ws, sid, answer="yes")
        await fake_ws.wait_for("cmd_navigate", timeout=60)

        filled = []
        # 旅程图步骤 6/7/8：填三个非敏感字段
        for _ in range(3):
            try:
                fill = await fake_ws.wait_for("cmd_fill_field", timeout=30)
                assert fill["payload"]["is_sensitive"] is False, (
                    f"普通字段 {fill['payload']['field_key']} 不应标记 is_sensitive"
                )
                assert fill["payload"]["value"], "字段值不能为空"
                assert fill["payload"]["voice_hint"], "cmd_fill_field 应有 voice_hint"
                filled.append(fill["payload"]["field_key"])
                print(f"  PASS cmd_fill_field: key={fill['payload']['field_key']} value='{fill['payload']['value']}'")
            except TimeoutError:
                # LLM 可能将步骤合并或跳过，允许少于 3 条
                break

        assert filled, "至少应代填一个非敏感字段"

    async def test_main_path_sensitive_field_permission(self, session):
        """步骤 9-11：HITL 授权 → 代填身份证号（is_sensitive=True）"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/elder")
        await do_text_input(handler, fake_ws, sid, "帮我缴医保")
        await do_confirm(handler, fake_ws, sid, answer="yes")
        await fake_ws.wait_for("cmd_navigate", timeout=60)

        # 等 HITL 权限请求（跳过中间的 fill_field）
        perm = await fake_ws.wait_for("permission_request", timeout=60)
        p = perm["payload"]
        assert p["permission_type"] == "fill_sensitive_field", (
            f"权限类型应为 fill_sensitive_field，实际: {p['permission_type']}"
        )
        print(f"  PASS permission_request(fill_sensitive_field): '{p['description']}'")

        await do_permission_response(handler, fake_ws, sid,
                                     permission_id=p["permission_id"],
                                     granted=True)

        # 等待代填身份证号
        fill_id = await fake_ws.wait_for("cmd_fill_field", timeout=60)
        assert fill_id["payload"]["is_sensitive"] is True, (
            "身份证号字段应标记 is_sensitive=True（前端负责脱敏渲染）"
        )
        assert fill_id["payload"]["value"], "身份证号值不能为空"
        print(f"  PASS cmd_fill_field(is_sensitive=True): key={fill_id['payload']['field_key']}")
        print("  N4-3 注意：前端须验证 is_sensitive=True 时显示打码值，不显示明文")

    async def test_main_path_highlight_payment_button(self, session):
        """步骤 12：代理高亮'去支付'按钮（止损点，不代按）"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/elder")
        await do_text_input(handler, fake_ws, sid, "帮我缴医保")
        await do_confirm(handler, fake_ws, sid, answer="yes")
        await fake_ws.wait_for("cmd_navigate", timeout=60)

        perm = await fake_ws.wait_for("permission_request", timeout=60)
        await do_permission_response(handler, fake_ws, sid,
                                     permission_id=perm["payload"]["permission_id"],
                                     granted=True)
        await fake_ws.wait_for("cmd_fill_field", timeout=60)

        hl = await fake_ws.wait_for("cmd_highlight", timeout=30)
        assert hl["payload"]["element_key"] == "btn_go_payment", (
            f"应高亮 btn_go_payment，实际: {hl['payload']['element_key']}"
        )
        print(f"  PASS cmd_highlight(btn_go_payment)：止损点，不代按")

        done = await fake_ws.wait_for("task_done", timeout=30)
        assert done["payload"]["summary"]
        print(f"  PASS task_done: '{done['payload']['summary'][:40]}…'")

    # ------------------------------------------------------------------
    # 分支 C：用户拒绝身份证号授权
    # ------------------------------------------------------------------

    async def test_branch_c_deny_sensitive_permission(self, session):
        """步骤 9-C：用户拒绝身份证号授权 → 代理中止，不填身份证，reply'好的，已取消'"""
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/elder")
        await do_text_input(handler, fake_ws, sid, "帮我缴医保")
        await do_confirm(handler, fake_ws, sid, answer="yes")
        await fake_ws.wait_for("cmd_navigate", timeout=60)

        perm = await fake_ws.wait_for("permission_request", timeout=60)
        await do_permission_response(handler, fake_ws, sid,
                                     permission_id=perm["payload"]["permission_id"],
                                     granted=False)

        cancel_reply = await fake_ws.wait_for("agent_reply", timeout=20)
        assert "取消" in cancel_reply["payload"]["text"], (
            f"拒绝授权后应回复包含'取消'，实际: {cancel_reply['payload']['text']}"
        )
        print(f"  PASS 分支 C：'{cancel_reply['payload']['text']}'")

        # 拒绝后不应出现更多 cmd_fill_field
        await asyncio.sleep(2)
        sensitive_fills = [
            m for m in fake_ws.sent
            if m["type"] == "cmd_fill_field" and m["payload"].get("is_sensitive")
        ]
        assert not sensitive_fills, "拒绝授权后不应出现敏感字段代填"
        print("  PASS 无敏感字段代填")
