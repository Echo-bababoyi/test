# 提交记录

按时间倒序。每条记录包含 commit hash、标题、改动要点。

---

### 2026-05-09（会话 5）— 前端 P0 修复 + 功能补全 + 产品文档

**前端流程回退 + P0 Bug 修复**
- 还原旧版层级结构：闪屏页（1.5s）→ 标准首页 → 长辈首页，PhoneFrame 壳包裹所有路由
- main.dart 恢复 Riverpod ProviderScope + 双模式主题（AppTheme.of(mode)）
- 路由路径全部改用 AppRoutes 常量（消除 18 处硬编码）
- PersistentBanner 改为 Riverpod authProvider 响应式，登录后自动消失
- AgentPanel 协议对齐：修复 agent_wake payload、permission_response 消息类型、field_key/button_key 字段名与后端协议不一致等 P0 Bug
- WakeWordListener 单例竞争修复（引用计数模式）

**功能补全（待测）**
- 草稿写入链路：DraftService.autoSave 补全，字段变化自动写 IndexedDB；AgentPanel 收到 draft_hint 显示恢复提示
- 语音引导 TTS：cmd_highlight/cmd_fill_field/cmd_navigate 的 voice_hint 接入 Web Speech API SpeechSynthesis

**产品侧**
- 长辈首页插入搜索条入口（_EldSearchBar，橙底白框 52dp），弥补小浙助手占用搜索 FAB 后的入口缺失
- 后端 scene prompt 路由前缀与 AppRoutes 同步
- 产出 docs/USER_JOURNEY.md v1.0（4 场景用户旅程图 + 情感曲线 + 前端支撑评估 + 3 条 PM/architect 联合调整建议）

---

### c7e1d55 refactor: 项目重构 — 设计阶段全部完成，进入实施准备
- 项目结构重构，设计阶段收尾
- 更新 CLAUDE.md 当前阶段描述
- 标记进入编码实施阶段

### 5f82ef1 docs(agent-def): 组 C 完整定稿 + 新增横切原则 3 "权限一事一授"
- 组 C（代理能力矩阵与权限控制）完整定稿
- 新增横切原则 3：权限一事一授

### 9ca5b6b docs(agent-def): 组 C 能力矩阵定稿 + C2/C3 派生消解
- 能力矩阵定稿
- C2/C3 派生问题消解

### b499525 docs(agent-def): 组 B3 定稿 — 执行前必先复述确认
- 组 B3 定稿：代理执行操作前必须先复述确认

### d878f0c docs(agent-def): 组 B2 定稿 — 区分情景应答
- 组 B2 定稿：区分不同情景下的应答策略

### 627c2cf docs(agent-def): 组 B1 定稿 + 横切原则 2 "确定性操作代理止步"
- 组 B1 定稿
- 新增横切原则 2：确定性操作代理止步

### 3680289 docs(agent-def): 组 A 粗线条通过 — 底部对话区，细节留待原型
- 组 A（代理入口与交互形态）粗线条通过
- 底部对话区方案，细节留待原型阶段确定

### 653e5e1 docs(agent-def): 组 E 定稿 — 代理永远不主动
- 组 E 定稿：代理永远不主动发起交互

### 8fbd627 chore: 项目结构扁平化 — archive/ 一级承载所有冻结资产
- 将 tools/ bin/ 等移入 archive/ 目录
- archive/ 统一承载所有冻结资产（SDK、场景画布、脚本）

### 82a449a chore: 场景画布 v1 整体归档到 archive/scene-canvas-v1/
- Phase 1/2 的 Flutter Web 原型 + FastAPI 后端整体归档
- 不再追求像素级还原，作为未来演示背景载体保留

### 23e29af chore: 项目重新定义 — 旧设计归档 + 代理定义工作文档启动
- 旧设计文档（PRD/PROJECT_PLAN 等）归档至 docs/archive/pre-redefinition/
- 新建 AGENT_DEFINITION_QUESTIONS.md 工作文档
- CLAUDE.md 重写，确立"受控响应型智能代理"为核心创新点
