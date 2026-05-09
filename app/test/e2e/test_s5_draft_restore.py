"""
场景 5：草稿箱恢复
前置条件：用户曾在医保缴费页代理已填部分字段，IndexedDB 中有未完成草稿

【重要限制 - 无法通过 WS 协议测试】
草稿恢复是纯前端逻辑，不涉及后端 WebSocket 消息：
  - DraftService.autoSave 写入 IndexedDB（Flutter 前端行为）
  - _checkPageDraft() 在 AgentPanel._initSession 中调用（Flutter 生命周期）
  - 草稿提示卡片直接插入气泡区（Flutter UI 状态）
  - 用户点"继续"→ GoRouter 刷新页面 + DraftService 恢复字段（Flutter 前端）
  - 后端收到 agent_wake 后只发 agent_ready(has_draft=False)，不参与草稿逻辑

本测试文件仅覆盖：
  1. agent_wake 在草稿页收到后，后端照常发 agent_ready
  2. has_draft 字段目前硬编码为 False（草稿检查在前端）

完整的草稿恢复流程（步骤 2/3A/3B）须在 Flutter 集成测试中验证：
  - 操作：先触发 DraftService.autoSave 写入 IndexedDB
  - 操作：关闭面板再重新打开
  - 验证：气泡区出现草稿提示卡片
  - 验证：点"继续"后表单字段恢复
  - 验证：点"不用了"后草稿从 IndexedDB 删除（N4-4 真机测试项）
"""
import pytest

from conftest import do_wake


@pytest.mark.asyncio
class TestScene5DraftRestore:

    async def test_agent_wake_on_draft_page_sends_ready(self, session):
        """
        步骤 2（前置）：在医保缴费页打开代理面板 → 后端发 agent_ready
        此步骤可在协议层验证；草稿检查由前端自行完成（不依赖后端消息）。
        """
        handler, fake_ws, sid = session
        ready = await do_wake(handler, fake_ws, sid,
                              current_page="/service/yibao-jiaofei")
        assert ready["type"] == "agent_ready"
        p = ready["payload"]
        assert p["greeting"], "agent_ready 应有问候语"
        # 当前后端硬编码 has_draft=False；草稿检查在前端
        assert p["has_draft"] is False, (
            "当前后端不承担草稿检查，has_draft 应为 False；"
            "草稿逻辑由前端 _checkPageDraft() 处理"
        )
        print(f"  PASS agent_ready(draft_page): has_draft={p['has_draft']}")
        print("  提示：草稿提示卡片、'继续'/'不用了'按钮均为前端实现，须 Flutter 集成测试验证")

    async def test_draft_pages_list(self):
        """
        文档验证：草稿检查仅对三个页面生效
        （非 WS 测试，仅检查路由常量定义）
        """
        import sys
        from pathlib import Path
        sys.path.insert(0, str(Path(__file__).resolve().parents[3]))
        # 读旅程图文档中定义的草稿页列表
        draft_pages = {
            "/service/yibao-jiaofei",
            "/service/yibao-query",
            "/service/pension-query",
        }
        # 从 router.dart 中的 AppRoutes 常量反向验证
        router_path = (Path(__file__).resolve().parents[3]
                       / "app" / "lib" / "router.dart")
        router_src = router_path.read_text(encoding="utf-8")
        for page in draft_pages:
            assert page in router_src, (
                f"路由 {page} 未在 router.dart 中定义，草稿恢复会因路由不匹配而静默失败"
            )
        print(f"  PASS 草稿检查页路由均已在 router.dart 中定义: {draft_pages}")

    @pytest.mark.skip(reason="须 Flutter 集成测试 + 真机（N4-4）")
    async def test_step_3a_continue_restores_form(self, session):
        """
        步骤 3A（待 Flutter 集成测试）：
        用户点'继续' → DraftService 恢复字段 → 表单显示已填内容
        须验证：IndexedDB 读写在真机上无竞态（N4-4）
        """
        pass

    @pytest.mark.skip(reason="须 Flutter 集成测试 + 真机（N4-4）")
    async def test_step_3b_dismiss_deletes_draft(self, session):
        """
        步骤 3B（待 Flutter 集成测试）：
        用户点'不用了' → DraftStore.deleteDraft 删除 IndexedDB 记录
        须验证：下次唤醒时不再出现草稿提示
        """
        pass
