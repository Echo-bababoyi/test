---
name: 踩坑教训
description: 所有血的教训按时间倒序 — 做决策前翻一下，避免重犯
type: feedback
---

## 2026-05-20 · 跳过用户确认 + 跳过 architect review diff

team-lead 收到 PM 决策和 architect 方案后，没有汇报给用户确认就直接派 frontend 实施；frontend 改完后也没派 architect review 实际 diff 就直接 commit 了。违反功能增强 6 步中的第 3 步（汇报+用户确认）和第 5 步（architect review diff）。

**根因**：任务简单（1 行改动 + 几行插入），team-lead 觉得"太简单不用走流程"就跳过了。
**规则**：无论改动大小，严格走 6 步流程。PM 方案 → architect 方案 → **汇报用户确认** → 派开发 → **architect review diff** → team-lead commit。简单不是跳步的理由。

## 2026-05-20 · team-lead 擅自决定团队成员启动/关闭

team-lead 自行决定"这次只需要 3 人不启动 backend"，任务完成后也自行 shutdown 全部成员。用户指出：启动和关闭团队/成员的决定权在用户，team-lead 无权自行决定。

**根因**：team-lead 把自己当项目经理而非执行者，越权做了资源分配决策。
**规则**：团队成员的启动和关闭只由用户决定。team-lead 按用户指令创建/关闭成员，不自行判断"需不需要某个角色"或"任务完成了该关人了"。

## 2026-05-19 · 成员越权 git commit

frontend 多次自行 git commit（6 次），architect 也在 review 后指示 frontend "直接 commit"。

**根因**：team-lead 在消息中写了"提交完告诉我 commit hash"，等于指示成员提交。
**规则**：git commit 只由 team-lead 执行。派活消息中永远写"改完告诉我，不要 git commit"。architect review 后报告给 team-lead，不指示成员提交。

## 2026-05-19 · 适老化批量改动被整体回退

PM 审查出 ~90 处字号不合规 → 产出改动清单 → frontend 一次性改了 14 个文件 110 处 → 用户看效果后不满意 → 整体 revert。

**根因**：没有让用户先看到预期效果就直接改代码。批量视觉改动效果不可预测。
**规则**：视觉/样式类批量改动，先出 mockup 或逐页改让用户确认，不要一次性全改。

## 2026-05-19 · 粗略方案被驳回

PM 第一版人脸验证方案只有粗线条流程概述，用户批评"一点都不详细"。

**根因**：没有站在用户视角逐帧设计，只给了技术流程摘要。
**规则**：大功能必须出详细设计文档（画面布局 + 每个字的文案 + 时长 + 动画 + 转场），写到 docs/ 下，用户过目确认后才开始编码。

## 2026-05-19 · Google CDN 国内不通

MediaPipe 资源原计划从 CDN 加载（googleapis.com + jsdelivr.net），国内基本被墙。

**规则**：任何外部依赖先检查国内可访问性。不可访问就下载到本地随项目部署（app/web/ 或 public/）。

## 2026-05-09 · team-lead 越权写代码

三个成员完成研究后，team-lead 自己把 800 行代码改动全做了，绕过 frontend。用户批评"所有工作都是你自己完成的"。

**规则**：team-lead 绝不亲自写代码。方案出来后通过 SendMessage 派给对应成员执行。流程本身就是产出的一部分。
