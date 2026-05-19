---
name: 团队运转规则
description: team-lead 铁律 / 派活纪律 / 成员约束 / Bug 修复 7 步 / 功能增强 6 步 — 团队运行中持续参照
type: feedback
---

## team-lead 铁律

1. **绝不亲自写代码/读代码/排查 bug/写文档** — 所有技术工作委派成员
2. **git commit 只由 team-lead 执行** — 成员改完只说"改完了"，不碰 git add/commit
3. **收到问题先记录不派活** — 用户测试阶段等用户说"修吧"再分配
4. **发消息后确认收到** — 成员没回复不假设已收到
5. **按职责分配** — 对照 [[feedback_team_setup]] 职责表
6. **不跳过评审流程** — 分析→方案→用户确认→实施→review→team-lead 提交

## 派活纪律

- **只用 SendMessage 派活**，不调 TaskUpdate(owner=X)
- **消息必须自包含**：不引用成员看不到的主对话内容，所有素材内联
- **Task 一事一建**：当前只有 1 个 in_progress + 最多 1 个 pending

## 成员行为约束

每次派活尾部附加：
- 完成后 idle 静默等待，不主动重发/自查/改 Task
- 先通读 SendMessage 正文再动手
- 不执行 git add / git commit（即使 architect 建议了 commit message）

## Bug 修复 7 步

1. team-lead 读 TODO 推荐优先项
2. 派 frontend/backend 调查根因 + 方案
3. 派 architect review 方案
4. team-lead 汇报，用户确认
5. 派成员执行 + 编译验证
6. 派 architect review diff
7. **team-lead** git commit，TODO 标 🧪

## 功能增强 6 步

1. PM 需求分析 → 需求文档
2. architect 技术方案 → 改动清单
3. team-lead 汇报，用户确认
4. 派成员执行
5. architect review diff
6. **team-lead** git commit

## 代码修复/改动必经 architect

**任何代码改动都必须先派 architect 审查代码 + 出方案，再派开发实施。team-lead 不得跳过 architect 直接派 frontend/backend 改代码。**

**Why**：用户明确要求所有代码改动先经 architect 看代码、找问题、出精确方案（文件:行号），再给开发照做。team-lead 自己写指令给开发等于越权替代 architect。

**How to apply**：收到用户反馈的 bug/改进 → 派 architect 审查 → architect 出方案 → 汇报用户确认 → 派开发实施。

## 其他

- idle 通知不回复，静默等待
- 服务启停只由 team-lead 管理
- 文档改动只派 PM
- .env 和破坏性操作只由 team-lead 执行
