# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在本仓库中工作时提供指引。

## 记忆系统路径（重要）

本项目所有记忆（user/feedback/project/reference）的**读取与写入**统一使用项目内路径：

```
/home/getui/codes/liangyc/archive/test/.claude/memory/
```

**禁止**使用 Claude Code 默认的全局路径 `/home/getui/codes/liangyc/.claude/projects/-home-getui-codes-liangyc-archive-test/memory/`。

- `MEMORY.md` 索引文件位于 `.claude/memory/MEMORY.md`
- 新增记忆时写入 `.claude/memory/<memory_name>.md` 并在同目录 `MEMORY.md` 中登记
- 读取记忆时仅从此目录加载，不要回落到默认路径

## 仓库定位（2026-04-22 重新定义）

本项目为本科毕业设计，学术定位见开题报告：**《信息服务 APP 的适老化设计与多模态交互》**。

**核心创新点**：**受控响应型智能代理**（权限受控 + 行为受控 + 不主动挑事，只在用户有需求时介入）。围绕该代理设计展开适老化交互与多模态交互研究。

**当前阶段**：代理的设计定义尚未完成。工作文档为 `docs/AGENT_DEFINITION_QUESTIONS.md`（用户逐条答题中）。答完后产出 `docs/AGENT_SPEC.md` 作为权威设计规范，再进入实施。

**"浙里办长辈版复刻"的定位**：Phase 1/2 已完成的 11 页 Flutter Web 原型 + FastAPI 代理后端已**整体归档至 `archive/scene-canvas-v1/`**，作为未来代理演示的背景载体保留，**不再追求像素级还原**。浙里办只是场景画布，不是最终交付物。重新激活时再按需从归档目录取出。

**旧设计文档**（PRD v2.0 / PROJECT_PLAN / AGENT_ARCHITECTURE / AGENT_UI_SPEC / AGENT_WEBSOCKET_SCHEMA / TECH_STACK_REVIEW）已全部归档至 `docs/archive/pre-redefinition/`，**不作为当前设计依据**。

## 参考资料结构

- `docs/AGENT_DEFINITION_QUESTIONS.md` — **当前活动的设计工作文档**。用户逐条回答其中问题后产出新 SPEC。
- `docs/TODO.md` — **本项目唯一的** todolist 活文档。新增问题/任务一律写入此文件；**不要**创建并行的第二个待办文件。状态：🔲 待做 / 🧪 待验证 / ✅ 已完成。
- `docs/信息服务APP的适老化设计与多模态交互_开题报告初稿.txt` — 毕业设计开题报告（文献综述、研究方法、进度安排）。**论文北极星**，所有设计决策需与此对齐。
- `docs/references/` — 4 份用户前期产出的权威源文档（用户调研报告 / 用户需求文档 / 核心场景流程设计文档 / 交互逻辑设计文档）。`.docx` 格式。
- `docs/复刻浙里办/浙里办页面逻辑.txt` — 浙里办页面跳转与弹窗的叙述性流程说明。**场景画布参考**，非设计依据。
- `docs/复刻浙里办/截图/` — 32 张浙里办权威截图。**场景画布参考**。
- `docs/archive/pre-redefinition/` — 重定义前的旧设计文档归档（仅供历史参考）。
- `docs/archive/team-personas/` — 5 份 CC Team persona 通用骨架（当前未启用）。

## 场景画布 v1 内部约定（封存不动，未来复用时沿用）

以下约定是 Phase 1/2 已固化的场景画布内部规则，**仅在重新启用 `archive/scene-canvas-v1/` 下的代码时适用**，不是当前代理设计的依据。

**两种视觉模式：** 标准版主色 `#2D74DC`（蓝色），长辈版主色 `#FF6D00`（橙色）。长辈版通过标准版首页专用入口进入，不是主题开关。

**两类弹窗（代码里两套独立组件族）：**
- `SystemDialog` — 阻塞式的操作系统级权限请求（摄像头、麦克风），处理后流程才能继续
- `InAppOverlay` — 非阻塞式浮层（登录提示、同意条款等），用户可关闭或忽略

**两条登录分支：** 刷脸路径（同意条款 → 刷脸 InAppOverlay → 摄像头 SystemDialog → 眨眼/摇头）；验证码备选路径（其他方式认证 → 验证码页 → SystemDialog）。

