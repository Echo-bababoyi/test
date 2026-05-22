---
name: 项目开发进展
description: 会话 17 后状态 — 多步引导阶段 1 完成 + 聊天框重构 + 高亮跟随缩放 + 活体检测 TTS，10 个 commit 已提交未 push
metadata:
  type: project
---

## 当前状态（2026-05-22 会话 17 后）

工作树干净，10 个新 commit 已提交（未 push）。

**会话 17 核心交付**：

### 1. 高亮框跟随窗口缩放修复（commit 5355d01）
- 坐标计算从 `localToGlobal + size` 改为 `getTransformTo(null) + transformRect`
- 根治浏览器窗口缩放后高亮框位置偏移问题

### 2. 多步引导机制阶段 1（commit b614a9f + 0fd5ed5 + 1c11fdd）
- 后端新增 `cmd_wait_user` + 前端 `step_completed` 消息
- 代理引导从"一次性执行完"改为逐步循环
- login_face / login_verify 两个场景 prompt 多步改造完成
- step_completed 300ms 防抖，合并 clicked_highlight + page_changed 两类信号
- input_phone 字段注册 + 条款浮层/摄像头弹窗 key 注册

### 3. 聊天框重构（commit f0f94c0 + d03861d + 17daae7 + 649435f）
- 支持上下拖动（补全 _bubbleY）
- 智能避让高亮区域（PhoneFrame-local 坐标，自动上下移位）
- AnimatedPositioned 平滑移动 + 落定脉冲形变
- 跨页位置保留修复

### 4. 弹窗蒙版修复（commit 6ca173b）
- 蒙版不透明度降至 15%，聊天框不被遮挡

### 5. 活体检测 TTS 提示（commit 3178870）
- 眨眼（S5）/ 转头（S7）阶段加入 TTS 语音引导

**未解决的已知问题**：

1. **多步引导阶段 2 未完成** — 仅 login_face/login_verify 改造，医保缴费/养老金查询等场景 prompt 尚未多步改造
2. **LLM response.content 仍不空** — DeepSeek 仍输出思考过程（会话 15 遗留，ISSUES #52）
3. **pop 返回 executor 失效** — 用户按浏览器返回时 unbindPage 清掉 executor（会话 15 遗留，ISSUES #53）
4. **草稿重复追加** — _checkPageDraft 反复执行重复插入 draft_prompt 卡（会话 15 遗留，ISSUES #54）
5. **人脸验证真机测试未进行** — ISSUES #37 🧪（会话 9 遗留）
6. **3080 端口浏览器缓存白屏** — 开发阶段绕过：改用 3081（ISSUES #51）

**下次会话接续点**：
- **首要**：测试 login 多步引导流程端到端，验证 cmd_wait_user + step_completed 循环是否稳定
- 其余场景 prompt 多步改造（医保缴费 / 养老金查询）
- 修复 LLM response.content（#52）/ pop 返回 executor 失效（#53）
- 真机测试（#37）

**Why:** 下次会话恢复时快速了解会话 17 做了什么、哪些问题待修。
**How to apply:** 新会话读此记忆，直接接续未修问题。
