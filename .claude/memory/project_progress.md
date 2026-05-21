---
name: 项目开发进展
description: 会话 15 后状态 — 代理引导机制大重构 + 跨页 session + Bug 修复，18 文件未提交
type: project
---

## 当前状态（2026-05-21 会话 15 后）

本地有 18 个文件改动，**尚未 git commit / push**。

**会话 15 核心交付**：

### 1. Bug 修复
- Bug 1：AgentFab 面板自动关闭 → 删除 `_scheduleAutoDismiss`
- Bug 2：cmd_highlight element_key 错配 → login_page 补 `chk_agree_terms`；prompt 对齐 `btn_login` / `btn_verify_login`；agent_command_executor 加 debugPrint 日志

### 2. 跨页 session 不断连
- 新建 `app/lib/services/agent_session.dart` 单例（WS 连接 + 消息分发 + 页面绑定）
- agent_fab.dart 大瘦身（约 250 行删减），BubbleWindow 不再拥有 WS / executor
- 面板状态（panelOpen）/ 未读红点（hasNewMessage）提升到 AgentSession 全局
- 跳页动画跳过（consumeAnimateOpenFlag）

### 3. 代理引导机制升级（核心重构）
- **页面知识库** `backend/knowledge/pages.py`：10 个页面（含新增 /my、/service/yibao-hub），结构化 ElementSpec / PageSpec / Transition + BFS find_path
- **页面感知**：前端 page_changed → 后端 AgentCore.set_current_page 实时同步
- **5 个 scene prompt 三段式重写**：标准操作流程写死 + LLM 仅选起点 + 环境信息自动注入
- **agent_core 改造**：`_build_executor_prompt` + `_render_environment_section` + `SCENE_TARGET_ROUTE` + `SCENE_DONE_SUMMARY` 硬编码兜底
- **启动校验**：`_validate_prompts_against_knowledge()` 部署期拦截 element_key / route 漂移
- **_EXECUTOR_PREFIX 重写**：明确 voice_hint 与 response.content 两渠道分工
- **工具职责清晰化**：cmd_say 唯一发声+入气泡；cmd_highlight / cmd_navigate / cmd_press_button / fill_field 纯 UI 操作不发声不入气泡；task_done summary 不入气泡
- **prompt cmd_say + cmd_highlight 配对模式**：每步先 cmd_say 说话，紧跟 cmd_highlight 高亮

### 4. 前端元素注册
- 5 个新 element_key：`tab_my`（elder_bottom_nav）、`card_yibao_hub`（elder_home）、`btn_go_login`（mine_page）、`card_yibao_jiaofei_entry` + `card_yibao_query_entry`（yibao_hub_page）
- `btn_switch_elder`（standard_home）

### 5. 文档
- DEPLOY.md 前端启动改为 release build + 静态服务
- AGENT_KNOWLEDGE_DESIGN.md v2.0 全链路技术方案

**未解决的已知问题**：

1. **高亮挖洞不生效** — Flutter Web HTML renderer 下 Path.combine(difference) 不工作，蒙版全屏无洞。architect 已出方案（saveLayer + BlendMode.clear），未实施
2. **蒙版层级** — 蒙版遮住聊天框（应该不遮）；底部导航栏没被遮（应该遮住只挖洞）。architect 有方案（多洞 + panelRect 上报），未实施
3. **LLM 一次执行完就结束** — 缺少"等用户操作 → 感知页面变化 → 继续下一步"的循环机制。当前 LLM 只做当前页能做的步骤就 task_done
4. **LLM response.content 仍不空** — prefix 已反复强调空字符串，但 DeepSeek 仍输出思考过程。SCENE_DONE_SUMMARY 硬编码兜住了最终气泡
5. **工具职责审查** — 用户要求 architect 审查所有工具职责边界，architect 未回复即关闭
6. **O-2：pop 返回 executor 失效** — 用户按浏览器返回时 unbindPage 清掉 executor，已知未修
7. **草稿重复追加** — _checkPageDraft 反复执行会重复追加 draft_prompt 卡
8. **btn_query 双重注册** — pension_query 和 yibao_query 都注册 'btn_query'

**下次会话接续点**：
- **首要**：修高亮挖洞（saveLayer + BlendMode.clear）+ 蒙版层级（多洞 + 聊天框不被遮）
- 工具职责边界审查（用户上次要求的，被中断）
- LLM 多步执行机制（等用户操作后继续下一步）— 这是代理引导能真正跑通的关键
- 测试完整登录流程端到端
- git commit 会话 15 所有改动

**Why:** 下次会话恢复时快速了解会话 15 做了什么、哪些问题待修。
**How to apply:** 新会话读此记忆，直接接续未修问题。
