# 会话日志

每次对话会话结束时记录。用于下次会话快速恢复上下文。**按时间倒序排列，最新会话在最前面。**

---

## 2026-05-26（会话 19）

**主要工作**：

1. **trust 传播机制**（#64）：新增 `trust_changed` 消息类型，前端 3 处发送（信任卡/设置页/面板重开），后端 `set_trust_level` + env block 按真实工具集过滤。解决登录后 trust 停在 guide 导致 cmd_navigate not found + API 400 的问题。
2. **信任选择卡修复**（#65）：登录后逐帧轮询 isCurrent 弹卡（解决淡出动画竞态），firstChoiceShown 改为成功选择后才持久化（解决卡死）。
3. **cmd_ask_user 场景内问答**（#66）：新增 HITL 工具，执行器内提问等回答，ws_handler 判 is_awaiting_answer 路由回执行器（不再误走意图分类）。60s 超时改为只裹 LLM arun。
4. **用户档案预填**（#67）：UserProfileService（localStorage）+ @档案占位符，身份证免打字、不经 LLM。
5. **医保缴费 prompt 多轮重写**（#68）：选择卡逐项问→填交错 + 删默认值矛盾 + 铁律。
6. **#60 验证码登录标为已完成**

**团队参与**：PM / architect(Opus) / frontend / backend / lead 全员

**关键决策**：
- **trust 传播用新消息类型**而非重发 agent_wake：更精确、不重建 session
- **cmd_ask_user 回答路由统一在 process_asr_text 开头**：文字/语音/选择卡答案一处搞定
- **@档案占位符**：真实身份证不经 LLM，前端替换，fail-safe
- **prompt "问→填"交错 + 铁律**：防 LLM 跳过询问直接用默认值

**遗留问题（明天修）**：
- **#69 授权卡文案不明确**：只说"敏感信息"未说具体字段名 🔧
- **#70 医保缴费页下拉框有预设值**：应为空 🔧
- **#71 点"去支付"跳转后聊天面板消失** 🐛
- **#68 医保缴费 prompt 待完整测试** 🧪
- **#37 人脸验证真机测试**仍未进行
- **#52/#53/#54 待真机回归**

**当前状态**：
- 2 个 commit（4d727ff + 待提交 prompt 修正），工作树有 1 个未提交改动
- 下次会话恢复点：① 修 #69/#70/#71 ② 完整测试医保缴费 ③ 真机测试

---

## 2026-05-25（会话 18）

**主要工作**：

1. **文档治理**：删除 COMMITS.md（git log 为权威来源，手抄镜像维护成本高且容易断档）；补登 ISSUES #55-#59（Sessions 13/14 遗漏条目）；SESSION-LOG 补齐会话 13/14/15；CLAUDE.md 日期更新；确立三文档机制（ISSUES / SESSION-LOG / CLAUDE.md）
2. **验证码登录 L2 破例代填**：前端新增 `sms_code_generated` WS 消息回传随机验证码；后端场景豁免机制（`_SCENE_FORCE_TOOLS`）让 login_verify 在登录前获得 L2 工具权限；授权卡 `permission_request: read_sms` 一事一授；prompt 改为 12 步多步引导，含拒绝回退路径
3. **医保缴费全委托代填**：新增 `applier` 机制（`AgentElementRegistry` 值应用器回调），解决 `DropdownButtonFormField` 无 `TextEditingController` 时代填下拉框的问题；医保缴费 prompt 3 步重写；支持家属路径
4. **养老金查询全委托改造**：prompt 2 步重写（navigate + 高亮查询按钮）；去掉 `cmd_press_button`（`ElevatedButton` 上静默失效），改为高亮引导用户亲手点；查询结果高亮 bug 修复（broadcast 按场景取 key，pension + yibao_query 同修）
5. **三遗留 bug 修复**：#52 `_strip_thinking` 过滤 `<think>` 块；#53 `build` 内幂等补绑 executor；#54 草稿 `pageId` 去重

**团队参与**：PM（需求分析 / 文档）/ frontend / backend（主力）/ lead

