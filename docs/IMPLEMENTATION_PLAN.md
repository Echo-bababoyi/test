# 编码实施计划

> **版本**：v1.1（2026-04-29）
> **作者**：architect
> **关联文档**：`docs/ARCHITECTURE.md`、`docs/PRD.md`、`docs/AGENT_SPEC.md`、`docs/UI_UX_DESIGN.md`

---

## 1 任务拆分

### T1 · 后端骨架

| 属性 | 值 |
|---|---|
| **归属** | 后端 |
| **涉及文件/模块** | `backend/main.py`、`backend/ws_handler.py`、`backend/agent_core.py`、`backend/models.py` |
| **依赖** | 无（起点） |

**内容**：
- FastAPI 应用初始化，`/ws/session/{session_id}` WebSocket 端点
- WebSocket Handler 状态机骨架（idle / listening / confirming / executing / done），仅框架，不含 Agno 逻辑
- Pydantic 消息模型定义（全部 14 种 WebSocket 消息类型，见 ARCHITECTURE.md §4.2）
- DeepSeek API 客户端封装（`DEEPSEEK_API_KEY` 读环境变量）

---

### T2 · Agno Agent 核心

| 属性 | 值 |
|---|---|
| **归属** | 后端 |
| **涉及文件/模块** | `backend/agent_core.py`、`backend/tools/navigate.py`、`backend/tools/fill_field.py`、`backend/tools/highlight.py`、`backend/tools/press_button.py`、`backend/tools/read_sms.py` |
| **依赖** | T1 |

**内容**：
- Agno `Agent` 实例化，绑定 `DeepSeek(id="deepseek-chat")`，`session_id=` 与 WebSocket 连接绑定
- 5 个工具函数注册：`cmd_navigate`、`cmd_highlight`、`fill_field_normal`、`fill_field_sensitive`（`requires_confirmation=True`）、`cmd_press_button`、`read_sms`（`requires_confirmation=True`）
- 场景级工具动态注册逻辑（Appendix A.2 的 4 场景工具集）
- `response_model=` Pydantic schema，强制 structured output
- 意图分类 prompt（输入：ASR 文本；输出：scene_id + intent 字段）
- 复述话术生成 prompt

---

### T3 · ASR / TTS 适配器

| 属性 | 值 |
|---|---|
| **归属** | 后端 |
| **涉及文件/模块** | `backend/asr_adapter.py`、`backend/tts_adapter.py` |
| **依赖** | T1 |

**内容**：
- 讯飞 ASR：WebSocket 流式接入，接收 `audio_chunk` base64，返回 `asr_result` 消息（含 `is_final`、`confidence`）
- 讯飞 TTS：HTTP/WebSocket 接入，输入文本，返回 mp3 base64；语速参数 0.85（慢 15%）
- Edge TTS 作为 TTS 备选，接口签名与讯飞适配器相同，可通过环境变量切换
- 讯飞 API Key 读环境变量（`XUNFEI_APP_ID`、`XUNFEI_API_KEY`、`XUNFEI_API_SECRET`）

---

### T4 · Flutter 项目初始化 + 路由体系

| 属性 | 值 |
|---|---|
| **归属** | 前端 |
| **涉及文件/模块** | `app/lib/main.dart`、`app/lib/router.dart`、`app/lib/theme.dart` |
| **依赖** | 无（起点，与 T1 并行） |

**内容**：
- `./bin/flutter create app`（使用项目级 SDK）
- GoRouter 路由表：全部 11 个页面路由（`/`、`/elder`、`/login`、`/login/face`、`/login/verify`、`/elder/yibao-jiaofei`、`/elder/yibao-query`、`/elder/pension-query`、`/elder/search`、`/elder/mine`、`/elder/operation-logs`）
- 主题文件（`ThemeData`）：主色 `#FF6D00`，全局字体最小 18sp（PRD §4.1 适老化要求），触控目标最小 48dp
- IndexedDB 封装（`draft_store.dart`、`operation_log_store.dart`），分别对应 `xiaozhe_draft` 数据库的两个 store

---

### T5 · WebSocket 客户端

| 属性 | 值 |
|---|---|
| **归属** | 前端 |
| **涉及文件/模块** | `app/lib/services/ws_client.dart`、`app/lib/services/session_state.dart` |
| **依赖** | T4 |

**内容**：
- WebSocket 连接管理（连接、断开检测、`websocket_connected` 状态更新）
- 消息序列化/反序列化（全部 14 种消息类型对应 Dart 模型）
- `session_state.dart`：前端内存级会话状态（对应 ARCHITECTURE.md §3.3 数据结构），含 `granted_permissions`、`dialog_history`（最近 10 轮）
- 断线 UI 通知（推送到代理面板 `NetworkBanner`）

