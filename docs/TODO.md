# 项目 Todolist

本项目唯一的活待办文件。新增问题/任务统一写入此文件。

**状态图例：** 🔲 待做 · 🧪 已做完待用户验证 · ✅ 用户已确认完成

---

## 当前待办

### Phase 1：主线黑白线框版（进行中）

按 `docs/REPRODUCTION_PLAN.md` §五.4 分 5 批：

- 🧪 **批次 1：SplashPage + StandardHomePage** 灰块线框（待用户验收）
- 🔲 批次 2：ElderHomePage 骨架 + 立即登录弹窗（3 Tab + 滚动 + InAppOverlay）
- 🔲 批次 3：LoginPage + FaceAuthPage 静态（含两类弹窗链路）
- 🔲 批次 4：SearchPage + SearchResultPage（query 路由参数 + 麦克风流程）
- 🔲 批次 5：SocialInsurancePage + PensionQueryPage + MyPage
- 🔲 Phase 1 终验收：主线能点通、弹窗分类正确、黑白线框视觉统一

---

## 已提交待验证

<!-- 新记录插入最上方 -->

- 🧪 **Phase 1 批次 1：SplashPage + StandardHomePage**（2026-04-18）
  - 改动：`lib/features/splash/splash_page.dart` / `lib/features/home/standard_home_page.dart`
  - SplashPage：StatefulWidget + `initState` delay 1500ms + `mounted && !_navigated` 双重防护跳转 `/home`
  - StandardHomePage：6 个语义 Section（`_HeroSection` / `_ServiceGridSection` / `_NewsBarSection` / `_HotServiceSection` / `_LoginPromptSection` / `_DevNavSection`）+ `_BottomNavBar`
  - frontend 自验 + architect review 双通过（`flutter analyze` 0 issues / `flutter build web` 通过）
  - **测试方法**（浏览器）：
    1. 终端跑 `./bin/flutter build web && python3 -m http.server 8080 --directory build/web --bind 0.0.0.0`
    2. 浏览器开 `http://localhost:8080/`
    3. 启动页自动过 ~1.5 秒跳到标准首页（不用点按钮）
    4. 标准首页：蓝色 Hero 区（logo + 快捷操作 + Banner + 搜索框）、2×4 服务网格、最新消息条、热门服务区、登录引导、开发导航面板、底部 5 Tab
    5. 点「长辈版」快捷按钮 → 主题变橙 + 跳 ElderHomePage
    6. 点搜索框 → 跳 SearchPage
    7. 点开发导航面板任一条 → 能跳到对应页

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

---

## 提交记录

> 新记录插入最上方。完整 diff 看 `git log`；本区只概括每个 commit 做了什么。

### 2026-04-18 · `<pending>` · feat(phase-1): 批次 1 — SplashPage + StandardHomePage 灰块线框
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
