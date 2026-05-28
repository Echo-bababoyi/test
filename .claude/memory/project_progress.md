---
name: 项目开发进展
description: 会话 21 后状态 — 气泡避让加固 + #78 localStorage 清理 + #79 医保缴费简化（仅本人）
metadata:
  type: project
---

## 当前状态（2026-05-28 会话 21 后）

工作树有未提交改动（7 个文件）。

**会话 21 核心交付**：

### 1. #73 气泡避让追加修复
- key==null 时不再复位到底部（防遮挡确认按钮）
- `_pickBubbleY` 末尾加 overlap 兜底（仍重叠则强制顶部）
- `_scheduleAvoid` deadline 450→800ms + 跨页 entry==null 推顶部

### 2. #78 普通刷新清除会话级 localStorage
- main.dart 启动时调用 `_clearSessionScopedKeys()` 清除 trust_level / first_choice_shown / profile_phone / profile_idcard
- 保留跨刷新偏好：app_mode / voice_enabled / speech_rate

### 3. #79 医保缴费简化（仅本人缴费）
- prompt 新增第 0 步"给谁缴费？"前置问询，他人→回复功能未开发
- yibao_jiaofei_page 删除缴费对象下拉 + 被缴费人信息区块（-136 行）
- pay_confirm_page 删除被缴费人信息卡，固定本人态
- pages.py 删除 daili 相关 ElementSpec

**待测/待修**：

1. **气泡避让** — 已修但需 build 后验证（确认页按钮不再被遮挡）
2. **医保缴费全流程** — 简化后需重新测试：代理问"给谁缴费"→本人→代填→确认→密码→结果
3. **#37 人脸验证真机测试**仍未进行
4. **#52/#53/#54 待真机回归**

**下次会话接续点**：
- 用户已确认医保缴费流程没问题
- 需要 git commit 本次改动
- 真机测试（#37 人脸验证 + #52/#53/#54 回归）
- N1 麦克风 Web Speech API → N2 云服务器部署 → 答辩准备

**Why:** 下次会话恢复时快速了解会话 21 做了什么。
**How to apply:** 新会话读此记忆，提醒用户 commit + 继续真机测试。