**关键决策**：
- **COMMITS.md 删除，三文档机制确立**：ISSUES + SESSION-LOG + CLAUDE.md 分工清晰，commit 记录以 git log 为权威
- **验证码登录登录前破例提权 L2**：采用场景豁免 `_SCENE_FORCE_TOOLS`，安全性由 `_SENSITIVE_TOOLS` 授权卡保证，不影响其他场景权限
- **下拉框代填用 applier 回调**：DropdownButtonFormField 无 TextEditingController，applier 是更通用的代填抽象（为医保等有下拉字段的场景铺路）
- **养老金查询去掉 cmd_press_button**：ElevatedButton 上 cmd_press_button 静默失效，改为高亮引导用户亲手点，符合"确定性操作止步"原则

**当前状态**：
- 5 个 commit 已推送 GitHub
- 6 场景 prompt 全部完成多步改造（login_face / login_verify / yibao_jiaofei / pension_query / yibao_query）
- 遗留 bug #52/#53/#54 已修，标为 🧪 待真机验证
- 下次会话恢复点：① 真机测试（人脸验证 #37 + 验证码 #60 + 医保 #61 + 养老金 #62）② N2 云服务器部署 ③ N5 Prompt 调优 ④ N6 答辩准备

---

## 2026-05-22（会话 17）

**主要工作**：

1. **高亮框窗口缩放修复**（commit `5355d01`）：坐标计算从 `localToGlobal + size` 改为 `getTransformTo(null) + transformRect`，根治高亮框在浏览器缩放后位置偏移的问题
2. **聊天框支持上下拖动**（commit `f0f94c0`）：补全 `_bubbleY` 读写，聊天框不再仅限左右移动
3. **多步引导机制阶段 1**（commit `b614a9f`）：后端新增 `cmd_wait_user` + 前端 `step_completed`，代理引导从"一次性执行完"改为逐步引导循环；login_face / login_verify 两个场景 prompt 改造完成
4. **聊天框智能避让高亮区域**（commit `d03861d` + `17daae7` + `649435f`）：监听高亮元素坐标自动上下避让，加入 AnimatedPositioned 平滑过渡 + 脉冲形变落定动效，修复跨页坐标保留问题
5. **step_completed 防抖**（commit `0fd5ed5`）：300ms 防抖合并 clicked_highlight + page_changed 两类事件，避免 LLM 收到重复触发信号
6. **登录引导真实流程对齐**（commit `1c11fdd`）：input_phone 字段注册高亮 key + 输入完成检测、条款浮层与摄像头授权弹窗注册为可高亮元素、login_face prompt 步骤重排
7. **弹窗蒙版修复**（commit `6ca173b`）：蒙版不透明度降至 15%，聊天框在弹窗出现时不被遮挡
8. **活体检测 TTS 提示**（commit `3178870`）：眨眼/转头阶段加入语音提示，引导老年用户完成活体动作

**团队参与**：frontend（主力）/ backend / PM（文档）/ lead 全员

**关键决策**：
- **多步引导分阶段推进**：阶段 1 先打通 login 场景（流程最复杂），其余场景后续类推；避免一次性改造失控
- **step_completed 取代 clicked_highlight + page_changed 双信号**：两类信号合并统一，后端逻辑更简洁
- **聊天框避让采用 PhoneFrame-local 坐标**：避免 FittedBox 缩放导致的坐标系混用
- **3080 端口缓存白屏改用 3081**：开发阶段绕过浏览器缓存，不作代码层修复

**遗留问题**：
- 多步引导阶段 2 未完成（医保缴费/养老金查询等场景 prompt 尚未多步改造）
- LLM response.content 仍不空（DeepSeek 仍输出思考过程，会话 15 遗留）
- pop 返回时 executor 失效（会话 15 遗留）
- 草稿重复追加 — `_checkPageDraft` 反复执行（会话 15 遗留）
- 人脸验证真机测试仍未进行（#37 🧪，会话 9 遗留）

**当前状态**：
- 10 个 commit，工作树干净，未 push
- login 场景多步引导可端到端测试
- 下次会话恢复点：① 测试 login 多步引导端到端 ② 其余场景 prompt 多步改造 ③ 修复 LLM response.content / pop 返回 executor 失效 ④ 真机测试

