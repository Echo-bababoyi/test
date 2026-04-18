# 项目 Todolist

本项目唯一的活待办文件。新增问题/任务统一写入此文件。

**状态图例：** 🔲 待做 · 🧪 已做完待用户验证 · ✅ 用户已确认完成

---

## 当前待办

### Phase 1：主线黑白线框版（进行中）

按 `docs/REPRODUCTION_PLAN.md` §五.4 分 5 批：

- ✅ 批次 1：SplashPage + StandardHomePage 灰块线框（2026-04-18 用户验收通过）
- 🧪 批次 2：ElderHomePage 骨架 + 立即登录弹窗（待用户验收）
- 🔲 批次 3：LoginPage + FaceAuthPage 静态（含两类弹窗链路） ← **下一步**
- 🔲 批次 4：SearchPage + SearchResultPage（query 路由参数 + 麦克风流程）
- 🔲 批次 5：SocialInsurancePage + PensionQueryPage + MyPage
- 🔲 Phase 1 终验收：主线能点通、弹窗分类正确、黑白线框视觉统一

### Phase 1 小修（低优，批次 3-5 哪次顺手哪次做）

- 🔲 `StandardHomePage._TopBarRow` 右侧加**通知铃铛**灰块占位（batch 1 reviewer 发现）

### Phase 2 必修项（已登记，贴皮阶段必须做）

- 🔲 **ElderHomePage 结构重排**（architect batch 2 review 发现）：
  - `_EldGovHotlineSection` 从各 Tab ScrollView 顶部移到 `AppBar.bottom`（只保留一份）
  - TabBar 从 `AppBar.bottom` 移到 `Scaffold.body` 顶部（白色卡片容器内）
  - 对齐截图的视觉分层：AppBar 含橙区 + 工具行 + 政务热线条；Body 顶是白色 TabBar 卡片 + TabBarView

---

## 已提交待验证

<!-- 新记录插入最上方 -->

- 🧪 **Phase 1 批次 2：ElderHomePage 骨架 + 立即登录弹窗**（2026-04-18）
  - 改动：`lib/features/home/elder_home_page.dart`（全量重写 63→450+ 行）
  - 3 Tab（热门服务 / 我的常用 / 我的订阅）+ 各 Tab 独立 `SingleChildScrollView`
  - 热门服务 Tab 3 段拼接：`_EldHotServiceCardSection` / `_EldOnlineServiceSection` / `_EldOfflineAndFooterSection`
  - 共用组件：`_EldGovHotlineSection` / `_EldToolBarItem` / `_EldServiceGridItem` / `_EldOfficeItem`
  - 立即登录 InAppOverlay：严格按 §5.1 Q3 规范，`addPostFrameCallback` + `mounted` + `ref.read(loginProvider)` 一次性检查，切 Tab / 热重启不重复弹
  - 底部导航 3 项（首页 / 搜索 / 我的，对照截图 frontend 主动纠正我 task 里说的 2 项）
  - 质量：`flutter analyze` 0 issues / `flutter build web` 通过 / architect code review 通过
  - 已知 Phase 2 必修项：TabBar 位置与政务热线条位置对调（见当前待办「Phase 2 必修项」）

---

## 已完成

<!-- 用户确认后从"已提交待验证"迁移到这里 -->

### Phase 1：主线黑白线框版

#### 批次 1：SplashPage + StandardHomePage 灰块线框（2026-04-18）

- ✅ SplashPage：1.5s 自动跳 `/home`，双重防护（`mounted` + `_navigated`）
- ✅ StandardHomePage：6 个语义 Section + 5 Tab 底部导航；蓝色 `#2D74DC` Hero 区 + 2×4 服务网格 + 长辈版入口按钮 + 搜索框入口
- ✅ 质量：`flutter analyze` 0 issues / `flutter build web` 通过 / architect code review 通过 / reviewer 对照 §四 验收条通过 / 用户 7 步点击路径通过
- 已知轻度问题（留到后续批次顺手改）：`_TopBarRow` 右侧缺通知铃铛占位（见当前待办「Phase 1 小修」）

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

---

## 提交记录

> 新记录插入最上方。完整 diff 看 `git log`；本区只概括每个 commit 做了什么。

