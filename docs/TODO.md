# 项目 Todolist

本项目唯一的活待办文件。新增问题/任务统一写入此文件。

**状态图例：** 🔲 待做 · 🧪 已做完待用户验证 · ✅ 用户已确认完成

---

## 当前待办

### Phase 1：主线黑白线框版（进行中）

按 `docs/REPRODUCTION_PLAN.md` §五.4 分 5 批：

- ✅ 批次 1：SplashPage + StandardHomePage 灰块线框（2026-04-18 用户验收通过）
- ✅ 批次 2：ElderHomePage 回炉 + PersistentBanner 第三类 UI 元素（2026-04-18 用户 12 步验收通过，5 个事实错误全修）
- 🔲 批次 3：LoginPage + FaceAuthPage 静态（含两类弹窗链路） ← **下一步**
- 🔲 批次 4：SearchPage + SearchResultPage（query 路由参数 + 麦克风流程）
- 🔲 批次 5：SocialInsurancePage + PensionQueryPage + MyPage
- 🔲 Phase 1 终验收：主线能点通、弹窗分类正确、黑白线框视觉统一

### Phase 1 小修（低优，批次 3-5 哪次顺手哪次做）

- 🔲 `StandardHomePage._TopBarRow` 右侧加**通知铃铛**灰块占位（batch 1 reviewer 发现）

### Phase 2 必修项（已登记，贴皮阶段必做）

- 🔲 `_EldTabCardSection` IndexedStack 改用 `ListenableBuilder(listenable: tab)` 局部重建（当前 `_tab.addListener(setState)` 每帧全页重建，虽不影响正确性但开销冗余）
- 🔲 `PersistentBanner.bannerButton` 在长辈模式下读 `modeProvider` 改用 `elderPrimary`（截图里长辈版 banner 按钮是橙色而非蓝色）
- 🔲 Banner 文字颜色从 `Colors.white` 改为灰色（对齐截图）
- 🔲 长辈版 AppBar「个人频道」pill 加刷新/同步图标（对齐截图）
- 🔲 长辈版底部 FAB 颜色从 `Colors.grey[500]` 改为 `AppColors.elderPrimary`（对齐截图）

---

## 已提交待验证

<!-- 新记录插入最上方 -->

_（暂无——批次 2 已被打回，5 个事实错误详见当前待办「批次 2 回炉」）_

---

## 已完成

<!-- 用户确认后从"已提交待验证"迁移到这里 -->

### Phase 1：主线黑白线框版

#### 批次 2：ElderHomePage 回炉 + PersistentBanner（2026-04-18）

- ✅ 新增第三类 UI 元素 `PersistentBanner`（常驻横条，非阻塞，× 关闭 session 内不重现，跨页共享 dismiss 态）
- ✅ 立即登录从 InAppOverlay 升级为 PersistentBanner，标准版 + 长辈版都挂
- ✅ ElderHomePage 结构大改：工具行 / 政务热线 / Tab 卡片 / 各常驻栏目按截图分层（工具行随滚、AppBar 固定只留地区+个人频道）
- ✅ Tab 降级为 IndexedStack 嵌入式切换器，只影响"浙里医保"那一小块；其他区块全常驻
- ✅ 长辈版底部导航改为 BottomAppBar + FAB centerDocked（中间大圆麦克风按钮跳 `/search`）
- ✅ 删 ElderHomePage AppBar 右上搜索 icon
- ✅ REPRODUCTION_PLAN §四 + §六 同步修订（PM 主笔）
- ✅ 质量：`flutter analyze` 0 issues / `flutter build web` 通过 / architect code review 通过（1 处路由硬编码已修）/ reviewer 对照验收条通过 / 用户 12 步验收通过
- 5 个 Phase 2 小修已登记到「当前待办 > Phase 2 必修项」

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

### 2026-04-18 · `<pending>` · feat(phase-1): 批次 2 回炉 — PersistentBanner + ElderHomePage 重构
- **文档层（PM 主笔修订）：** `docs/REPRODUCTION_PLAN.md` §四 StandardHomePage 新增登录 Banner 验收条；§四 ElderHomePage 全节重写（AppBar 只留地区+个人频道、工具行移入 body、政务热线到 TabBar 上方独立白卡、Tab 只管紧邻一块、其他区块全常驻、底部导航改 3 项含中间大圆搜索）；§六 新增三类 UI 元素定义表（SystemDialog / InAppOverlay / PersistentBanner）+ 弹窗清单按类型重分组（S3 / I5 / P1）
- **新建组件：** `lib/core/widgets/persistent_banner.dart`（第三类 UI 元素骨架：声明式 ConsumerWidget，读 `loginProvider` + `loginBannerDismissedProvider` 双条件控制显示；内含深色胶囊 + × 关闭 + "立即登录"按钮 → `AppRoutes.login`）
- **新增状态：** `lib/core/state/app_state.dart` 加 `LoginBannerDismissedNotifier` + `loginBannerDismissedProvider`（Riverpod v3 无 StateProvider，用 NotifierProvider<bool>）
- **设计 token：** `lib/core/theme/design_tokens.dart` 加 `AppColors.bannerBg` / `bannerButton`
- **StandardHomePage：** 删 `_LoginPromptSection`，body 改 `Stack + Align(bottomCenter) PersistentBanner`
- **ElderHomePage 整页重构：** 全量重写；AppBar 去搜索 icon；工具行 / 政务热线 / Tab 卡片 / 线上一站办 / 线下就近办 / 授权办 / 页脚 全部移入 body `SingleChildScrollView > Column`；Tab 内容走 `IndexedStack` 只包含"浙里医保"那一块；底部 `BottomAppBar + FAB.centerDocked`（麦克风大圆 → `/search`）；body `Stack + PersistentBanner`；彻底删除 `addPostFrameCallback + InAppOverlay.show + _LoginPromptContent`
- 回炉背景：用户 12 步验收发现 5 个事实错误，这轮全部修复
- architect review：⚠️→ ✅（1 处路由硬编码 `/login` 已改为 `AppRoutes.login`）
- 顺带修：批次 1 提交记录的 `<pending>` 回填为 `4504f06`

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
