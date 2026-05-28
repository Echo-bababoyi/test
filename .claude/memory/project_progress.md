---
name: 项目开发进展
description: 会话 22 后状态 — 讯飞 TTS 全链路启用 + AgentDock V2 保存在分支（已回退）
metadata:
  type: project
---

## 当前状态（2026-05-28 会话 22 后）

工作树干净，已 push 到 GitHub（`a2f064b`）。

**会话 22 核心交付**：

### 1. 讯飞 TTS 语音合成全链路启用
- .env 配置讯飞 APPID/APIKey/APISecret
- ws_handler.send 统一拦截注入 TTS（7 类消息自动生成 mp3）
- 音色 x4_yezi，语速 40（慢 15%，适老化）
- 前端 6 处消息类型新增 AudioPlayer.playBase64 播放
- cmd_say 优先讯飞 mp3，fallback Web Speech
- audio_player 队列式播放（防打断）
- 删 _BubbleWindow.dispose 内 AudioPlayer.stop()（防跨页打断）

### 2. AgentDock V2 底部 Shell 布局（已回退，分支保存）
- 用户反馈 V1 AgentDock 交互"花里胡哨"，要求改为底部导航栏+聊天框一体化
- 完成 AgentBottomShell（导航栏双态 + AnimatedSize + 五态 Panel）
- 用户测试后因时间紧迫回退到 AgentFab 版本（`6693cf7`）
- V2 进度保存在分支 `agentdock-v2-wip`，待后续继续
- 已知问题：guide 态缺少输入框/按钮

**下次会话接续点**：
- 讯飞 ASR 语音识别接入（用户已提供讯飞 API 凭据）
- #37 人脸验证真机测试
- N2 云服务器部署 → N5 Prompt 调优 → N6 答辩准备
- AgentDock V2 如需继续：`git checkout agentdock-v2-wip`

**Why:** 下次会话恢复时快速了解会话 22 做了什么。
**How to apply:** 新会话读此记忆，继续讯飞 ASR → 真机测试 → 部署。
