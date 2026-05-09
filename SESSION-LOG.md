# 会话日志

每次对话会话结束时记录。用于下次会话快速恢复上下文。**按时间倒序排列，最新会话在最前面。**

---

## 2026-05-09（会话 5）

**主要工作**：
- 前端流程回退：还原旧版（archive/scene-canvas-v1）层级结构，恢复 PhoneFrame 壳、Riverpod ProviderScope、双模式主题
- AgentPanel 协议 P0 Bug 修复：agent_wake payload、permission_response 消息类型、field_key/button_key 字段名对齐
- PersistentBanner 改 Riverpod 响应式；路由路径统一 AppRoutes 常量（18 处硬编码消除）
- WakeWordListener 单例竞争修复（引用计数）
- 草稿写入链路打通（DraftService.autoSave + AgentPanel draft_hint 提示）
- 语音引导 TTS（voice_hint 接入 Web Speech API SpeechSynthesis）
- 长辈首页搜索条入口补回（_EldSearchBar，橙底白框 52dp）
- 后端 scene prompt 路由前缀同步
- 产出 docs/USER_JOURNEY.md v1.0（4 场景用户旅程图 + 情感曲线 + 前端支撑评估 + 3 条调整建议）
- 产出 docs/DEPLOY.md（部署指引，含云服务器配置、Nginx + HTTPS、systemd 服务）

**团队参与**：PM / architect / frontend / backend / reviewer 全员参与

**关键决策**：
- 搜索入口方案：方案 B（内容区顶部搜索条），PM + architect 一致推荐，改动约 25 行，无技术阻碍
- 用户旅程图 3 条调整建议定稿：①刷脸弹窗语音前移（Prompt 加 1 行，列入 N5）；②身份证脱敏接受现状（mock 数据安全风险为零）；③TTS 同步计时改造（N4 真机测试后按需实施）
- 身份证号脱敏当前由前端 _redactValue 渲染打码，后端 WS 消息传明文但为 mock 数据，毕设阶段接受现状

**当前状态**：
- 前端 P0 Bug 全部修复，主流程可在 localhost 跑通
- 草稿写入 / 语音引导 TTS 已实现，待真机验证（N4）
- 下一步：N1 麦克风 Web Speech API 接入 → N2 云服务器部署 → N3 Flutter Web Build → N4 真机测试 → N5 Prompt 调优（含刷脸弹窗语音前移）→ N6 答辩准备
- 下次会话恢复点：确认是否购买云服务器（U1）；N1 麦克风接入可立即开始

---

## 2026-04-28（会话 3）

**主要工作**：
- 启动 CC Team（5 人：PM / architect / frontend / backend / reviewer，均 Sonnet 模型）
- architect 通读 4 份设计文档，产出 `docs/IMPLEMENTATION_PLAN.md`（10 个子任务、4 个 Phase）
- PM 审阅实施计划，提出 3 条调整建议 + 1 条风险补充

**关键决策**：
- 实施计划拆为 4 Phase：Phase 1 后端骨架+Flutter 初始化 → Phase 2 Agent 核心+ASR/TTS+WS 客户端+面板 UI+页面骨架 → Phase 3 指令执行层+草稿箱 → Phase 4 端到端集成
- PM 审阅发现 3 处待调整：① T4 主题字号应为 18sp（非 14sp，PRD 适老化要求）；② T9 需补充医保查询场景（PRD P0 功能被遗漏）；③ Phase 4 验收表需补注草稿箱演示前置步骤
- PM 补充风险：老年用户口音可能影响讯飞 ASR 识别率，建议 T9 加入识别率底线测试
- 以上调整建议用户确认采纳前会话结束，**下次会话需先让 architect 修订 IMPLEMENTATION_PLAN.md 再开工**

**当前状态**：
- 实施计划初稿已出，待用户确认 PM 的调整建议后修订
- 零代码文件，编码尚未开始
- 下次会话恢复点：确认调整建议 → architect 修订计划 → 开始 Phase 1

---

## 2026-04-28（会话 2）

**主要工作**：
- 完成代理设计定义最后 3 组问答（组 D 草稿箱与操作记录 / 组 F 错误恢复 / 组 G 开放补充）
- 更新 `docs/AGENT_DEFINITION_QUESTIONS.md` 全部答案
- 产出 `docs/AGENT_SPEC.md` v1.0（代理设计规范，7 组问答定稿）
- 清理项目结构：旧设计文档归档 `docs/archive/pre-redefinition/`，场景画布归档 `archive/scene-canvas-v1/`，SDK 和脚本移至 `archive/` 下
- 产出 `docs/PRD.md` v1.0（产品需求文档，4 场景用户故事 + 验收标准 + 功能清单）
- 启动团队（PM / architect / frontend / backend / reviewer）
- 产出 `docs/ARCHITECTURE.md` v1.2（系统架构，FastAPI + Agno Agent + DeepSeek-V3 + 讯飞 ASR/TTS，含 WebSocket 协议 15 种消息类型）
- 产出 `docs/UI_UX_DESIGN.md` v1.0（UI/UX 交互设计，4 场景逐步剧本 + 适老化规范 + 代理面板设计）
- 更新 CLAUDE.md 项目结构和当前阶段描述

**关键决策**：
- 代理名字定为"小浙"，形象为卡通化"浙"字小人
- 草稿箱为页面级快照，只存已完成字段，存于前端 IndexedDB
- 子女查看操作记录方式：拿老人手机直接看，不涉及远程/多账号
- 后端框架选 Agno（用户有使用经验，HITL 机制天然对应权限一事一授；v1.0/v1.1 曾推荐手写状态机，用户要求改为 Agno 后 v1.2 定稿）
- 确定性按钮不注册为 Agno 工具，实现物理隔离；非确定性按钮用 `is_deterministic` 字段 + 前端白名单双重保障
- "助手"按钮放底部 Tab 栏中央，替代原浙里办搜索麦克风位

**当前状态**：
- 设计阶段全部完成，下一步进入编码实施
- 团队已启动，需先出实施计划再开始编码

---

## 2026-04-27（会话 1）

**主要工作**：
- 从 image-search 项目的 `.claude/skills/` 学习项目管理经验（project-documentation + team-management）
- 将经验沉淀到 `.claude/memory/`：更新 `feedback_team_mode.md`（补充派活纪律、成员约束），新建 `feedback_project_documentation.md`（四文档机制）
- 建立四文档体系：ISSUES.md / COMMITS.md / SESSION-LOG.md / CLAUDE.md（均在项目根）
- 清理不需要的文件：删除 `project_tech_decisions.md`、`feedback_working_style.md`（内容已在 CLAUDE.md 中覆盖）；删除整个 `.claude/skills/` 目录和 `skills-lock.json`

**关键决策**：
- 问题清单命名为 ISSUES.md（对齐 image-search skill 定义），状态标记 5 种：✅/🧪/🔧/🐛/❓
- 四文档全部放项目根目录，不放 docs/ 子目录
- skill 文件对本项目无用，只保留 memory 沉淀
- team-personas 通用版骨架暂不定制，等需要时再改

**当前状态**：
- 代理定义期：`docs/AGENT_DEFINITION_QUESTIONS.md` 用户逐条答题中（组 A~E 已定稿）
- 场景画布 v1 封存在 `archive/scene-canvas-v1/`
- 四文档体系已建立，后续每次会话/提交按机制维护