**11 个页面（已实现于 `archive/scene-canvas-v1/lib/features/`）：** SplashPage、StandardHomePage、ElderHomePage（含 Tab）、LoginPage、FaceAuthPage、VerifyPage、SearchPage、SearchResultPage、SocialInsurancePage、PensionQueryPage、MyPage。

**代理后端（已实现于 `archive/scene-canvas-v1/backend/`）：** FastAPI 骨架 + WebSocket + Agno Agent + DeepSeek-V3 LLM（Step 1-4 已完成，未接前端）。

## 工作准则

- 截图文件名与文档中的页面名均为中文。在引用和提交信息中保持中文原样，**不要**转写为拼音或英文。
- 当前阶段（代理定义期）**不对 `archive/scene-canvas-v1/` 下的任何代码做功能性改动**。若新设计需要改动，待 `docs/AGENT_SPEC.md` 产出后再决定是"原地解冻修改"还是"按需从归档取组件到新目录"。
- 需要运行场景画布时，先 `cd archive/scene-canvas-v1/`，再用 `../../bin/flutter <cmd>` 调用项目级 Flutter SDK（SDK 仍在根 `tools/flutter/`，包装脚本仍在根 `bin/`）。

## 本地工具链约定

**使用项目级 Flutter SDK，不用系统级。** 所有 Flutter/Dart 命令走项目内包装脚本：

```bash
./bin/flutter <cmd>    # 不是 flutter <cmd>
./bin/dart <cmd>       # 不是 dart <cmd>
```

- SDK 位于 `tools/flutter/`（~1.5 GB，已 `.gitignore` 排除）
- 包装脚本自动设置镜像环境变量 `PUB_HOSTED_URL=https://pub.flutter-io.cn` 和 `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`
- **不要**改 `~/.bashrc` / 不要把 `tools/flutter/bin` 加入系统 PATH——项目级隔离是刻意设计
- `flutter doctor` 会报 "binary not on PATH" 警告，这是预期的，不用修

## 导航决策约定（go / push / pop / NoTransitionPage）

Phase 1 结束时由 architect 统一定稿，全员照此写新代码。

### go / push / pop 决策矩阵

| 操作 | 场景 | 举例 |
|---|---|---|
| `context.go(dest)` | 同级 Tab 切换 / 流程终结 / 应用初始化（替换栈） | `/elder ↔ /my` / auth 成功→ `/elder` / Splash → `/home` |
| `context.push(dest)` | 钻取导航 / 打开有"取消或返回"的全屏页（入栈） | `/search → /search/result → /service/...` / 首页搜索入口→ `/search` |
| `context.pop()` | 页面内×/取消/返回（回上一页） | SearchPage 取消、服务页返回 |
| `context.replace(dest)` | 替换当前 URL 但**不增加历史条目** | SearchResultPage 新 query 提交时 |

**核心原则**：凡目的页有"取消/×/返回"按钮且语义是"回到来源"，**必须用 push 进入 + pop 退出**；凡进入后不应后退（流程终结 / Tab 切换），用 go。

### NoTransitionPage 适用

**用户感知上是横向平移的 Tab 切换**时用 `NoTransitionPage`（瞬时无动画）；钻取 / 流程 / 弹出用默认动画。

当前已配置：`/elder` 和 `/my` 用 `NoTransitionPage`。其他路由保持默认动画。

Phase 2 若新增 Tab 式切换（例如 StandardHomePage 5 Tab 联通），**优先用 IndexedStack 在页面内部切换**，不拆路由——避免引入新的 `NoTransitionPage` 判断。

### PersistentBanner 挂载范围

**原则**：Banner 只挂在用户"落脚停留"的主目的地页，不挂在流程中间页和钻取详情页。

- 挂 banner：StandardHomePage / ElderHomePage / MyPage
- 不挂 banner：LoginPage / FaceAuthPage / VerifyPage（登录流程中）/ SearchPage / SearchResultPage / 服务详情页

### URL 与状态同步

**进 URL 的条件**：该值满足"书签直达有意义"。

- 进 URL：SearchResult 的 `q`（用户可分享/直达）
- 不进 URL：SocialInsurancePage 的 `_sub`（依赖会话上下文）、表单中间态、`modeProvider`（由 `/home` vs `/elder` 隐含）

**不要**把 URL 状态缓存进 widget State 字段，应始终从 `GoRouterState.of(context).uri.queryParameters` 读取。若页面内改变 URL 相关状态，走 `context.replace(newUrl)` 同步。