---

## 2026-05-21（会话 15）

**主要工作**：

1. **代理引导机制大重构**（commit `bea2330`）：新建 `AgentSession` 全局单例，WS 连接不随页面切换断开，面板状态全局化；后端新增 `knowledge/pages.py`（10 页页面知识库 + BFS 路径查找 + 启动校验）；5 个 scene prompt 三段式重写（标准流程写死 + LLM 仅选起点 + 环境信息自动注入）；前端新增 5 个 element_key 注册；`cmd_say` 成为唯一发声入气泡渠道，其他 cmd_* 纯 UI 操作；产出 `docs/AGENT_KNOWLEDGE_DESIGN.md` v2.0（1006 行）
2. **voice_hint 死参数清理**（commit `cb85ee0`）：从 5 个工具签名、4 个 Payload 模型、ws_handler 构造处及 5 个 scene prompt 中移除 `voice_hint` 死参数，修正 `_EXECUTOR_PREFIX` 矛盾描述
3. **聊天框自动滚动 + 高亮机制重设计**（commit `60ac92a`）：修复代理发言后不自动滚到底部；高亮机制去蒙版（改为边框突出），点击高亮区消失，`AgentElementRegistry` 实时追踪元素位置
4. **AgentElementRegistry 按 route 分区注册**（commit `d2debc3`）：注册改为按页面路由分区，避免跨页 key 冲突；`rootOverlay` 修复高亮框位置偏移

**团队参与**：frontend（主力）/ backend / PM（文档）/ lead

**关键决策**：
- **AgentSession 全局单例**：跨页 session 让代理在用户跳页后可继续引导，是多步引导机制的核心基础设施
- **页面知识库 BFS**：后端可自主规划跨页导航路径，不再依赖 prompt 硬编码跳转
- **cmd_say 唯一发声**：职责清晰化，其他工具不再有 voice_hint 副作用

**遗留问题**：
- LLM response.content 仍不空（DeepSeek 思考过程泄漏，#52）
- pop 返回时 executor 失效（#53）
- 草稿重复追加（#54）

**当前状态**：
- 引导机制大重构完成，跨页 session 可用
- 下次会话恢复点：验证多步引导端到端 → 修复 #52/#53/#54 遗留 Bug

---

## 2026-05-21（会话 14）

**主要工作**：

1. **load_dotenv 路径修复**（commit `8dcbb4b`）：`load_dotenv()` 无参时在 CWD 找 .env，从项目根启动时找不到 `backend/.env`，导致 API key 为空。改为相对 `main.py` 路径加载，修复 `DEEPSEEK_API_KEY` 读不到的问题
2. **响应延迟优化 11s→1s**（commit `e8f0b7f`）：关闭 agno 遥测 + DeepSeek 参数调优 + OOS 合并 + 去 TTS 阻塞，OOS 路径 11.2s → 1.0s（详见 #56）
3. **AgentFab 聊天记录持久化**（commit `97e94c2`）：新增 ChatHistory 单例，关闭重开不丢历史（详见 #57）
4. **ModeNotifier localStorage 持久化**（commit `24e4fce`）：F5 刷新后长辈版模式不再丢失（详见 #58）
5. **登录分支选择弹窗**（commit `a9332ba`）：模糊登录意图弹两按钮让用户选（详见 #59）
6. **DEPLOY.md 从零 clone 到跑通完整补全**（commit `d6df16c`）：补全 9 项缺失步骤
7. **gitignore 防御性加固**（commit `ccd5145`）：显式忽略 .venv/venv/env/.pytest_cache

**团队参与**：frontend / backend（主力）/ PM / lead

**关键决策**：
- **响应优先级调整**：遥测和 TTS 阻塞是主要瓶颈，去掉后性能提升显著（11x）
- **持久化策略**：聊天记录内存持久化（关闭不丢）；模式 localStorage 持久化（F5 不丢）

**当前状态**：
- 性能、持久化、登录体验三项优化完成
- 下次会话恢复点：代理引导机制重构（会话 15）

---

## 2026-05-20（会话 13）

