---
name: feedback-git-commit-team-lead-only
description: 团队规则 — git commit 只由 team-lead 执行，其他成员（architect/PM/frontend/backend）不得建议或指示 commit
metadata:
  type: feedback
---

review / 方案 / 实施完成后，**不要**在报告或消息中写"可以让 X 提交 commit"、"建议 commit"、"准备 commit" 等措辞。

**Why**：team-lead 2026-05-20 在 session-11b 明确纠正过一次。git commit 是 team-lead 的专属职责，其他角色越权建议 commit 会越界团队分工，造成混乱。

**How to apply**：
- architect review 通过后，只报告"通过 / 不通过"+ 发现的问题，不提及 commit
- PM 方案、architect 方案、frontend 实施完成时同理
- 如果想表达"工作已就绪可纳入版本"，用"可合入演示"、"可纳入主分支"等非 git 动作的表述，但**最好直接省略**，把判断权交给 team-lead
- 仅当 team-lead 主动询问 commit 时机或要求出 commit message 草稿，才参与 commit 相关讨论
