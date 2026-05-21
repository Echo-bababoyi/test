---
name: 项目开发进展
description: 会话 14 后状态 — 三级权限审查修正 + WS 连接修复 + 性能优化 + 登录分支选择
type: project
---

## 当前状态（2026-05-21 会话 14 后）

本地领先 origin/main 42 个 commit，未 push。

**会话 14 核心交付**：

1. `fdcf19d` fix: 三级权限审查 3 处修正 — read_sms 注释 + prompt 兜底 + 弹卡 flag 提前
2. `64bd793` docs: DEPLOY.md 全面修订 — 端口/环境变量/路由表/资源说明对齐实际（8 项）
3. `f5ad852` fix: WS 连接 3 处修复 — 动态 host 推导 + 订阅时序 + 单例残留
4. `073bb38` docs: DEPLOY.md 补充跨机访问说明
5. `8dcbb4b` fix: load_dotenv 路径改为相对于 main.py，修复 DEEPSEEK_API_KEY 读不到
6. `e8f0b7f` perf: 响应延迟优化 11s→1s — 关遥测 + 参数调优 + OOS 合并 + 去 TTS 阻塞
7. `97e94c2` feat: AgentFab 聊天记录跨开关/跨页面持久化（ChatHistory 单例）
8. `24e4fce` fix: ModeNotifier 持久化到 localStorage，F5 刷新后模式不丢失
9. `a9332ba` feat: 登录分支选择 — 模糊登录意图弹两按钮让用户选

**前端改为 release build + 静态服务**（python3 -m http.server），不再用 flutter run debug 模式，避免白屏。

**测试进展**（P0 清单）：
- P0-1 启动+进入长辈版 ✅
- P0-2 登录后首次弹卡 ✅
- P0-3 AgentFab 基本对话 ✅
- P0-4 引导级登录场景 — 发现面板自动关闭 + 高亮不生效（未修）
- P0-5 半委托级医保缴费 — 未测
- P0-6 人脸验证 — 未测

**已发现未修的问题**：
- AgentFab 面板自动关闭（代理输出消息后面板自动收起，用户来不及看完）
- cmd_highlight 高亮不生效
- DeepSeek 503 过载时错误提示不够精确（通用"处理失败"而非"服务繁忙"）
- wait_for 超时 30s 对适老化太长（建议降到 15s）
- agent_core.py JSONDecode 二次解析未在 try/except 内（潜在隐患）
- 需要备选 LLM 做 fallback（DeepSeek 过载时切换）

**下次会话接续点**：
- **首要**：修面板自动关闭 + 高亮不生效，继续 P0-4 ~ P0-6 测试
- 备选 LLM fallback 方案（阿里通义/智谱 GLM/Moonshot）
- DeepSeek 503 错误区分 + 超时降到 15s
- JSONDecode 加固
- 语音合成/识别方案待定（用户倾向讯飞）
- N2 云服务器部署
- N6 答辩准备

**Why:** 下次会话恢复时快速了解会话 14 做了什么、哪些问题待修。
**How to apply:** 新会话读此记忆，直接接续未修问题和未完成测试。