**主要工作**：

1. **三级权限方案 v0.6 设计定稿**（commit `68d8ebe`）：PM × architect 联合稿，6 项决策全部拍板（信任分级 L0/L1/L2、密码硬底线、任务级一次性授权等）
2. **三级权限全链路实现**（commits `b88ee3e`→`9d09441`）：
   - 后端：`say` 工具 + `trust_level` 模型 + 场景×级别工具集 + `execute_task` 权限分级 + 密码硬拒 + ws_handler 透传
   - prompt：登录场景纯引导模式 + 医保缴费去 mock 数据
   - 前端：AgentSettingsService 设置服务 + cmd_say 渲染 + 权限卡组件 + fab 参数传递 + 首次弹卡 + 设置页三卡 + 未登录灰显
3. **AGENT_SPEC v1.1 对齐**（commit `66b6cb3`）：§3.3 三级信任模型重写 + 能力矩阵 + 权限矩阵新增（详见 #55）
4. **三级权限审查修正**（commit `fdcf19d`）：read_sms 注释 + prompt 兜底规则 + 弹卡 flag 提前 3 处修正
5. **DEPLOY.md 全面修订**（commit `64bd793`）：端口/环境变量/路由表/MediaPipe 资源说明全量对齐实际
6. **WS 连接 3 处修复**（commit `f5ad852`）：动态 host 推导（解决跨机访问问题）+ 订阅时序 + 单例残留清理

**团队参与**：PM（主力）/ architect / frontend / backend / lead

**关键决策**：
- **三级信任模型**：L0 纯引导（无需授权）/ L1 需实时确认 / L2 密码级硬拒，成为小浙代理的核心安全机制
- **密码硬底线**：无论任何 trust_level，密码相关字段代理一律不填，前端白名单双重保障
- **cmd_say 统一发声**：cmd_say 成为唯一发声+气泡渠道，其他 cmd_* 纯 UI 操作（为会话 15 重构铺路）

**当前状态**：
- 三级权限全链路已实现，AGENT_SPEC v1.1 定稿
- 下次会话恢复点：性能优化（会话 14）→ 引导机制大重构（会话 15）

---

## 2026-05-19（会话 9）

**主要工作**：

1. **拉取 GitHub 最新代码**（commit `e07f0d8`，会话 8 在外部完成），登记到 SESSION-LOG / ISSUES（#31-#36）
2. **项目现状全面审视**：CLAUDE.md / ISSUES.md / NEXT_PLAN.md 全部读完，向 lead 报到 + 提交优先级建议
3. **AgentFab 全页面覆盖**：12 页新增 AgentFab 入口 + 颜色自适配 modeProvider（标准版蓝 / 长辈版橙）+ **删 AgentPanel 死代码 664 行**（PM 审查确认 AgentFab 已事实替代 AgentPanel，原"底部 Tab 中央小浙按钮"在会话 8 已被删）
4. **WS 端口对齐**：前端 WS 客户端默认端口对齐后端 8080
5. **关闭标准版登录/搜索入口** + **长辈版全页面橙色统一**（10 文件 ~50 处），明确"重心在长辈版"
6. **清理论文图表生成脚本及临时截图素材**（35 个文件）—— docs/diagrams 部分被用户主动剔除
7. **"我的"页面未登录态登录引导**：loginProvider watch + `_LoginPrompt`，长辈版橙色样式
8. **修复标准版底部"我的"Tab 误跳长辈版**（1 行）
9. **全页面适老化整改尝试 → 回退**：PM 审 14 页 ~110 处 → 方案 A 逐行改 → 用户认为效果不好 → 全部回退，**仅保留登录页改动**
10. **登录页交互优化定稿**：条款 checkbox 勾选 + 勾选后跳过条款浮层 + 字号适老化 + 删除"其他登录方式"装饰区
11. **人脸验证真检测实现**：MediaPipe FaceLandmarker **本地化部署**（Google CDN 国内不通）+ 浏览器 getUserMedia 摄像头接入 + 完整状态机 S0-S9 + 异常分支 E1-E4
12. **产出 docs/FACE_AUTH_DESIGN.md v1.0**：11 状态 + 4 异常出口逐帧详细设计（ASCII 布局 / 文案精确到字 / 持续时间 / 颜色 / 动画 / 状态机 dart enum）

