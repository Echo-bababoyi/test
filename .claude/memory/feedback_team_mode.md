---
name: 团队模式规则（休眠，启动时生效）
description: CC Team 启动方式 / 5 人结构 / team-lead 6 铁律 / Bug 修复 7 步 / 功能增强 6 步 — 目前团队未启动，仅用户显式要求时启用
type: feedback
---

> **触发条件**：用户说"创建团队"、"恢复团队"、"开启团队"、"启动 team"等指令时加载本文件。**非团队模式下忽略所有 team-lead、成员派发等描述**，按常规 1-on-1 协作处理。

## 启动方式

用户说"创建团队"等指令时，使用 **TeamCreate → Agent(team_name=...)** 一次性创建 5 个成员。**不是**在主对话中读 persona 文件然后角色扮演。

**Why**：读 persona 只是信息加载，不等于启动团队协作模式。角色扮演一人分饰多角会混淆上下文、无法并行、拿不到 Team 工具链的分发能力。

## 成员模型默认 Sonnet

5 个成员（PM / architect / frontend / backend / reviewer）默认 `model: "sonnet"`；team-lead（主对话）保持当前模型（通常 opus）做协调。

**Why**：成员执行具体编码/审查/文档任务，sonnet 速度更快、足够胜任；opus 留给 team-lead 做复杂的任务拆分。全员 opus 成本与延迟都翻倍。

## 5 人结构与职责边界

| 角色 | 职责 | 绝不做 |
|------|------|--------|
| PM | 需求分析、方案设计、文档维护、UX 分析 | 不改代码 |
| architect | 架构方案、技术方向、设计评审 | 只给方向不给代码示例，不直接改代码 |
| frontend | 前端代码开发 | 不写文档、不做审查 |
| backend | 后端代码开发 | 不写前端、不写文档 |
| reviewer | 代码审查、验证构建、测试、部署 | 不修改业务代码；未经许可不自行跑测试 |

## team-lead 6 铁律

1. **绝不创建新 agent** — 额外工作分给现有成员
2. **绝不亲自读代码/改代码/排查 bug/写文档** — 所有技术工作委派
3. **收到问题先记录不派活** — 用户测试阶段等用户说"修吧"再分配
4. **发消息后确认收到** — 成员没回复不假设已收到
5. **按职责分配** — 对照职责表，不混乱
6. **不跳过评审流程** — 分析→方案→用户确认→实施→review，不能跳步

## 生命周期

- **创建/恢复**：TeamCreate → 一次性建 5 成员 → team-lead 进入 leader 模式 → SendMessage 派活 → 成员 idle 待命 → 下个任务 SendMessage 唤醒（**不销毁不重建**）
- **重启**：向所有成员发 shutdown_request → 重新 TeamCreate
- **关闭**：向所有成员发 shutdown_request → 退出 leader 模式

## Bug 修复完整流程（7 阶段）

1. **任务选择**：team-lead 读 TODO，推荐优先项目给用户
2. **调查**：派 frontend/backend 调查根因 + 方案（说清楚：问题成因、改哪些文件哪些位置、为什么这样改能解决）
3. **方案审查**：派 architect review 方案（边界情况、风险点）
4. **用户确认**：team-lead 汇报方案 + architect 意见，用户确认后执行
5. **实施**：派成员按审查通过的方案执行，汇报改动摘要 + 编译验证
6. **代码 Review**：派 architect review 实际 diff，有问题回步骤 5
7. **提交 + 测试**：team-lead `git commit`，TODO 标 🧪；用户验证通过后标 ✅

## 功能增强流程（6 阶段）

比 bug 修复多前置 PM 需求 + architect 方案阶段：

1. **需求分析**（PM）：用户故事、验收标准、优先级 → 输出需求文档
2. **技术方案**（architect）：读需求，设计技术方案（文件/函数/改动点）→ 输出方案 + 改动量/风险评估
3. **用户确认**：team-lead 汇报需求摘要 + 技术方案 + 改动范围
4. **实施**：派成员按方案执行
5. **代码 Review**（architect）：review diff
6. **提交 + 测试**：team-lead commit，TODO 标 🧪，用户验证后 ✅

## 派活纪律

### 派活只用 SendMessage
- 不调 `TaskUpdate(owner=X)`（会触发系统自动通知，制造噪音）
- Task 清单仅作 team-lead 看板，owner 保持空

**Why**：TaskUpdate 改 owner 会触发成员收到系统通知，干扰正常派活流程。

### 派活消息必须自包含
- 不引用"上一条消息"、"主对话里"等成员看不到的内容
- 所有素材（文件路径、需求描述、约束条件）内联到同一条 SendMessage 里

**Why**：成员的上下文窗口独立于主对话，看不到 team-lead 和用户之间的对话内容。

### Task 一事一建
- 当前只能有 1 个 in_progress + 最多 1 个 pending
- 禁止预建整条 pipeline 的 N 个 Task
- 上一个 completed 后再 TaskCreate 下一个

**Why**：避免 Task 列表爆炸，保持看板清晰。

## 成员行为约束（每次派活 prompt 尾部附加）

### idle 后静默等待

每次派活的 prompt 尾部必须附加以下约束：
```
完成本任务的汇报后进入 idle，静默等待下一次派活。不得主动：
- 重发或补充已完成任务的方案
- 自查 TaskList 状态或文件系统
- 修改 Task 的 status / owner
- 发 idle 之后的第二轮文字回复
有新想法 → 等 team-lead 主动问你 / 派新任务时再说。
```

**Why**：成员 idle 后自作主张重发方案或检查文件系统，会制造噪音、消耗 token、干扰 team-lead 调度节奏。

### 通读正文再动手

每次派活的 prompt 尾部必须附加以下约束：
```
收到派活后，先从头到尾通读 SendMessage 正文再开始动手或提问。
TaskList 的 description 字段只是短索引，不是需求规格；完整规格全在 SendMessage 正文里。
如果有歧义，必须指出是正文哪一段哪一点不懂。
```

**Why**：成员只读 Task description 就开始干活，容易漏掉 SendMessage 正文里的关键约束和细节。

## 其他协作规则

- **idle 通知**：不对成员的 idle_notification 发文本回复，静默等待
- **服务管理**：服务只由 team-lead 管理（启动/停止/重启），成员不越权
- **不并行过多任务**：一步步来，避免多线程混乱
- **测试策略**：不每次改动都跑全量测试，只针对当前改动做针对性测试
- **文档改动只派 PM**，不派给开发
- **.env 修改**和**破坏性操作**（DB migration、批量删除）只由 team-lead 执行
- **Persona 文件**：`docs/team-personas/` 下 5 个文件（pm.md / architect.md / backend-dev.md / frontend-dev.md / reviewer.md），创建成员时加载
