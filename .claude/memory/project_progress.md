---
name: 项目开发进展
description: 会话 19 后状态 — trust 传播 + 信任卡修复 + cmd_ask_user + 用户档案预填 + 医保 prompt 重写，3 个新 bug 待修
metadata:
  type: project
---

## 当前状态（2026-05-26 会话 19 后）

工作树有 1 个未提交改动（prompt 修正）。commit 4d727ff 已推送 GitHub。

**会话 19 核心交付**：

### 1. trust 传播机制（#64）
- 新增 trust_changed 消息类型（models + ws_handler + agent_core）
- 前端 3 处发送：信任卡选择 / 设置页 / ensureSession 复用分支
- env block 按 get_scene_tools 真实工具集过滤，guide 禁调 cmd_navigate

### 2. 信任选择卡修复（#65）
- 登录后逐帧轮询 isCurrent（240 帧上限）解决淡出动画竞态
- firstChoiceShown 改为成功选择后才持久化 + _trustSheetShowing 防重入

### 3. cmd_ask_user 场景内问答（#66）
- 新增 HITL 工具 ask_user.py（stop_after_tool_call）
- 执行器 cmd_ask_user 分支：发 agent_choice_request / agent_reply → await _answer_event 180s
- ws_handler process_asr_text 开头 is_awaiting_answer 路由回执行器
- 60s 超时改为只裹 LLM arun，人工等待不被误杀

### 4. 用户档案预填（#67）
- UserProfileService（localStorage）存手机号 + 身份证号
- 代填用 @档案 占位符，前端 _onFillField 替换真实值
- 真实身份证不经 LLM

### 5. 医保缴费 prompt 多轮重写（#68）
- 选择卡逐项问→填交错结构 + 铁律
- 删字段取值规范"默认值"矛盾措辞
- cmd_ask_user 收集缴费对象/险种/年度/档次

**未解决/待修**：

1. **#69 授权卡文案不明确** — 只说"敏感信息"未说具体字段名 🔧
2. **#70 医保缴费页下拉框有预设值** — 应为空 🔧
3. **#71 点"去支付"跳转后聊天面板消失** 🐛
4. **#68 医保缴费 prompt 待完整测试** 🧪
5. **#37 人脸验证真机测试**仍未进行
6. **#52/#53/#54 待真机回归**
7. **养老金查询 #62 已跑通**（trust=full + cmd_navigate 正常）
8. **验证码登录 #60 已确认完成** ✅

**下次会话接续点**：
- **首要**：修 #69/#70/#71 三个新 bug
- 完整测试医保缴费流程（#68）
- 真机测试（#37 人脸验证 + #52/#53/#54 回归）
- N1 麦克风 Web Speech API → N2 云服务器部署 → 答辩准备

**Why:** 下次会话恢复时快速了解会话 19 做了什么、哪些问题待修。
**How to apply:** 新会话读此记忆，直接接续未修问题。