**团队参与**：PM（主力）/ architect / frontend / lead 全员

**关键决策**：
- **AgentFab 替代 AgentPanel**：成为唯一代理入口，AgentPanel 664 行死代码删除（未来需求由 AgentFab 承载）
- **关闭标准版入口**：项目重心收敛到长辈版，标准版仅作展示用，论文核心论点（受控代理 + 适老化）由长辈版承载
- **适老化批量整改回退**：用户认为方案 A 逐行改字号"效果不好"，回退所有改动只保留登录页。教训：未来字号整改需要先做视觉对比 mockup 再实施，不能直接改代码
- **人脸验证选方案 A 真检测**：否决方案 C（倒计时模拟），核心论点"多模态交互"需要真实摄像头能力支撑
- **MediaPipe 资源本地化**：Google CDN 国内访问不稳，模型 + JS 全部托管自己同源路径
- **保留两个授权弹窗**：应用内"请求刷脸认证"+ 浏览器 getUserMedia 原生权限，分层教学价值
- **超时退回登录页**：不降级短信、不弹对话框，让用户在登录页自己重选（覆盖 PM 初稿的"降级方案"）
- **每步停顿反馈**：S6/S8 各 1.0s、S9 1.5s，绿色 ✓ 对勾 + "识别成功" —— 不无缝衔接，老人能看到每一关结果
- **× 全程可点 + 无二次确认**：老人意图明确就不打扰
- **团队成员模型**：当前误用 Opus 4.7，下次启动改为 Sonnet（节省成本）

**当前状态**：
- 本地领先 origin/main 10 个 commit，**未 push**
- 人脸验证代码完成，待真机测试（#37 🧪）
- 验证码登录流程未开始
- 前端 3080 / 后端 8080 本地运行中
- 下次会话恢复点：N4 人脸验证真机测试 → 验证码登录流程 → N2 云部署 + N3 build + N5 prompt 调优 → N6 答辩准备

---

## 2026-05-17（会话 8 — 从 GitHub 同步）

**主要工作**（commit `e07f0d8`，用户在外部完成，本会话仅做文档登记）：

- **AgentFab 悬浮助手组件**：新增 `app/lib/widgets/agent_fab.dart`（935 行），右下角可拖动气泡形态聊天窗，内置 WS 连接 + 文本输入 + 语音 + 授权卡片，提供独立于底部 Tab 的常驻入口
- **低保真线框图页面**：新增 `app/lib/pages/wireframe_page.dart`（814 行），含 6 个界面线框（长辈首页 / 人脸认证 / 医保缴费 / 代理面板 / 授权卡片 / 操作记录），路由 +6 条，用作论文插图源
- **多页面交互重构**：
  - `drafts_page.dart` 草稿箱（+310 行）
  - `face_auth_page.dart` 人脸认证（±269 行）
  - `pension_query_page.dart` 养老金查询（+364 行）
  - `elder_bottom_nav.dart` 长辈底部导航（-缩减约一半，138→精简版）
  - `mic_button.dart` 麦克风按钮重构
  - `agent_bubble.dart` 气泡样式调整、`agent_panel.dart` 同步更新
- **Noto Sans SC 中文字体集成**：`app/fonts/NotoSansSC-Regular.ttf` + `Bold.ttf`，`pubspec.yaml` 注册字体族
- **后端健壮性加固**：
  - `agent_core.py`：Agno API 字段适配（`add_history_to_messages` → `add_history_to_context`），`send` 异常捕获
  - `ws_handler.py`：消息处理重构 — `_dispatch` 全包 try/except、`text_input` 改 `asyncio.create_task` 异步、ASR 三种错误细分、TTS 按需生成
  - `deepseek_client.py`：错误处理加固
  - `main.py`：新增 `dotenv` 加载
