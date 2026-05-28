---
name: 项目开发进展
description: 会话 23 后状态 — 讯飞 ASR 全链路接入 + PPT 制作指引
metadata:
  type: project
---

## 当前状态（2026-05-28 会话 23 后）

工作树干净，已 push 到 GitHub（`dd32839`）。

**会话 23 核心交付**：

### 1. 讯飞 ASR 语音识别全链路接入（commit `80ba845`）
- 前端：新建 AudioCapture（Web Audio API 16k mono PCM）替换 MediaRecorder
- 前端：MicButton 改 Listener 零延迟触发 + 30s 超时 + onError 回调 + size 参数
- 前端：AgentFab 输入栏插入紧凑版麦克风按钮（size=36）
- 前端：agent_session 新增 sendAudio()（切帧 base64 发后端）+ asr_result 占位气泡清除
- 后端：ASR/TTS 凭证隔离（XUNFEI_ASR_* 优先，回退共用 XUNFEI_*）
- 后端：asr_adapter wpgs 合并 bug 修复（sentences dict 按 sn/pgs/rg 正确合并）
- 后端：business 加 vad_eos=3000 + ptt=1 + nunum=1；空 result 防护
- 冒烟测试通过：TTS 生成 PCM → ASR 识别，"帮我缴纳医保"→"帮我缴纳医保。"

### 2. 成果展示 PPT 制作指引（commit `dd32839`）
- docs/PPT_CONTENT.md：10 页逐页内容（标题+要点+图片需求+布局建议）
- 8 张截图清单 + 2 张自制图表说明
- 纯成果展示版（前期背景/方法已在之前汇报过）

### 3. AgentDock V2（未变，仍保存在分支）
- 分支 `agentdock-v2-wip`，guide 态缺输入框，待后续继续

**下次会话接续点**：
- 前后端联调测试（浏览器实际按麦克风说话 → 讯飞 ASR → 代理响应）
- #37 人脸验证真机测试
- N2 云服务器部署 → N4 真机测试 → N5 Prompt 调优 → N6 答辩准备
- PPT 截图需要跑起原型后按路由路径截取

**Why:** 下次会话恢复时快速了解会话 23 做了什么。
**How to apply:** 新会话读此记忆，继续联调测试 → 真机测试 → 部署。
