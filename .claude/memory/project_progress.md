---
name: 项目开发进展
description: 会话 20 后状态 — #69-#71 修复 + 高亮滚动 + 气泡避让 + 确认页代填 + 授权每次弹卡 + 密码 demo + ?reset
metadata:
  type: project
---

## 当前状态（2026-05-27 会话 20 后）

工作树干净。6 个 commit（447f889 → 9026fce）未推送 GitHub。

**会话 20 核心交付**：

### 1. #69/#70/#71 三个遗留 bug 修复
- #69：授权卡文案显示具体字段名（"小浙想帮您填写【身份证号】"）
- #70：草稿回填仅 ?restore=1 时触发，默认进页下拉框为空
- #71：pay_confirm_page 补挂 AgentFab

### 2. 高亮自动滚动 + 气泡避让（#72/#73）
- cmd_highlight 前加 Scrollable.ensureVisible(alignment:0.85)
- 气泡避让从单次 postFrame 改为 450ms 有界重试
- _pickBubbleY 改为 clearAbove vs clearBelow 净空决策

### 3. 确认页代填续写（#74）
- pay_confirm_page 注册 confirm_id_card/confirm_bank_card/btn_confirm_pay + applier
- prompt 第 3 步改 cmd_wait_user，新增第 4 步代填身份证+银行卡(@档案)
- pages.py 补确认页 PageSpec
- user_profile_service 新增 mock 银行卡

### 4. 每次敏感字段独立弹授权卡（#75）
- 移除 _task_sensitive_authorized 一次性放行（4 处删除）
- 全流程预期 3 张授权卡（主页身份证 + 确认页身份证 + 银行卡）

### 5. 支付密码页 demo 模式（#76）
- 去掉硬编码密码校验，任意 6 位输入通过

### 6. ?reset URL 参数（#77）
- 访问 /?reset 清空 xiaozhe_* localStorage + app_mode + IndexedDB 草稿

**待测/待修**：

1. **气泡避让方向** — 代码已改对（architect 确认），需 build 后 Ctrl+Shift+R 硬刷新验证
2. **?reset 功能** — 已实现未测试
3. **医保缴费全流程** — 确认页代填+授权卡+密码页，需完整跑一遍
4. **#68 医保缴费 prompt** 待完整测试
5. **#37 人脸验证真机测试**仍未进行
6. **#52/#53/#54 待真机回归**

**下次会话接续点**：
- **首要**：build + 硬刷新测气泡避让 + ?reset + 医保全流程
- 真机测试（#37 人脸验证 + #52/#53/#54 回归）
- N1 麦克风 Web Speech API → N2 云服务器部署 → 答辩准备

**Why:** 下次会话恢复时快速了解会话 20 做了什么、哪些问题待测。
**How to apply:** 新会话读此记忆，提醒用户先 build 测试气泡避让和 ?reset。