- **论文草稿大幅更新**：`docs/论文草稿.md` ±871 行（v1.0 → v2.0）
- **论文图表素材**：截图（`docs/diagrams/screenshots/` + `brochure_shots/`）、线框图（`docs/diagrams/wireframes/`）、用户旅程图（`user_journey-1~4.png` + `user_journey_full.png` + `user_journey.md`）、信息架构图 `ia_diagram.png`，配套渲染脚本 5 个

**团队参与**：用户外部独立完成，团队成员未参与该次提交

**关键决策**（推测自 diff，未在会话中讨论）：
- 引入 AgentFab 提供"全局浮动"的代理入口，与底部 Tab 中央"小浙"按钮形成两条入口并存
- 用线框图页面作为论文插图源（直接 Flutter 渲染截图，避免另起 Figma/Sketch 工作流）
- 后端 ws_handler 全面 try/except 化，向真机部署前的健壮性靠拢
- 论文草稿 v2.0 大幅扩写，进入答辩材料准备阶段

**当前状态**：
- 代码已从 GitHub 拉取并同步本地
- 部分图表素材已被用户手动删除（与 commit 相比）
- 下一步：继续其余页面交互优化收尾 → N1 麦克风 Web Speech API 接入 → N2 云部署 → N4 真机测试 → N5 Prompt 调优 → N6 答辩准备
- 下次会话恢复点：盘点其余待优化页面 / N1 麦克风接入可立即开始

---

## 2026-05-11（会话 7）

**主要工作**：
- 全页面交互反馈优化：三轮 architect 审查（代码正推→用户视角倒推），48 个问题、约 100 个可交互元素补齐 ripple/InkWell
- PM 出交互样式设计规范 v1.0→v1.1（8 类元素：ripple + 按下缩放 + 背景变色 + SnackBar 提示）
- 新建 PressScaleWrapper 通用按下态组件（Listener+AnimatedScale+AnimatedOpacity+InkWell）
- 闪屏页还原浙里办原版（"伴你一生大小事" + logo）
- 标准版首页全面交互优化：按下缩放/变色、热门服务横向滚动渐变卡片、底部导航弹性回弹、占位功能 SnackBar
- 长辈版首页全面交互优化：35 个元素按 v1.1 规范统一
- 修复 Tab 标签切换文字位移 bug（选中/未选中态 padding 不一致）
- 修复 Tab 选中态消失 bug（Ink 无 Material 祖先→改 Container）
- ThemeData 集中配置 splashColor/highlightColor/hoverColor（标准版蓝/长辈版橙）
- PersistentBanner 加宽 + 按钮改标准版蓝色
- 路由转场统一 180ms FadeTransition

**团队参与**：PM / architect / frontend（主力）/ backend（待命）

**关键决策**：
- 交互规范 v1.0 只有 ripple 不够明显 → v1.1 加入按下缩放+变色+SnackBar 三层反馈
- 搜索栏/消息条等大面积区域不适合缩放动画 → 搜索栏直接跳转，消息条只变色
- Tab 标签不适合缩放（横向排列互相影响布局）→ 只保留 ripple
- Ink 在无 Material 祖先时渲染不可靠 → 改用 Container 做普通背景色切换

**当前状态**：
- 标准版首页 + 长辈版首页交互优化完成
- 其余页面（登录/搜索/服务页/我的等）尚未按 v1.1 规范优化
- 下一步：继续优化其余页面交互 → N1 麦克风接入 → N2 云部署 → N4 真机测试
- 下次会话恢复点：继续其余页面的交互优化（登录页、搜索页、各服务页、我的页）

---

## 2026-05-09（会话 6）

**主要工作**：
- 产出 docs/AGENT_DESIGN_REPORT.md v1.3（智能代理"小浙"设计分析报告，8 节：定位/能力/流程/准则/多模态/UI/专属页面分析/实现差距）
- PM 与 architect 对齐方案：不做独立主页 Tab，在"我的"页面加"小浙助手"设置入口
- 新增 AgentSettingsService + 小浙助手设置页（语音开关/语速/操作记录/草稿箱/使用说明）
- _speakHint 接入设置服务（语音开关 + 动态语速）
- AudioPlayer onEnded 回调修复 + 30s 超时兜底，面板关闭等 TTS 播完
- 产出 docs/USER_JOURNEY_TESTING.md v1.0（7 场景操作级测试旅程图）
- 7 场景 E2E 测试套件（app/test/e2e/，reviewer 编写，architect review + 修复 2 个 P0）

