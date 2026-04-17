# 项目 Todolist

本项目唯一的活待办文件。新增问题/任务统一写入此文件。

**状态图例：** 🔲 待做 · 🧪 已做完待用户验证 · ✅ 用户已确认完成

---

## 当前待办

### Phase 1：主线黑白线框版（未开始）

- 🔲 每个页面按截图拆出"语义区块"（Header / 服务网格 / 轮播 / 卡片 / 底部导航）用灰块占位
- 🔲 端到端主线跑通：启动 → 标准首页 → 长辈首页 → 登录全链路 → 搜索医保缴费 → 社保服务页
- 🔲 搜索结果页按关键词分流（医保缴费 vs 养老金查询）
- 🔲 底部导航联通：首页/我的在长辈版下正常切换
- 🔲 长辈首页 3 个 Tab 下的"占位卡片"按截图区块规划（具体图标/配色 Phase 2 做）
- 🔲 Phase 1 验收：主线能点通、弹窗分类正确、黑白线框视觉统一

---

## 已提交待验证

<!-- 新记录插入最上方 -->

_（暂无）_

---

## 已完成

<!-- 用户确认后从"已提交待验证"迁移到这里 -->

### Phase 0：项目骨架（2026-04-17）

- ✅ 前置决策 5 项：Riverpod / go_router / Flutter Web 目标 / SDK 项目级安装（`tools/flutter/` 3.41.7）/ 基准分辨率 405 × 880 dp
- ✅ Flutter 项目初始化 + feature-based 目录结构
- ✅ Riverpod + go_router 集成（`flutter_riverpod ^3.3.1` / `go_router ^17.2.1`）
- ✅ 双主题 + 设计 token 文件（`lib/core/theme/`）
- ✅ 两套弹窗组件族骨架（`SystemDialog` 阻塞 / `InAppOverlay` 非阻塞，物理分开）
- ✅ 11 个页面占位 Scaffold + 路由全连通
- ✅ 6 个扩展接口骨架：`VoiceInputService` / `FaceAuthService` / `AppIntent + Dispatcher` / `InteractionLogger` / `ServiceRepository`（Semantics 留到 Phase 2 贴皮时按页面添加）
- ✅ PhoneFrame：Web 端 405×880 dp 固定画框 + FittedBox 等比缩放
- ✅ 验收通过：`flutter analyze` 0 issues / `flutter build web` 30 秒构建 / 用户浏览器端跑通 7 步点击路径
