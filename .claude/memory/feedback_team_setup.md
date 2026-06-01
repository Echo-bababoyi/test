---
name: 团队启动配置
description: CC Team 创建方式 / 默认 4 人 全员 Opus / 成员结构 / 生命周期 — 用户说"启动团队"时加载
type: feedback
---

## 触发条件

用户说"创建团队"、"恢复团队"、"启动团队"等指令时加载本文件。非团队模式下忽略。

## 创建方式

TeamCreate → Agent(team_name=...) 一次性创建 4 个成员（PM / architect / frontend / backend）。不是在主对话中角色扮演。

## 成员模型

- **全员 Opus**：team-lead / architect / PM / frontend / backend / reviewer 统一使用 Opus

**Why**：用户要求全员 Opus，质量优先。
**创建时**：所有成员 `Agent(model="opus")`。

## 默认 4 人结构

| 角色 | 职责 | 绝不做 |
|------|------|--------|
| PM | 需求分析、方案设计、文档维护、UX 分析 | 不改代码 |
| architect | 架构方案、技术方向、代码 review | 不直接改代码 |
| frontend | 前端代码开发 | 不写文档、不 git commit |
| backend | 后端代码开发 | 不写前端、不 git commit |

reviewer 按需追加，日常不启动。不在时 review 由 architect 承担。

## Persona 文件

`docs/team-personas/` 下 5 个文件（pm.md / architect.md / backend-dev.md / frontend-dev.md / reviewer.md），创建成员时在 prompt 中指引其读取对应 persona。

## 生命周期

- **创建**：TeamCreate → 建 4 成员 → team-lead 进 leader 模式 → SendMessage 派活
- **关闭**：向所有成员发 shutdown_request
- **重启**：关闭后重新 TeamCreate