### 2026-04-18 · `<pending>` · feat(phase-1): 批次 2 — ElderHomePage 骨架 + 立即登录 InAppOverlay
- `lib/features/home/elder_home_page.dart` 全量重写（63→450+ 行）
- 架构：`AppBar(bottom: PreferredSize(Column[工具行, TabBar]))` + `TabBarView`（3 Tab）+ `BottomNavigationBar`（3 项）
- 热门服务 Tab 拆 3 段：`_EldHotServiceCardSection` / `_EldOnlineServiceSection` / `_EldOfflineAndFooterSection`；共用 `_EldGovHotlineSection` / `_EldServiceGridItem` / `_EldOfficeItem`
- 立即登录弹窗按 §5.1 Q3 实现（initState + addPostFrameCallback + 双重守卫，不用 ref.listen）
- 底部导航 3 项（首页 / 搜索 / 我的），搜索与我的路由联通
- architect review：✅ 通过；登记 Phase 2 必修项「TabBar 位置 + 政务热线条位置对调」到 TODO

### 2026-04-18 · `4504f06` · feat(phase-1): 批次 1 — SplashPage + StandardHomePage 灰块线框
- `lib/features/splash/splash_page.dart`：`ConsumerWidget` → `StatefulWidget`，`initState` delay 1.5s 自动跳 `/home`，双重防护（`mounted` + `_navigated`）
- `lib/features/home/standard_home_page.dart`：拆 6 个语义 Section（Hero / ServiceGrid / NewsBar / HotService / LoginPrompt / DevNav）+ `_BottomNavBar`；Hero 区蓝底含顶栏 logo 占位、3 快捷操作（含「长辈版」入口）、Banner 占位、搜索框；服务网格 2×4；保留 `_DevNavSection` 开发导航面板（Phase 2 删）
- frontend 自验 + architect review 双通过
- Phase 1 分 5 批实施计划同步落入 `docs/TODO.md`

### 2026-04-18 · `3dc1d9e` · docs: Phase 1-4 完美复刻计划（PM 主笔 + architect 技术章节）
- 新增 `docs/REPRODUCTION_PLAN.md`（443 行）——团队产出的完美复刻计划
- 含 32 张截图→Flutter 资源映射、主线 + 4 分支流程图、11 页 P1-P11 优先级、每页可勾选验收标准、5 个技术决策、10 个弹窗清单、5 个复刻瓶颈预警

### 2026-04-18 · `6c60c2e` · docs(memory): 团队成员默认用 Sonnet 模型
- `.claude/memory/feedback_team_collaboration.md` 新增一节
- 启动团队时 5 个成员默认用 sonnet，team-lead 保持当前模型（opus）做协调

### 2026-04-18 · `4c2daad` · chore: 装 7 个 Claude Code skill 协助 Phase 1-2 开发
- `.claude/skills/` 新增 7 个纯 markdown skill（合计 <60 KB）
- find-skills（元技能）+ flutter 官方 5 件套（accessibility / layouts / state / theming / navigation）+ arvindrk/extract-design-system
- `skills-lock.json` 入库

### 2026-04-17 · `41b3be3` · feat(phase-0): Flutter 骨架 — 11 页 + Riverpod + go_router + 两套弹窗 + 6 扩展接口
- `lib/` 完整骨架（core + features + services）
- 11 页面占位 Scaffold + 路由全连通 + 双主题 + 双弹窗组件族（SystemDialog / InAppOverlay）+ 6 扩展接口 mock（VoiceInput / FaceAuth / ServiceRepository / AppIntent / InteractionLogger / PhoneFrame）
- `flutter analyze` 0 issues / `flutter build web` 30 秒通过

### 2026-04-17 · `9ce9842` · chore: 安装项目级 Flutter SDK + 包装脚本
- `bin/flutter` / `bin/dart` 包装脚本（自动走 flutter-io.cn 镜像）
- Flutter 3.41.7 装在 `tools/flutter/`（gitignored，不入库）

### 2026-04-17 · `d90606a` · chore: 立项 — 项目蓝图、文档结构、记忆系统
- `CLAUDE.md` / `docs/` / `.claude/memory/` / `.gitignore`
- 32 张截图 + 页面逻辑 + 开题报告 + 5 份 persona 骨架