---

### T6 · 代理面板 UI

| 属性 | 值 |
|---|---|
| **归属** | 前端 |
| **涉及文件/模块** | `app/lib/widgets/agent_panel.dart`、`app/lib/widgets/agent_bubble.dart`、`app/lib/widgets/auth_card.dart`、`app/lib/widgets/mic_button.dart`、`app/lib/widgets/status_bar.dart` |
| **依赖** | T4、T5 |

**内容**：
- 代理面板容器：屏幕高度 45%，底部滑上动画（300ms easeOutCubic），上方页面蒙层（`rgba(0,0,0,0.4)`）
- 对话气泡区：小浙气泡（左对齐，`#FFF0E6` 底）、用户气泡（右对齐，`#F5F5F5` 底），文字 20sp
- 状态行（动态文字：有什么可以帮您 / 正在听您说话… / 小浙正在想…）
- 麦克风大按钮（72dp 圆形，按住录音，松开发送）+ 声波扩散动画
- 授权卡片（`auth_card.dart`）：内嵌在面板，"可以"橙色填充 / "不用了"白底灰边；超时 15 秒自动拒绝
- 网络断开横幅（`NetworkBanner`，顶部 40dp，`#FF3B30`）

---

### T7 · 业务页面骨架（11 页）

| 属性 | 值 |
|---|---|
| **归属** | 前端 |
| **涉及文件/模块** | `app/lib/pages/` 下 11 个 page widget |
| **依赖** | T4 |

**内容**：
- 11 个页面 Widget，均含底部 Tab 栏（首页/助手/我的），助手按钮橙色圆形 56dp
- 各页面预注册 `element_key`：在 `agent_element_registry.dart` 中维护语义 key → Flutter Widget Key 映射表（ARCHITECTURE.md 附录 B）
- 医保缴费页：表单字段（缴费对象/年度/金额/身份证号），支持代填动画（数字逐位填入效果）
- 查询页（医保查询/养老金查询）：结果数据卡片区域，支持 `query_result_ready` 消息触发
- 我的页：草稿箱入口（含红色数字徽章）、操作记录入口

---

### T8 · 代理指令执行层

| 属性 | 值 |
|---|---|
| **归属** | 前端 |
| **涉及文件/模块** | `app/lib/services/agent_command_executor.dart` |
| **依赖** | T5、T6、T7 |

**内容**：
- `AgentCommandExecutor`：接收后端下发的各类 `cmd_*` 消息，分发执行
- `cmd_navigate`：调用 GoRouter 跳转
- `cmd_highlight`：查找 `element_key` 对应 Widget，施加橙色脉冲描边动画（3dp，1000ms 循环），并在蒙层对应位置挖空
- `cmd_fill_field`：向目标字段 Controller 写入值，触发填充动画；`is_sensitive=true` 时显示脱敏值
- `cmd_press_button`：白名单校验（`is_deterministic=false` + key 在允许列表内）后模拟点击
- `query_result_ready`：提取页面 State 中的结果字段，上报后端

---

### T9 · 4 场景端到端集成

| 属性 | 值 |
|---|---|
| **归属** | 全栈 |
| **涉及文件/模块** | 场景 prompt 文件（`backend/prompts/`）、前端场景接线代码 |
| **依赖** | T2、T3、T8 |

**内容**：
- 场景 1（登录·刷脸）：L1 工具集接线，刷脸动作引导话术 prompt
- 场景 2（登录·验证码）：L2 工具集 + `read_sms` HITL 接线，短信读取模拟逻辑（毕设用 mock 返回固定验证码）
- 场景 3（医保缴费）：L2-L3 工具集 + `fill_field_sensitive` HITL 接线，草稿箱保存/恢复逻辑
- 场景 4a（养老金查询）：`cmd_press_button` 接线，`query_result_ready` → TTS 播报结果全链路
- 场景 4b（医保查询）：复用场景 4a 查询链路，工具集相同（L1–L2），跳转医保查询页 + 代按"查询" + 结果双通道呈现
- 超出能力应答：`agent_out_of_scope` 生成逻辑（prompt 兜底规则）

---

### T10 · 草稿箱与操作记录

| 属性 | 值 |
|---|---|
| **归属** | 前端 |
| **涉及文件/模块** | `app/lib/services/draft_service.dart`、`app/lib/services/log_service.dart`、`app/lib/pages/drafts_page.dart`、`app/lib/pages/operation_logs_page.dart` |
| **依赖** | T4、T7 |

