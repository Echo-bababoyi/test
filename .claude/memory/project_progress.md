---
name: 项目开发进展
description: 会话 27 后状态 — AgentDock 重构已 revert 回退到悬浮窗（AgentFab）稳定版，实测全链路通过
metadata:
  type: project
---

## 当前状态（2026-06-02 会话 27 后）

**AgentDock 重构已整体回退。** 用户决定不再走底部一体化聊天框方向，回到悬浮窗（AgentFab）最新稳定形态。

- 用 `git revert d39fa9c` 反做了 AgentDock 重构，新增 revert 提交 `5294446`（36 文件 +197/-2501）；历史完整保留，将来想找回 AgentDock 可 `git revert 5294446` 或 cherry-pick。
- 回退后 main HEAD = `5294446`（**本地领先 origin/main 一个提交，尚未推送**；远端 origin/main 仍停在 `d39fa9c`，AgentDock 还在远端）。
- 代码层面 = 悬浮窗稳定版（= `77c0c26` 内容）：`agent_dock.dart` 已删，`elder_bottom_nav.dart` 已恢复，`agent_fab.dart` 仍在。
- **实测全链路通过**（4 人团队，本会话 architect=Opus / PM·frontend·backend=Sonnet，会话末已关团队）：`flutter build web --release` 成功（`dart:web_audio` 仅 Wasm dry-run 告警，不阻断 JS build）；浏览器 6 项验证全过——首页加载 / 长辈版 AgentFab / WS 连通 / LLM 回复（DeepSeek 通）/ 跨页颜色（代码确认）/ 控制台 0 Error。
- **团队模型配置已调整**（见 [[团队启动配置]]）：仅 architect 用 Opus，PM/frontend/backend/reviewer 改 Sonnet。

**下次会话接续点**：用户原计划在悬浮窗稳定版上做下拉框（后又决定暂不做）。可选方向：QA 剩余 P1-A/P1-B/P2-E → 答辩 PPT → N2 云部署 → N4 真机。注意远端 origin/main 与本地不一致，推送前需确认。

**Why:** 下次会话恢复时立刻明白 AgentDock 已回退、当前是悬浮窗稳定版、本地未推送领先远端一个 revert 提交。
**How to apply:** 新会话读此记忆；勿再假设 AgentDock 是成品。

---

## 历史状态（2026-06-01 会话 26 — AgentDock，已 revert 回退）

> ⚠️ 以下 AgentDock 工作已于会话 27 整体 revert（提交 `5294446`），仅作历史保留。曾 commit `d39fa9c` 并推送远端。

**会话 26 核心交付（AgentDock，已回退）**：

### 1. 底部一体化聊天框 AgentDock（替换悬浮气泡 AgentFab）
- 弃用并删除旧分支 `agentdock-v2-wip`（用户对旧实现不满意，全新重做）
- 4 态状态机：S0 收起 / S1 半屏对话 / S2 引导窄条 / S3 卡片临时长高；挂 `Scaffold.bottomNavigationBar` 槽位，body 自动压缩重排
- 新建 `app/lib/widgets/agent_dock.dart`；18 页接入（主流程 full dock / 任务流 slim dock 砍首页·我的 / 刷脸·支付密码·设置页不挂）；删 `elder_bottom_nav.dart`；`agent_fab.dart` 保留（标准版仍用，本期只做长辈版）
- 引导态/卡片态做成纯窄条（去导航行）；收尾窄条原地渐隐收起（不放大，适老）
- 暖卡视觉「无边框·层次阴影」：暖米底 #FFF8F2 + 双层柔和阴影 + 顶部 grabber 抓手 + 头部栏（小浙身份）+ 私有 `_DockBubble`。**严格限于 agent_dock.dart**，共享组件 agent_bubble/auth_card 未动
- 用了官方 `frontend-design` skill 的设计原则（取其"精炼克制+质感"，舍其"大胆极繁"——适老约束）
- 文档：`docs/AGENT_DOCK_REDESIGN.md`（交互稿）+ `AGENT_DOCK_TECH_PLAN.md`（技术方案）+ `AGENT_DOCK_VISUAL.md`（视觉）+ `docs/screenshots_dock/`（8 张终图）

### 2. 刷脸回执闭环（前后端 interlock）
- 根因：登录刷脸引导在"活体检测开始"那步断头（prompt 无 cmd_wait_user + 刷脸成功无回执）
- Part A：`scene_login_face.txt` 第9步补 cmd_wait_user + 新增第10步登录成功收尾
- Part B：`face_auth_page._onAllSuccess` 发 `sendStepCompleted('face_auth_success')`，代理无缝接回引导
- 刷脸页保留方案甲（不挂 dock，全屏原生引导），靠 headless bindPage 让高亮/上报可用

