---
name: 团队启动配置
description: CC Team 创建方式 / 默认 4 人 Sonnet / 成员结构 / 生命周期 — 用户说"启动团队"时加载
type: feedback
---

## 触发条件

用户说"创建团队"、"恢复团队"、"启动团队"等指令时加载本文件。非团队模式下忽略。

## 创建方式

TeamCreate → Agent(team_name=...) 一次性创建 4 个成员（PM / architect / frontend / backend）。不是在主对话中角色扮演。

## 成员模型

- **team-lead + architect**：Opus 4.6（1M context）— 需要复杂推理和架构决策
- **PM / frontend / backend / reviewer**：Sonnet — 速度快、成本低，足够胜任编码/文档任务

**Why**：architect 需要做技术方案设计、代码 review、架构评估，复杂度接近 team-lead，用 Opus 保证质量。其余成员执行具体任务用 Sonnet 即可。
**创建时**：`Agent(model="opus")` 给 architect，其余不指定或指定 `model="sonnet"`。

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
