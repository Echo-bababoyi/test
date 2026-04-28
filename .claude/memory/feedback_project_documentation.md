---
name: 四文档机制
description: 项目文档体系 — ISSUES + COMMITS + SESSION-LOG + CLAUDE.md 四文档分工 + 会话恢复流程
type: feedback
---

## 四文档机制

项目根目录维护 4 个核心文档，各有明确分工，不重叠不替代：

| 文档 | 记录单位 | 核心问题 | 位置 |
|------|---------|---------|------|
| ISSUES.md | 问题/需求 | 有哪些问题？解决了没？ | 项目根 |
| COMMITS.md | git commit | 每次提交改了什么？ | 项目根 |
| SESSION-LOG.md | 对话会话 | 这次对话做了什么？ | 项目根 |
| CLAUDE.md | 项目整体 | 项目当前是什么状态？ | 项目根 |

**Why**：image-search 项目实践证明，四文档各管一面，上下文恢复效率远高于"什么都往一个文档塞"。ISSUES 跟踪长期问题，COMMITS 永久归档改动，SESSION-LOG 恢复会话上下文，CLAUDE.md 给新会话提供起点。

**How to apply**：
- 每次 commit 后更新 COMMITS.md（hash + 标题 + 改动要点）
- 会话结束时更新 SESSION-LOG.md（工作/决策/踩坑/状态）
- 问题状态变化时更新 ISSUES.md
- 架构/配置变化时更新 CLAUDE.md
- 恢复上下文时：读 SESSION-LOG 最近一条 + `git log --oneline -5`

## ISSUES.md 状态标记（5 种）

| 标记 | 含义 |
|------|------|
| ✅ | 已完成 |
| 🧪 | 已实现待测（代码改了，等用户确认） |
| 🔧 | 未实现 |
| 🐛 | Bug |
| ❓ | 待确认 |

提交后只能标 🧪，**用户真人确认后才标 ✅**。全项目只维护一个 ISSUES 文件。

## SESSION-LOG 格式

**按时间倒序排列，最新会话在最前面**，方便快速查看最新状态。

```markdown
## YYYY-MM-DD（会话 N）

**主要工作**：
- ...

**关键决策**：
- ...

**踩坑/教训**：
- ...

**当前状态**：
- ...
```

## COMMITS.md 格式

按时间倒序，每条：
```markdown
### <hash-short> <标题>
- 改动要点 1
- 改动要点 2
```