**内容**：
- 草稿箱：写入（表单中断时自动触发，`IndexedDB` `drafts` store）、读取（唤醒代理时检查 `draft_hint`）、覆盖旧草稿（同 `page_id` 覆盖）、超出 10 条删最旧
- 操作记录：`task_done` 收到时写入（`operation_logs` store），`steps[]` 中敏感字段 value 替换为 `[已隐藏]`，最多 50 条
- 草稿箱页面 UI：列表展示，每项显示页面名 + 最后更新时间 + "继续"按钮
- 操作记录页面 UI：列表展示，每项显示场景名 + 时间 + `summary`，点击展开 `steps` 明细

---

## 2 开发顺序（按依赖分批）

```
Phase 1（并行）
  ├── T1  后端骨架
  └── T4  Flutter 项目初始化 + 路由体系

Phase 2（依赖 Phase 1，并行）
  ├── T2  Agno Agent 核心          （依赖 T1）
  ├── T3  ASR / TTS 适配器         （依赖 T1）
  ├── T5  WebSocket 客户端          （依赖 T4）
  ├── T6  代理面板 UI               （依赖 T4，T5 可部分并行）
  └── T7  业务页面骨架（11 页）       （依赖 T4）

Phase 3（依赖 Phase 2，并行）
  ├── T8  代理指令执行层             （依赖 T5、T6、T7）
  └── T10 草稿箱与操作记录           （依赖 T4、T7）

Phase 4（全量集成，串行）
  └── T9  4 场景端到端集成           （依赖 T2、T3、T8）
```

---

## 3 技术依赖与风险

### 3.1 外部依赖（需提前获取）

| 依赖 | 获取方式 | 用途 |
|---|---|---|
| `DEEPSEEK_API_KEY` | platform.deepseek.com 注册 | LLM 推理（意图理解、话术生成） |
| `XUNFEI_APP_ID` / `XUNFEI_API_KEY` / `XUNFEI_API_SECRET` | open.xfyun.cn 注册，开通实时语音转写 + 语音合成 | ASR + TTS |
| Agno 版本 | `pip install agno`，当前稳定版（2.x） | Agent 框架 |

### 3.2 需提前确认的技术点

| 技术点 | 风险程度 | 说明 |
|---|---|---|
| **Flutter Web 对 WebSocket 的支持** | 低 | Flutter Web 支持 `dart:html WebSocket`，与 FastAPI `WebSocket` 兼容；但需验证 Chrome/Edge 下无跨域问题（开发期用同源部署或 CORS 配置解决） |
| **讯飞 ASR Web SDK 可用性** | 中 | 讯飞实时语音转写为服务端 WebSocket 协议；**前端音频流需先发到后端，再由后端转发讯飞**（不能从浏览器直连讯飞，因为讯飞需要服务端签名）。这个转发链路是架构中已有的设计，但需实测延迟（预期 < 800ms） |
| **Flutter Web 麦克风权限（`dart:html getUserMedia`）** | 中 | 需要 HTTPS 或 localhost；Chrome 在 HTTP 非 localhost 上不给麦克风权限。开发期用 `localhost` 绕过，演示时部署到 HTTPS |
| **Agno `requires_confirmation=True` + WebSocket 异步的结合** | 中 | Agno HITL 设计为阻塞等待确认；需要在 `AgentCore` 层实现异步挂起（Future/asyncio.Event），等待 `permission_response` 消息到来后恢复。这是本项目最复杂的一处异步协调，需专项验证 |
| **讯飞 TTS 延迟对用户体验的影响** | 低 | 讯飞 TTS 延迟一般 200-500ms，加上 WebSocket 往返约 800ms 总延迟；如超过 1.5s 可切换 Edge TTS（本地生成，延迟更低） |

### 3.3 已知风险与应对

| 风险 | 影响 | 应对方案 |
|---|---|---|
| 讯飞 API 账号审核周期 | 阻塞 T3，进而阻塞 T9 | **提前申请**（注册后一般 1 个工作日）；T3 开发期使用 Edge TTS（免费，无审核）作为 stub，联调通过后切换讯飞 |
| DeepSeek API 不稳定/高延迟 | 影响 T9 联调体验 | 本地缓存常见意图的固定回复作为 mock（如"帮我缴医保"→固定返回 `yibao_jiaofei` intent）；演示时提前预热 API 连接 |
| Agno 版本 API 变更 | T2 重写风险 | 锁定 `agno==x.y.z` 版本号（`requirements.txt` 固定），不用 `agno>=x` |
| Flutter Web IndexedDB 兼容性 | T10 草稿箱失效 | 使用 `idb` Flutter 包（对 `indexed_db` 的封装），避免直接使用底层 `dart:indexed_db`；在 Chrome 和 Edge 双浏览器测试 |
| LLM 意图理解准确率不足 | T9 场景体验差 | 在 prompt 中枚举全部 4 个 scene_id 及触发词示例；对"帮我缴医保"、"医保缴费"等变体各写 3 个 few-shot 示例 |

