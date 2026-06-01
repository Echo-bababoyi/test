---
name: 二文档机制
description: 项目文档体系 — ISSUES + CLAUDE.md 二文档分工 + 会话恢复（项目记忆 + git log）
type: feedback
---

## 二文档机制

项目根目录维护 2 个核心文档，各有明确分工，不重叠不替代：

| 文档 | 记录单位 | 核心问题 | 位置 |
|------|---------|---------|------|
| ISSUES.md | 问题/需求 | 有哪些问题？解决了没？ | 项目根 |
| CLAUDE.md | 项目整体 | 项目当前是什么状态？ | 项目根 |

历史精简记录：
- COMMITS.md 已于会话 18（2026-05-25）删除——git log 才是 commit 记录的权威来源。
- SESSION-LOG.md 已于会话 25（2026-06-01）删除——逐会话历史冗余于项目记忆 `project_progress.md` + git log，临近答辩收尾后维护价值下降。

**Why**：ISSUES 跟踪长期问题，CLAUDE.md 给新会话提供起点；会话上下文恢复改由 `.claude/memory/project_progress.md`（当前状态）+ `git log` 承担，不再单独维护会话流水。

**How to apply**：
- 问题状态变化时更新 ISSUES.md
- 架构/配置/阶段变化时更新 CLAUDE.md
- 每次会话结束更新 `project_progress.md` 记忆（当前状态 + 下次接续点）
- 恢复上下文时：读 `project_progress.md` 记忆 + `git log --oneline -5`

## ISSUES.md 状态标记（5 种）

| 标记 | 含义 |
|------|------|
| ✅ | 已完成 |
| 🧪 | 已实现待测（代码改了，等用户确认） |
| 🔧 | 未实现 |
| 🐛 | Bug |
| ❓ | 待确认 |

提交后只能标 🧪，**用户真人确认后才标 ✅**。全项目只维护一个 ISSUES 文件。
