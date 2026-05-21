---
name: 项目开发进展
description: 会话 13 后状态 — 三级权限系统 v0.6 全部落地（6 commit）
type: project
---

## 当前状态（2026-05-20 会话 13 后）

本地领先 origin/main 34 个 commit，未 push。

**会话 13 核心交付**：三级权限系统 v0.6 全量开发完成（PM 需求 R1-R26 全部落地），6 个 commit：

1. `b88ee3e` feat: 后端基础层 — say 工具 + trust_level 模型 + 场景×级别工具集
   - 新建 backend/tools/say.py（cmd_say 纯语音提示工具）
   - models.py: AgentWakePayload 加 trust_level 字段（guide/semi/full，默认 guide）
   - agent_core.py: SCENE_TOOLS 全场景加 cmd_say + login 场景收紧为仅 {highlight, say}
   - 新增 _LEVEL_TOOLS + get_scene_tools() 实现场景集 ∩ 级别集三道 AND 机制

2. `383d237` feat: 后端核心流程 — execute_task 权限分级 + 密码硬拒
   - 密码白名单 _PASSWORD_FIELDS + _is_password_field 模糊匹配
   - execute_task 整段重写：密码硬拒 → full+已授权快路径 → 弹 permission_request → 拒绝跳过不取消
   - ws_handler 透传 trust_level 给 AgentCore
   - 修复 agno API add_history_to_context → add_history_to_messages

3. `e54b81e` feat: 后端 prompt 重写 — 登录场景纯引导 + 医保缴费去 mock
   - login_face/login_verify prompt 改为 cmd_highlight + cmd_say 纯引导
   - yibao_jiaofei 4 处硬编码 mock 值替换为用户意图占位符

4. `d975c01` feat: 前端基础层 — 设置服务 + cmd_say + 权限卡组件 + fab 传参
   - agent_settings_service 新增 trustLevel/firstChoiceShown 读写（localStorage）
   - agent_command_executor 加 cmd_say 分支
   - 新建 trust_level_cards.dart 三卡组件（适老化字号 + 橙色选中态 + readonly 灰显）
   - agent_fab _initSession 传 effective_trust_level（未登录强制 guide）

5. `9d09441` feat: 前端页面集成 — 首次弹卡 + 设置页三卡 + 未登录灰显
   - elder_home 登录后首次进入弹 BottomSheet 选择信任等级
   - agent_settings_page 改 ConsumerStatefulWidget，新增三卡 section
   - 升级弹 SystemDialog 确认 / 降级直接生效
   - 未登录黄色 banner + 三卡 readonly 灰显
   - SectionHeader 13→15sp / HelpCard desc 14→16sp

6. `66b6cb3` docs: AGENT_SPEC.md v1.0 → v1.1 — 三级信任模型全面对齐

**联调验收**：后端 uvicorn 启动 OK + 7 条工具集验证全绿；前端 flutter analyze 无 error + build web 编译成功。

**下次会话接续点**：
- **首要**：浏览器手动走核心用户旅程（登录→弹卡选级→唤醒小浙→场景执行），验证 UI 效果和 WS 交互
- 验证码登录流程（需前端 login 页面完善）
- N1 麦克风 Web Speech API（ASR 输入）
- N2 云服务器部署（TLS 反代）
- N4 真机测试
- N5 Prompt 调优（业务知识补充）
- N6 答辩准备
- 代理文本对话基本可用（DeepSeek API key 已配）
- 语音输入（ASR）待用户申请讯飞 API 后再做

**Why:** 下次会话恢复时快速了解三级权限已落地、下一步做什么。
**How to apply:** 新会话开始时读此记忆，三级权限无需再开发，重点转向端到端手动验证和后续任务。