---

## 4 验收里程碑

### Phase 1 完成后可演示

- FastAPI 服务启动，`/ws/session/{id}` 端点建立 WebSocket 连接
- 发送任意 JSON 消息，服务端能 echo 回来（状态机 idle 状态）
- Flutter Web 在 `localhost` 跑起来，GoRouter 各路由可跳转，主题色 `#FF6D00` 正确

### Phase 2 完成后可演示

- 前端打开代理面板（动画、蒙层、麦克风按钮正常），按住麦克风录音，前端录音波形动画正常
- 后端 WebSocket 接收 `agent_wake`，Agno Agent 实例化，返回 `agent_ready`（含问候语）
- 讯飞 ASR：后端向讯飞转发音频，返回识别文字；TTS：后端生成音频 base64，前端可播放
- 11 个页面骨架可导航，`element_key` 注册表存在

### Phase 3 完成后可演示

- 后端发送 `cmd_navigate`，前端正确跳转页面
- 后端发送 `cmd_highlight`，前端对应元素出现橙色脉冲描边，蒙层挖空
- 后端发送 `cmd_fill_field`，前端字段填充动画正常；`is_sensitive=true` 时脱敏显示
- 后端发送 `permission_request`，前端弹出授权卡片，用户点击"可以"后 `permission_response` 上报
- 草稿箱写入/读取/列表页正常；操作记录写入/列表页正常

### Phase 4 完成后可演示（完整毕设演示）

以下 4 个场景可端到端独立演示（从唤醒到任务完成）：

| 场景 | 演示验收点 |
|---|---|
| 登录·刷脸 | 语音说"帮我登录"→ 复述确认 → 跳转登录页 → 高亮"同意条款" → 高亮"登录"按钮 → 语音引导刷脸 → 播报"登录成功" |
| 登录·验证码 | 语音说"帮我用验证码登录"→ 跳转验证码页 → 授权弹窗 → 代填验证码 → 高亮"登录"按钮 |
| 医保缴费 | 语音说"帮我缴医保"→ 逐字段代填 → 身份证号授权弹窗 → 敏感字段脱敏填入 → 高亮"去支付"止步 |
| 养老金查询 | 语音说"帮我查养老金"→ 代按"查询"→ 结果语音 + 屏幕双通道呈现 |
| 医保查询 | 语音说"帮我查医保"→ 跳转医保查询页 → 代按"查询"→ 结果双通道呈现 |
| 超出能力 | 语音说"帮我订火车票"→ 小浙回复"浙里办没有这个服务" |
| 草稿箱恢复 | **前置步骤**：先执行"医保缴费"场景至中途，关闭代理面板使草稿自动保存。**演示**：再次唤醒 → 小浙提示草稿 → 用户说"要" → 字段恢复 |
| ASR 识别率底线 | 使用 10 句预设测试语料（覆盖 4 场景典型指令），ASR 识别准确率 ≥ 80%；低于此底线切换备选 ASR 方案或调整 prompt 容错 |

---

## 附录：目录结构预期

```
/
├── backend/
│   ├── main.py                  # FastAPI 入口，WebSocket 端点
│   ├── ws_handler.py            # WebSocket Handler 状态机
│   ├── agent_core.py            # Agno Agent 实例化与运行
│   ├── asr_adapter.py           # 讯飞 ASR 适配器
│   ├── tts_adapter.py           # 讯飞 TTS / Edge TTS 适配器
│   ├── models.py                # Pydantic 消息模型（14 种消息类型）
│   ├── prompts/                 # 各场景 prompt 文件
│   │   ├── intent_classify.txt
│   │   └── scene_*.txt
│   ├── tools/                   # Agno 工具函数
│   │   ├── navigate.py
│   │   ├── fill_field.py
│   │   ├── highlight.py
│   │   ├── press_button.py
│   │   └── read_sms.py
│   └── requirements.txt
├── app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── router.dart
│   │   ├── theme.dart
│   │   ├── pages/               # 11 个业务页面
│   │   ├── widgets/             # agent_panel, auth_card, mic_button 等
│   │   └── services/            # ws_client, session_state, draft_service, log_service, agent_command_executor
│   └── pubspec.yaml
└── docs/
    └── IMPLEMENTATION_PLAN.md   # 本文件
```
