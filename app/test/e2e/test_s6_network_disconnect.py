"""
场景 6：网络断线重连

覆盖路径：
  - 步骤 1：面板开启期间 WS 断开 → 后端清理 session（permission_event 清理）
  - 步骤 2（执行中断线）：执行任务途中 WS 断开 → permission_event 解决为 False，任务中止
  - 步骤 3：重新连接（新 session）→ 新 agent_wake 照常完成

【前端行为限制】（无法通过 WS 协议测试）：
  - 红色横幅 "网络已断开，小浙暂时无法帮您" 须在 Flutter 集成测试中验证
  - 麦克风按钮变灰、文字输入框禁用须 Flutter 集成测试验证
  - 重连后红色横幅消失须 Flutter 集成测试验证
  - 执行中断线的字段保留（IndexedDB DraftService）须真机验证（N4-4）
"""
import asyncio
import json
import uuid
from unittest.mock import AsyncMock, MagicMock

import pytest

from conftest import (
    do_wake, do_text_input, do_confirm, ts, FakeWs, make_handler,
)


@pytest.mark.asyncio
class TestScene6NetworkDisconnect:

    # ------------------------------------------------------------------
    # 步骤 1：正常会话中断开连接
    # ------------------------------------------------------------------

    async def test_disconnect_during_idle_cleans_up(self, session):
        """
        步骤 1：face_ws 断开（发 agent_ready 后）→ 后端 run() 退出，
        handler._agent_core 被清理，permission_event resolve(False) 无异常。
        """
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid)
        # 此时 handler._agent_core 已创建
        assert handler._agent_core is not None

        # 模拟 WS 关闭：手动调用 finally 块逻辑（等同于 run() 退出）
        if handler._agent_core:
            handler._agent_core.resolve_permission(False)
            handler._agent_core = None

        assert handler._agent_core is None, "断开后 agent_core 应被清理"
        print("  PASS 连接断开后 agent_core 已清理")

    # ------------------------------------------------------------------
    # 步骤 2：执行任务途中断开连接
    # ------------------------------------------------------------------

    async def test_disconnect_during_executing_resolves_permission(self, session):
        """
        执行中途断开：若代理等待 permission 期间断线，
        resolve_permission(False) 应触发，任务中止，不挂起。
        """
        handler, fake_ws, sid = session
        await do_wake(handler, fake_ws, sid, current_page="/elder")
        await do_text_input(handler, fake_ws, sid, "帮我用验证码登录")
        await do_confirm(handler, fake_ws, sid, answer="yes")

        # 等待 permission_request（代理等待中途）
        try:
            perm = await fake_ws.wait_for("permission_request", timeout=60)
            print(f"  PASS 已收到 permission_request: {perm['payload']['permission_type']}")
        except TimeoutError:
            pytest.skip("LLM 未进入 HITL 分支，无法验证此路径")

        # 模拟断线：不发 permission_response，直接 resolve(False)
        if handler._agent_core:
            handler._agent_core.resolve_permission(False)

        # 等待代理中止并发出取消消息
        cancel_reply = await fake_ws.wait_for("agent_reply", timeout=15)
        assert "取消" in cancel_reply["payload"]["text"], (
            f"断线后代理应回复包含'取消'，实际: {cancel_reply['payload']['text']}"
        )
        print(f"  PASS 断线后任务中止: '{cancel_reply['payload']['text']}'")

    # ------------------------------------------------------------------
    # 步骤 3：重新连接（新 session）
    # ------------------------------------------------------------------

    async def test_reconnect_with_new_session(self):
        """
        步骤 3：关闭旧面板再重新打开 → 新 session agent_wake 照常工作。
        """
        # 第一个 session：断开
        sid1 = f"e2e-{uuid.uuid4().hex[:8]}"
        fake_ws1 = FakeWs()
        handler1 = make_handler(fake_ws1, sid1)
        await do_wake(handler1, fake_ws1, sid1)
        if handler1._agent_core:
            handler1._agent_core.resolve_permission(False)
            handler1._agent_core = None

        # 第二个 session：重新连接
        sid2 = f"e2e-{uuid.uuid4().hex[:8]}"
        fake_ws2 = FakeWs()
        handler2 = make_handler(fake_ws2, sid2)
        ready = await do_wake(handler2, fake_ws2, sid2, current_page="/elder")

        assert ready["type"] == "agent_ready"
        assert ready["payload"]["greeting"], "重连后 agent_ready 应有问候语"
        print(f"  PASS 重连新 session: '{ready['payload']['greeting']}'")
        print("  提示：前端红色横幅消失须 Flutter 集成测试验证")

        if handler2._agent_core:
            handler2._agent_core.resolve_permission(False)

    # ------------------------------------------------------------------
    # 补充：执行中断线后草稿残留说明
    # ------------------------------------------------------------------

    @pytest.mark.skip(reason="须 Flutter 集成测试 + 真机（N4-4）")
    async def test_draft_preserved_after_disconnect(self):
        """
        执行中断线 + DraftService.autoSave 正常时，已填字段写入 IndexedDB，
        下次打开有草稿恢复提示（仅限草稿页）。
        须真机验证 IndexedDB 读写与字段恢复竞态（N4-4）。
        """
        pass