### 3. 顺手修的 2 个潜在 bug
- 医保缴费 trust 过滤 bug（agent_core.py `_SCENE_FORCE_TOOLS` 给 yibao_jiaofei 加豁免）——自 #60 起潜在，guide 级跑医保必崩，安全靠每次授权卡不破
- `agent_out_of_scope` 无条件清引导进度（插话不打断引导）

### 4. QA 找到但本会话未修（待续）
对抗式探索测试（playwright 真链路）发现，**已记入待办，尚未修**：
- **P1-A** 拒绝授权卡后代理仍说"都填好啦"（yibao prompt 未处理敏感字段被拒分支）
- **P1-B** 养老金查询未登录态断流（让点不存在的"社保服务"）+ 鉴权脑裂（确认页有 profile 但"我的"页显未登录）
- **P2-E** ASR 录音失败残留"识别中…"占位气泡不消除
- **P2-F** 路由不同步 URL，F5 丢当前子页（既有问题，非 dock 引入）

### 5. 留真机（N4）验证
刷脸活体端到端（含 Part B 回执）、ASR 真麦克风、软键盘遮挡输入框（P1-4）—— headless 测不了。

**答辩准备（会话 25 遗留，未动）**：套 `答辩PPT逐页文字.md` 制作 .pptx / 补代理态截图 / 自制 3 张图 / Q&A 预演；论文测试数据 SUS 57.5、信任题 1.75 口径如实呈现。

**下次会话接续点**：收 QA 剩余 P1-A/P1-B/P2-E（拒绝授权文案 + 养老金未登录 + ASR 气泡）→ 答辩 PPT → N2 云部署 → N4 真机。

**Why:** 下次会话恢复时快速了解 AgentDock 已落地、还剩哪些 QA 待修。
**How to apply:** 新会话读此记忆；继续收 QA 待修项或转答辩 PPT。

---

## 历史状态（2026-06-01 会话 25 后）

进入**答辩准备阶段**。本次会话产出全部为文档，未改代码。

**会话 25 核心交付（答辩准备）**：

### 1. 开题报告 + 论文初稿 文本拆分
- 两份 Word 已转 `.docx`（论文 `.doc`→`.docx`，用户转的）
- `docs/word/extracted/开题报告/` — 8 文件 + `目录.md`（二级粒度，跳过外文翻译/外文原文）
- `docs/word/extracted/论文初稿/` — 57 文件 + `目录.md`（**三级粒度**，一级章=文件夹→二级节=子文件夹→三级=md；表格已还原为 Markdown 表；跳过摘要/目录/附录/作者简历）
- 提取脚本在 `/tmp/extract_kt.py` + `/tmp/extract_thesis.py`（非持久，按 body 顺序遍历 w:p + w:tbl）

### 2. 答辩 PPT 三件套（8–10 分钟，12 页正文）
- `docs/答辩PPT大纲.md` — 12 页大纲 + **逐页口播讲稿** + 时长分配表（~9.5 分钟）
- `docs/答辩PPT逐页文字.md` — **直接上屏的文字/表格**（已压短为短语；含 3 张表：问题→机会、普通助手vs小浙、L1/L2/L3 矩阵）
- `docs/答辩PPT配图清单.md` — 逐页配图状态与缺口

### 3. 关键发现（影响答辩口径）
- **论文 `.doc` 最新版已含真实可用性测试数据**（4 位 60+ 老人）：SUS 均分 **57.5**（低于基准 68）；信任问卷 Q3"相信不越权"均分 **1.75**（全卷最低）；"不主动"4.25、"止步安心"3.75 获认可
- 论文 §6.1.2 / §6.3 做了**诚实反思**：信任问题>易用性问题；原则内在矛盾——高风险环节（刷脸）代理因止步原则反而帮不上
- **答辩口径红线**：如实呈现，不夸大成全部成功；把"暴露的矛盾"当批判性深度亮点
- 学术定位：工业设计专业 → PPT 重心放设计贡献，技术架构仅 1 页

### 4. 配图缺口（用户暂不补）
- 代理"动作态"截图全缺（气泡对话/授权卡/去支付止步/脱敏/语音播报）—— 现有 `docs/screenshots_ppt/` 12 张为干净静态页
- 用户旅程图/系统架构图/止步点示意图 需自制（`docs/diagrams/` 已空）

**上一会话（24）**：ws_handler 选项/确认本地匹配跳过 LLM；成果展示 PPT 流水线（`gen_ppt.py` + 12 截图 + `成果展示PPT.pptx`，本次已删 pptx）。

**下次会话接续点**：
- 套用 `答辩PPT逐页文字.md` 制作 .pptx（或用 `gen_ppt.py`）
- 可选：补代理态截图（需跑原型）/ 自制 3 张图 / Q&A 预演
- 技术侧仍待：前后端联调 → #37 人脸真机 → N2 云部署 → N4 真机 → N5 Prompt 调优

**Why:** 下次会话恢复时快速了解答辩准备进度与口径。
**How to apply:** 新会话读此记忆，继续做 PPT / Q&A，注意测试数据如实呈现口径。
