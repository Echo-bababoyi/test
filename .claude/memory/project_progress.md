---
name: 项目开发进展
description: 会话 9 后状态 — 人脸验证 MediaPipe 实现 + AgentFab 全覆盖 + 标准版收紧，待真机测试
type: project
---

## 当前状态（2026-05-19 会话 9 后）

本地领先 origin/main 11 个 commit，未 push。

**会话 9 核心交付**：
- 人脸验证 MediaPipe FaceLandmarker 真检测（本地化部署，零 CDN 依赖）
- AgentFab 全 16 页覆盖 + 模式色自适配（标准蓝/长辈橙）+ AgentPanel 664 行死代码清理
- 标准版入口关闭（登录/搜索），重心收紧到长辈版
- 长辈版全页面橙色统一（10 文件 ~50 处）
- "我的"页面未登录态登录引导
- 登录页交互优化（checkbox 勾选 + 字号适老化 + 删装饰区）
- 人脸验证设计文档 docs/FACE_AUTH_DESIGN.md v1.0（710 行）

**待验证**：
- #37 人脸验证真机测试（需摄像头 + HTTPS/localhost）
- 验证码登录流程尚未跑通

**下一步路线图**：
真机测试人脸验证 → 验证码登录流程 → N1 麦克风 Web Speech API → N2 云部署 → N4 真机全场景测试 → N5 Prompt 调优 → N6 答辩准备

**端口约定**：前端 3080 / 后端 8080

**Why:** 下次会话恢复时快速了解项目在哪个阶段、下一步做什么。
**How to apply:** 新会话开始时读此记忆 + SESSION-LOG.md 最新条目即可继续推进。