**团队参与**：PM / architect / frontend / backend / reviewer（本次新增）全员参与

**关键决策**：
- 代理不做独立主页 Tab（上下文断裂 + 适老化导航负担），改为"我的"页面轻量设置入口
- 不做历史对话记录（与 session 不持久化架构冲突）和批量预授权（与"权限一事一授"原则冲突）
- AudioPlayer 缺 onEnded 回调从"待验证"升级为"N4 前必须修复"（已修复）
- 报告中 3 处数字以代码为准修正（面板 55%、超时 20s、延迟 2s）

**当前状态**：
- 代理设计报告定稿，设置页已实现，E2E 测试套件就绪
- 下一步：N1 麦克风 Web Speech API 接入 → N2 云部署 → N4 真机测试

---

## 2026-05-09（会话 5）

**主要工作**：
- 前端流程回退：还原旧版（archive/scene-canvas-v1）层级结构，恢复 PhoneFrame 壳、Riverpod ProviderScope、双模式主题
- AgentPanel 协议 P0 Bug 修复：agent_wake payload、permission_response 消息类型、field_key/button_key 字段名对齐
- PersistentBanner 改 Riverpod 响应式；路由路径统一 AppRoutes 常量（18 处硬编码消除）
- WakeWordListener 单例竞争修复（引用计数）
- 草稿写入链路打通（DraftService.autoSave + AgentPanel draft_hint 提示）
- 语音引导 TTS（voice_hint 接入 Web Speech API SpeechSynthesis）
- 长辈首页搜索条入口补回（_EldSearchBar，橙底白框 52dp）
- 后端 scene prompt 路由前缀同步
- 产出 docs/USER_JOURNEY.md v1.0（4 场景用户旅程图 + 情感曲线 + 前端支撑评估 + 3 条调整建议）
- 产出 docs/DEPLOY.md（部署指引，含云服务器配置、Nginx + HTTPS、systemd 服务）

**团队参与**：PM / architect / frontend / backend / reviewer 全员参与

**关键决策**：
- 搜索入口方案：方案 B（内容区顶部搜索条），PM + architect 一致推荐，改动约 25 行，无技术阻碍
- 用户旅程图 3 条调整建议定稿：①刷脸弹窗语音前移（Prompt 加 1 行，列入 N5）；②身份证脱敏接受现状（mock 数据安全风险为零）；③TTS 同步计时改造（N4 真机测试后按需实施）
- 身份证号脱敏当前由前端 _redactValue 渲染打码，后端 WS 消息传明文但为 mock 数据，毕设阶段接受现状

**当前状态**：
- 前端 P0 Bug 全部修复，主流程可在 localhost 跑通
- 草稿写入 / 语音引导 TTS 已实现，待真机验证（N4）
- 下一步：N1 麦克风 Web Speech API 接入 → N2 云服务器部署 → N3 Flutter Web Build → N4 真机测试 → N5 Prompt 调优（含刷脸弹窗语音前移）→ N6 答辩准备
- 下次会话恢复点：确认是否购买云服务器（U1）；N1 麦克风接入可立即开始

---

## 2026-04-28（会话 3）

**主要工作**：
- 启动 CC Team（5 人：PM / architect / frontend / backend / reviewer，均 Sonnet 模型）
- architect 通读 4 份设计文档，产出 `docs/IMPLEMENTATION_PLAN.md`（10 个子任务、4 个 Phase）
- PM 审阅实施计划，提出 3 条调整建议 + 1 条风险补充

**关键决策**：
- 实施计划拆为 4 Phase：Phase 1 后端骨架+Flutter 初始化 → Phase 2 Agent 核心+ASR/TTS+WS 客户端+面板 UI+页面骨架 → Phase 3 指令执行层+草稿箱 → Phase 4 端到端集成
- PM 审阅发现 3 处待调整：① T4 主题字号应为 18sp（非 14sp，PRD 适老化要求）；② T9 需补充医保查询场景（PRD P0 功能被遗漏）；③ Phase 4 验收表需补注草稿箱演示前置步骤
- PM 补充风险：老年用户口音可能影响讯飞 ASR 识别率，建议 T9 加入识别率底线测试
- 以上调整建议用户确认采纳前会话结束，**下次会话需先让 architect 修订 IMPLEMENTATION_PLAN.md 再开工**

**当前状态**：
- 实施计划初稿已出，待用户确认 PM 的调整建议后修订
- 零代码文件，编码尚未开始
- 下次会话恢复点：确认调整建议 → architect 修订计划 → 开始 Phase 1

---

## 2026-04-28（会话 2）

**主要工作**：
- 完成代理设计定义最后 3 组问答（组 D 草稿箱与操作记录 / 组 F 错误恢复 / 组 G 开放补充）
- 更新 `docs/AGENT_DEFINITION_QUESTIONS.md` 全部答案
- 产出 `docs/AGENT_SPEC.md` v1.0（代理设计规范，7 组问答定稿）
- 清理项目结构：旧设计文档归档 `docs/archive/pre-redefinition/`，场景画布归档 `archive/scene-canvas-v1/`，SDK 和脚本移至 `archive/` 下
- 产出 `docs/PRD.md` v1.0（产品需求文档，4 场景用户故事 + 验收标准 + 功能清单）
- 启动团队（PM / architect / frontend / backend / reviewer）
- 产出 `docs/ARCHITECTURE.md` v1.2（系统架构，FastAPI + Agno Agent + DeepSeek-V3 + 讯飞 ASR/TTS，含 WebSocket 协议 15 种消息类型）
- 产出 `docs/UI_UX_DESIGN.md` v1.0（UI/UX 交互设计，4 场景逐步剧本 + 适老化规范 + 代理面板设计）
- 更新 CLAUDE.md 项目结构和当前阶段描述

**关键决策**：
- 代理名字定为"小浙"，形象为卡通化"浙"字小人
- 草稿箱为页面级快照，只存已完成字段，存于前端 IndexedDB
- 子女查看操作记录方式：拿老人手机直接看，不涉及远程/多账号
- 后端框架选 Agno（用户有使用经验，HITL 机制天然对应权限一事一授；v1.0/v1.1 曾推荐手写状态机，用户要求改为 Agno 后 v1.2 定稿）
- 确定性按钮不注册为 Agno 工具，实现物理隔离；非确定性按钮用 `is_deterministic` 字段 + 前端白名单双重保障
- "助手"按钮放底部 Tab 栏中央，替代原浙里办搜索麦克风位

**当前状态**：
- 设计阶段全部完成，下一步进入编码实施
- 团队已启动，需先出实施计划再开始编码

---

## 2026-04-27（会话 1）

**主要工作**：
- 从 image-search 项目的 `.claude/skills/` 学习项目管理经验（project-documentation + team-management）
- 将经验沉淀到 `.claude/memory/`：更新 `feedback_team_mode.md`（补充派活纪律、成员约束），新建 `feedback_project_documentation.md`（四文档机制）
- 建立四文档体系：ISSUES.md / SESSION-LOG.md / CLAUDE.md（均在项目根）
- 清理不需要的文件：删除 `project_tech_decisions.md`、`feedback_working_style.md`（内容已在 CLAUDE.md 中覆盖）；删除整个 `.claude/skills/` 目录和 `skills-lock.json`

**关键决策**：
- 问题清单命名为 ISSUES.md（对齐 image-search skill 定义），状态标记 5 种：✅/🧪/🔧/🐛/❓
- 四文档全部放项目根目录，不放 docs/ 子目录
- skill 文件对本项目无用，只保留 memory 沉淀
- team-personas 通用版骨架暂不定制，等需要时再改

**当前状态**：
- 代理定义期：`docs/AGENT_DEFINITION_QUESTIONS.md` 用户逐条答题中（组 A~E 已定稿）
- 场景画布 v1 封存在 `archive/scene-canvas-v1/`
- 四文档体系已建立，后续每次会话/提交按机制维护
