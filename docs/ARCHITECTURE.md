# 系统架构设计文档

> **版本**：v1.2（2026-04-28）
> **关联文档**：`docs/PRD.md`、`docs/AGENT_SPEC.md`
> **作者**：architect
> **变更说明**：v1.2 将后端代理框架改为 Agno（2.2 节重写），更新组件图与职责表，更新附录 A 状态机说明

---

## 1 系统组件总览

### 1.1 组件图

```
┌─────────────────────────────────────────────────────────────────┐
│                        用户设备（浏览器）                         │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   Flutter Web 前端                        │  │
│  │                                                          │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │  │
│  │  │  业务页面层   │  │  代理 UI 层   │  │  本地存储层    │  │  │
│  │  │（11 个页面）  │  │（底部面板）   │  │（草稿箱/记录） │  │  │
│  │  └──────┬──────┘  └──────┬───────┘  └───────────────┘  │  │
│  │         │                │                              │  │
│  │  ┌──────┴────────────────┴───────────────────────────┐  │  │
│  │  │              WebSocket Client                      │  │  │
│  │  └───────────────────────┬───────────────────────────┘  │  │
│  └──────────────────────────┼───────────────────────────────┘  │
│                             │ WebSocket                        │
└─────────────────────────────┼───────────────────────────────────┘
                              │
┌─────────────────────────────┼───────────────────────────────────┐
│              后端代理服务（FastAPI）                               │
│                             │                                   │
│  ┌──────────────────────────┴───────────────────────────────┐  │
│  │              WebSocket Handler（消息路由）                  │  │
│  └──────┬──────────────────┬─────────────────┬──────────────┘  │
│         │                  │                  │                 │
│  ┌──────┴───────┐  ┌────────┴──────┐  ┌───────┴─────────┐      │
│  │  Agno Agent   │  │  ASR 适配器    │  │  TTS 适配器      │      │
│  │（工具注册、    │  │（音频→文字）   │  │（文字→音频）     │      │
│  │ HITL 确认、   │  └────────┬──────┘  └───────┬─────────┘      │
│  │ session 管理、│           │                  │               │
│  │ structured    │           │                  │               │
│  │ output）      │           │                  │               │
│  └──────┬───────┘           │                  │               │
│         │                  │                  │               │
└─────────┼──────────────────┼──────────────────┼───────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
   ┌─────────────┐  ┌──────────────┐  ┌──────────────┐
   │ DeepSeek API │  │  ASR 服务    │  │  TTS 服务     │
   │  (LLM 推理)  │  │（讯飞/云服务）│  │（讯飞/Edge） │
   └─────────────┘  └──────────────┘  └──────────────┘
```

### 1.2 各组件职责

| 组件 | 职责 |
|---|---|
| **Flutter Web 前端 · 业务页面层** | 渲染 11 个长辈版页面；接收代理指令执行页面跳转、元素高亮、字段填充；呈现操作结果 |
| **Flutter Web 前端 · 代理 UI 层** | 底部对话面板；麦克风采集；语音波形反馈；代理文字/语音回复显示；授权弹窗 |
| **Flutter Web 前端 · 本地存储层** | 草稿箱（IndexedDB）；操作记录（IndexedDB）；代理会话状态（内存，页面关闭丢弃） |
| **WebSocket Client** | 维持与代理服务的长连接；序列化/反序列化消息；断线提示 |
| **Agno Agent** | 核心代理运行时：注册并调度操作工具（页面跳转、高亮、代填等）；通过 HITL 机制实现授权确认；管理 session 级对话历史；调用 DeepSeek-V3 完成意图理解与话术生成；structured output 解析 LLM 输出为结构化指令 |
| **ASR 适配器** | 接收前端音频流；调用 ASR 服务；返回识别文字给 Agno Agent |
| **TTS 适配器** | 接收代理话术文字；调用 TTS 服务；返回音频数据给前端播放 |
| **DeepSeek API** | 意图理解；复述话术生成；超出能力场景的应答文字生成 |
| **ASR 服务** | 普通话语音转文字 |
| **TTS 服务** | 文字转语音（适老化：语速偏慢、音色亲切） |

---

## 2 技术选型

### 2.1 前端：Flutter Web

**结论：保持 Flutter Web，无需更换。**

理由：已有技术基础（场景画布 v1 已用 Flutter Web 实现 11 页原型）；跨平台 Web 部署满足毕设演示需求；GoRouter 路由体系已成熟；无需引入新技术栈。

### 2.2 后端代理框架

> 本节为 v1.2 修订，基于 Agno 最新文档（2025-2026 年）重新评估并更新推荐。

**结论：推荐 FastAPI + Agno Agent，替代手写状态机。**

#### 2.2.1 框架对比表

| 框架 | 定位 | 学习成本 | 文档质量 | HITL 支持 | 工具注册 | 毕设适配性 |
|---|---|---|---|---|---|---|
| **Agno**（推荐） | 轻量单/多 Agent 运行时；原生 DeepSeek 支持；内置 tool use / HITL / session / structured output | 中（有 FastAPI 经验上手快） | 好（docs.agno.com，持续更新） | 原生支持（requires_confirmation 装饰器） | 原生支持（Python 函数注册为 tool） | ★★★★★ |
| FastAPI + 手写状态机 | 无框架，完全自控 | 无额外成本 | — | 需自行实现 | 需自行实现 | ★★★★ |
| **LangGraph** | 状态图编排；LangChain 生态 | 高（图概念 + 生态复杂） | 好（英文） | 有（checkpoint） | 有 | ★★ |
| **CrewAI** | 角色制多 Agent | 低 | 好（英文） | 有限 | 有 | ★★ |
| **AutoGen**（Microsoft） | 对话式多 Agent；研究场景 | 高 | 好（英文） | 有限 | 有 | ★ |
| **Dify / Coze** | 低代码/无代码平台 | 极低 | 好 | 平台托管，黑盒 | 黑盒 | ★ |

#### 2.2.2 选择 Agno 的理由

**1. 已有实际使用经验**：场景画布 v1 后端（FastAPI + WebSocket + Agno Agent + DeepSeek-V3）已用 Agno 搭建，团队熟悉 API，无额外学习成本。

**2. HITL 机制原生对应"权限一事一授"**：Agno 的 `@tool(requires_confirmation=True)` 装饰器可在工具执行前暂停代理、等待用户确认，与"权限一事一授"原则天然契合，无需手写中断逻辑。

**3. Tool use 替代状态机的能力分级**：L1/L2/L3 能力分级通过工具的**条件注册**实现——每个能力（代填非敏感字段、代填敏感字段）作为独立 tool，按场景动态传入 `tools=` 参数。不需要的能力不注册，代理物理上无法调用。

**4. Structured output 保证指令可靠性**：Agno 支持 `response_model=` 强制 LLM 输出符合 Pydantic schema 的结构化 JSON，前端收到的指令格式有保障，无需手写解析层。

**5. Session 管理轻量可控**：Agno session 是 WebSocket 连接级别的短生命周期，连接关闭时 session 自然失效——天然匹配"权限一事一授"的任务级授权，不会跨 session 残留授权状态。

**6. 毕设学术价值**：使用正式 Agent 框架比手写状态机在论文中更有讨论价值，可在"技术实现"章节展开"基于 Agno HITL 机制的受控响应型代理设计"的学术叙事。

#### 2.2.3 Agno 在本项目中的使用方式

**用到的能力**：
- `Agent` 类 + `tools=[]` 参数注册操作工具
- `@tool(requires_confirmation=True)` 实现授权确认（权限一事一授）
- `response_model=` 强制 structured output（指令格式保障）
- `session_id=` 绑定 WebSocket 连接，管理对话历史（最近 10 轮）
- DeepSeek-V3 原生集成（`model=DeepSeek(id="deepseek-chat")`）

**不用的能力**：
- **长期 memory / 持久化 storage**：不启用（毕设不需要跨 session 记忆，且避免授权状态意外持久化）
- **多 Agent 编排（Teams）**：不使用（单 Agent 架构）
- **AgentOS 云托管**：不使用（本地 FastAPI 自托管）
- **内置向量知识库（RAG）**：不使用（无知识检索需求）

#### 2.2.4 三条横切原则在 Agno 架构中的落地

| 横切原则 | 落地机制 |
|---|---|
| **原则 1：代理永远不主动** | WebSocket Handler 控制：收到 `agent_wake` 消息才实例化 Agno Agent 并开始运行；连接建立时 Agent 处于静默，不调用任何工具 |
| **原则 2：确定性操作代理止步** | 确定性按钮（"登录"/"去支付"等）**不注册为工具**；Agent 物理上无法调用；只有非确定性操作（"查询"/"下一步"）注册为 `cmd_press_button` tool |
| **原则 3：权限一事一授** | 敏感能力（`fill_sensitive_field`、`read_sms`）使用 `@tool(requires_confirmation=True)` 注册；Agent 调用前自动触发 HITL 暂停，向前端推送 `permission_request` 消息，等待用户当场授权；session 结束授权自动失效 |

### 2.3 LLM 选型

**结论：推荐 DeepSeek-V3（API 调用），备选 DeepSeek-R1。**

| 方案 | 中文能力 | 成本 | 延迟 | 毕设适配性 |
|---|---|---|---|---|
| **DeepSeek-V3**（推荐） | 极强 | 极低（¥0.27/M input tokens） | 低 | ★★★★★ |
| DeepSeek-R1 | 极强 | 低（¥4/M input tokens） | 中（思维链） | ★★★★ |
| GPT-4o | 强 | 高（$5/M input tokens） | 低 | ★★★ |
| Qwen-Max | 强 | 低 | 低 | ★★★★ |
| 本地模型（Ollama） | 中 | 零 | 高（受设备限制） | ★★ |

**推荐理由**：DeepSeek-V3 中文理解与生成质量最高，API 价格极低（毕设用量月均 < ¥10），响应速度快。意图理解场景不需要 R1 的思维链推理。开题报告已提到 DeepSeek-V3，沿用保持一致。

### 2.4 ASR（语音识别）选型

**结论：推荐讯飞 ASR（WebSocket 流式）。**

| 方案 | 中文准确率 | 实时性 | 成本 | 接入复杂度 |
|---|---|---|---|---|
| **讯飞实时语音转写**（推荐） | 极高 | 流式，延迟 < 500ms | 免费额度 500 小时/年 | 中（WebSocket） |
| 阿里云 ASR | 高 | 流式 | 有免费额度 | 中 |
| Google Speech-to-Text | 高 | 流式 | 按量付费，无中文优化 | 中 |
| Web Speech API（浏览器原生） | 中 | 实时 | 免费 | 低 | 
| Whisper（本地） | 高 | 非实时（批量） | 零 | 高（需 GPU） |

**推荐理由**：讯飞 ASR 在普通话识别上准确率业界领先，免费额度对毕设足够，WebSocket 流式 API 与架构天然契合。浏览器原生 Web Speech API 准确率不稳定、Chrome 依赖度高、无法自定义语速/打断，不推荐作主方案。

### 2.5 TTS（语音合成）选型

**结论：推荐讯飞 TTS，兼容备选 Edge TTS（微软免费）。**

| 方案 | 音色自然度 | 语速可控 | 成本 | 接入复杂度 |
|---|---|---|---|---|
| **讯飞 TTS**（推荐） | 极高 | 可调 | 免费额度充足 | 低（HTTP/WebSocket） |
| Edge TTS（微软）| 高 | 可调（SSML） | 完全免费 | 低（HTTP） |
| 阿里云 TTS | 高 | 可调 | 按量付费 | 低 |
| 浏览器原生 Web Speech Synthesis | 中 | 有限 | 免费 | 极低 |

**推荐理由**：讯飞 TTS 可定制语速（慢 20% 适合老年用户）、音色亲切自然。若讯飞配额不足，Edge TTS 作无缝备选（接口风格类似，切换成本低）。两者都能输出 mp3/pcm，前端统一用 HTML5 Audio 播放。

---

## 3 数据模型

### 3.1 草稿箱数据结构

存储位置：**前端 IndexedDB**（`db: xiaozhe_draft`，`store: drafts`）

```json
{
  "draft_id": "draft_20260428_143022",
  "page_id": "yibao_jiaofei",
  "page_title": "医保缴费",
  "created_at": "2026-04-28T14:30:22+08:00",
  "updated_at": "2026-04-28T14:35:10+08:00",
  "fields": {
    "jiaofei_duixiang": "本人",
    "jiaofei_niandu": "2026",
    "jiaofei_jine": "4800",
    "id_card": ""
  },
  "sensitive_fields_filled": false,
  "status": "incomplete"
}
```

**设计说明**：
- `fields` 只存已完成字段，未填字段留空字符串，不存半截输入
- `sensitive_fields_filled` 标记身份证号等是否已填（子女查看时脱敏处理）
- 一个页面同时只保留一份草稿（同 `page_id` 覆盖旧草稿）
- 草稿箱最多保留 10 条，超出删除最旧的

### 3.2 操作记录数据结构

存储位置：**前端 IndexedDB**（`db: xiaozhe_draft`，`store: operation_logs`）

```json
{
  "log_id": "log_20260428_143022_001",
  "created_at": "2026-04-28T14:30:22+08:00",
  "scene": "yibao_jiaofei",
  "scene_title": "医保缴费",
  "trigger": "voice",
  "status": "completed",
  "summary": "帮您填写了医保缴费表单（缴费年度：2026年，金额：4800元），您亲手点击了"去支付"",
  "steps": [
    { "seq": 1, "action": "page_navigate", "target": "医保缴费页", "by": "agent" },
    { "seq": 2, "action": "field_fill", "field": "缴费对象", "value": "本人", "by": "agent" },
    { "seq": 3, "action": "field_fill", "field": "缴费年度", "value": "2026", "by": "agent" },
    { "seq": 4, "action": "field_fill", "field": "金额", "value": "4800", "by": "agent" },
    { "seq": 5, "action": "button_press", "target": "去支付", "by": "user" }
  ],
  "sensitive_actions_redacted": true
}
```

**设计说明**：
- `summary` 是给子女看的一句话摘要（由代理服务生成）
- `steps` 中涉及敏感字段（身份证号等）的 `value` 替换为 `"[已隐藏]"`
- `by` 字段区分代理做的 vs 用户做的，契合 AGENT_SPEC 中"确定性操作由用户亲手完成"的原则
- 记录保留最近 50 条，超出删除最旧的

### 3.3 代理会话状态

存储位置：**前端内存**（页面关闭即丢弃，不持久化）

```json
{
  "session_id": "sess_20260428_143010",
  "state": "executing",
  "current_task": {
    "task_type": "yibao_jiaofei",
    "intent_confirmed": true,
    "current_step": "fill_field",
    "granted_permissions": ["read_sms", "fill_sensitive_field"],
    "pending_field": "jiaofei_niandu"
  },
  "dialog_history": [
    { "role": "user", "text": "帮我缴医保", "ts": "2026-04-28T14:30:10+08:00" },
    { "role": "agent", "text": "帮您缴医保，对吗？", "ts": "2026-04-28T14:30:12+08:00" },
    { "role": "user", "text": "对", "ts": "2026-04-28T14:30:14+08:00" }
  ],
  "asr_retry_count": 0,
  "websocket_connected": true
}
```

**设计说明**：
- `granted_permissions` 只在本次 session 内有效，session 结束后清空（对应原则 3：权限一事一授）
- `dialog_history` 只保留最近 10 轮，超出裁剪后传给 LLM（控制 token 成本）
- 会话状态不上传后端，后端只维护 WebSocket 连接级别的轻量上下文

### 3.4 存储方案总结

| 数据类型 | 存储位置 | 生命周期 | 理由 |
|---|---|---|---|
| 草稿箱 | 前端 IndexedDB | 用户手动删或超出 10 条 | 离线可访问；无需账号体系 |
| 操作记录 | 前端 IndexedDB | 超出 50 条自动删旧 | 子女拿手机直接看；不需要服务端 |
| 代理会话状态 | 前端内存 | 页面关闭即丢 | 无敏感持久化风险；符合毕设原型定位 |
| 后端 | 无持久化 | - | 毕设不需要生产级存储；无账号体系 |

---

## 4 前后端通信协议

### 4.1 设计原则

- 所有消息走单一 WebSocket 连接（`ws://host/ws/session/{session_id}`）
- 消息统一格式：`{ "type": "...", "payload": {...}, "ts": "ISO8601" }`
- 前端 → 后端：用户事件（唤醒、语音、确认）
- 后端 → 前端：代理指令（跳转、高亮、填字段、播语音、请求授权）

### 4.2 消息类型定义

#### 4.2.1 唤醒代理

**前端 → 后端**
```json
{
  "type": "agent_wake",
  "payload": {
    "session_id": "sess_20260428_143010",
    "trigger": "button",
    "current_page": "elder_home"
  },
  "ts": "2026-04-28T14:30:10+08:00"
}
```

**后端 → 前端**（唤醒确认）
```json
{
  "type": "agent_ready",
  "payload": {
    "greeting": "您好，我是小浙，有什么可以帮您？",
    "draft_hint": "您上次有个未完成的医保缴费，要继续吗？",
    "has_draft": true,
    "draft_id": "draft_20260428_130000"
  },
  "ts": "2026-04-28T14:30:11+08:00"
}
```

#### 4.2.2 语音输入（音频流）

**前端 → 后端**（分片发送）
```json
{
  "type": "audio_chunk",
  "payload": {
    "session_id": "sess_20260428_143010",
    "chunk_index": 3,
    "is_last": false,
    "audio_base64": "UklGRiQA..."
  },
  "ts": "2026-04-28T14:30:15+08:00"
}
```

**前端 → 后端**（语音结束）
```json
{
  "type": "audio_end",
  "payload": {
    "session_id": "sess_20260428_143010"
  },
  "ts": "2026-04-28T14:30:18+08:00"
}
```

#### 4.2.3 ASR 识别结果（后端内部 → 前端显示）

**后端 → 前端**
```json
{
  "type": "asr_result",
  "payload": {
    "text": "帮我缴医保",
    "is_final": true,
    "confidence": 0.97
  },
  "ts": "2026-04-28T14:30:19+08:00"
}
```

#### 4.2.4 代理回复（文字 + 语音）

**后端 → 前端**
```json
{
  "type": "agent_reply",
  "payload": {
    "text": "帮您缴医保，对吗？",
    "tts_audio_base64": "UklGRiQA...",
    "tts_format": "mp3",
    "requires_confirmation": true,
    "confirmation_timeout_ms": 10000
  },
  "ts": "2026-04-28T14:30:20+08:00"
}
```

#### 4.2.5 用户确认/拒绝

**前端 → 后端**
```json
{
  "type": "user_confirm",
  "payload": {
    "session_id": "sess_20260428_143010",
    "answer": "yes",
    "input_mode": "voice",
    "raw_text": "对"
  },
  "ts": "2026-04-28T14:30:22+08:00"
}
```

#### 4.2.6 页面跳转指令

**后端 → 前端**
```json
{
  "type": "cmd_navigate",
  "payload": {
    "target_route": "/elder/yibao-jiaofei",
    "transition": "push",
    "voice_hint": "好的，帮您打开医保缴费页面"
  },
  "ts": "2026-04-28T14:30:23+08:00"
}
```

#### 4.2.7 高亮元素指令

**后端 → 前端**
```json
{
  "type": "cmd_highlight",
  "payload": {
    "element_key": "btn_go_payment",
    "highlight_color": "#FF6D00",
    "pulse": true,
    "voice_hint": "请您点这个橙色的"去支付"按钮",
    "duration_ms": 5000
  },
  "ts": "2026-04-28T14:30:45+08:00"
}
```

**设计说明**：`element_key` 为前端预注册的语义 key，与实际 widget key 映射，代理服务只知道语义 key，不知道 DOM 结构。

#### 4.2.8 代填字段指令

**后端 → 前端**
```json
{
  "type": "cmd_fill_field",
  "payload": {
    "field_key": "jiaofei_niandu",
    "field_label": "缴费年度",
    "value": "2026",
    "is_sensitive": false,
    "voice_hint": "已帮您填好缴费年度：2026年"
  },
  "ts": "2026-04-28T14:30:35+08:00"
}
```

#### 4.2.9 授权请求

**后端 → 前端**（代理请求用户当场授权）
```json
{
  "type": "permission_request",
  "payload": {
    "permission_id": "perm_fill_id_card_20260428_143010",
    "permission_type": "fill_sensitive_field",
    "field_label": "身份证号",
    "description": "这次我帮您填身份证号可以吗？",
    "tts_audio_base64": "UklGRiQA...",
    "expires_in_ms": 15000
  },
  "ts": "2026-04-28T14:30:38+08:00"
}
```

**前端 → 后端**（用户授权响应）
```json
{
  "type": "permission_response",
  "payload": {
    "permission_id": "perm_fill_id_card_20260428_143010",
    "granted": true,
    "input_mode": "voice",
    "raw_text": "可以"
  },
  "ts": "2026-04-28T14:30:41+08:00"
}
```

#### 4.2.10 任务结束

**后端 → 前端**
```json
{
  "type": "task_done",
  "payload": {
    "scene": "yibao_jiaofei",
    "summary": "医保缴费表单已填好，您点击了"去支付"",
    "voice_hint": "好的，表单已经填好了，祝您一切顺利！",
    "tts_audio_base64": "UklGRiQA...",
    "log_id": "log_20260428_143022_001"
  },
  "ts": "2026-04-28T14:31:00+08:00"
}
```

#### 4.2.11 错误与特殊状态

**后端 → 前端**（ASR 没听清）
```json
{
  "type": "agent_error",
  "payload": {
    "error_code": "asr_unclear",
    "retry_count": 1,
    "max_retries": 3,
    "voice_hint": "不好意思没听清，您再说一遍",
    "tts_audio_base64": "UklGRiQA..."
  },
  "ts": "2026-04-28T14:30:22+08:00"
}
```

**后端 → 前端**（超出能力）
```json
{
  "type": "agent_out_of_scope",
  "payload": {
    "user_intent": "订火车票",
    "scope_type": "not_in_platform",
    "voice_hint": "浙里办没有订火车票的服务，您可以试试 12306",
    "tts_audio_base64": "UklGRiQA..."
  },
  "ts": "2026-04-28T14:30:22+08:00"
}
```

#### 4.2.12 代理思考中状态（盲点补充 1）

**问题**：LLM 推理期间（ASR 结束 → `agent_reply` 发出之前）存在 1-3 秒空白，老年用户容易误判为死机。

**解决方案**：后端在调用 LLM 之前立即推送 `agent_thinking` 消息，前端展示动态动画（如三个跳动小点 + "小浙正在想…"文字）。

**后端 → 前端**（LLM 调用前立即发送）
```json
{
  "type": "agent_thinking",
  "payload": {
    "hint_text": "小浙正在想…",
    "estimated_wait_ms": 2000
  },
  "ts": "2026-04-28T14:30:19+08:00"
}
```

**前端处理逻辑**：
- 收到 `agent_thinking` → 显示思考动画（跳动省略号 + hint_text）
- 收到 `agent_reply` → 立即清除动画，播放回复
- 若超过 `estimated_wait_ms` × 2 仍未收到回复 → 前端自动降级为"网络较慢，请稍等"提示

**时序位置**：插入 `asr_result (final)` 之后、`agent_reply` 之前（见第 5 节医保缴费时序图，在意图解析 LLM 调用前）。

#### 4.2.13 查询结果屏幕展示（盲点补充 2）

**问题**：场景 4（医保查询/养老金查询）PRD 验收标准要求"语音 + 屏幕双通道呈现查询结果"，但架构未说明代理如何驱动页面渲染查询数据。

**解决方案**：查询场景中，代理代按"查询"按钮（`cmd_press_button`）后，页面数据由页面自身从接口获取并渲染（前端业务逻辑）。代理在监测到页面渲染完成后，发送 `cmd_read_result` 指令，前端提取目标数据字段并回传，代理生成播报文本经 TTS 后推送。

**时序补充（查询场景）**：

```
代理服务 → 前端: cmd_press_button（btn_query）
前端: 触发页面查询接口 → 渲染结果
前端 → 代理服务: query_result_ready（携带结果文本）
代理服务 → LLM: 生成播报话术
代理服务 → 前端: agent_reply（含 TTS 音频 + result_highlight）
```

**新增消息类型 1：前端通知查询结果已渲染**

**前端 → 后端**
```json
{
  "type": "query_result_ready",
  "payload": {
    "page_id": "pension_query",
    "result_fields": {
      "month": "2026年4月",
      "amount": "3280",
      "unit": "元"
    }
  },
  "ts": "2026-04-28T14:30:40+08:00"
}
```

**新增消息类型 2：代理指令高亮结果区域**

**后端 → 前端**（在 `agent_reply` 之后或合并发送）
```json
{
  "type": "cmd_highlight",
  "payload": {
    "element_key": "result_pension_amount",
    "highlight_color": "#FF6D00",
    "pulse": false,
    "voice_hint": "您的养老金本月发放了3280元",
    "duration_ms": 8000
  },
  "ts": "2026-04-28T14:30:43+08:00"
}
```

**设计说明**：
- 查询数据由页面接口获取，代理不参与接口调用——避免代理成为数据通道，维持职责清晰
- `result_fields` 由前端从页面 DOM/State 中提取，硬编码提取规则（每个页面对应固定字段）
- 语音播报文本由 LLM 基于 `result_fields` 生成（通俗化，如"3280元"不说"叁仟贰佰捌拾元整"）

#### 4.2.14 前端 listening 状态切换信号（盲点补充 3）

**问题**："正在听您说话"的视觉反馈（麦克风波形动画）由什么触发——前端用户按钮事件自判，还是等后端推消息？

**结论：listening 状态由前端自判，不依赖后端推消息。**

**理由**：麦克风激活是纯前端动作（用户按下录音按钮），前端最先知道，等后端确认再显示动画会引入 100-300ms 延迟，老年用户感知明显。后端只负责接收音频和返回 ASR 结果，不负责管理前端 UI 状态。

**前端 listening 状态触发规则**：

| 事件 | 前端动作 |
|---|---|
| 用户按下"说话"按钮（或长按） | 立即显示麦克风波形动画 + "正在听您说话" |
| 用户松开按钮 / 静音超时 | 停止录音，动画切换为"小浙正在想…"（等待 `agent_thinking`） |
| 收到 `asr_result (is_final=true)` | 在面板显示识别文字 |
| 收到 `agent_thinking` | 显示思考动画（见 4.2.12） |
| 收到 `agent_reply` | 清除动画，播放回复 |

**后端行为**：收到第一个 `audio_chunk` 时可选推送 `asr_listening_ack`（纯 ack，无 UI 语义），前端可用于检测连接健康，不用于驱动动画。

```json
{
  "type": "asr_listening_ack",
  "payload": {
    "session_id": "sess_20260428_143010"
  },
  "ts": "2026-04-28T14:30:15+08:00"
}
```

---

## 5 核心场景技术流程

### 5.1 场景 3：医保缴费（完整时序）

选择理由：L2-L3 混合能力、包含敏感字段单独授权、有草稿箱机制、止步于确定性按钮——4 个场景中最复杂。

```
用户        前端 Flutter        WebSocket        代理服务           LLM          ASR/TTS
 │                │                  │               │               │              │
 │  点击"助手"按钮  │                  │               │               │              │
 │─────────────►  │                  │               │               │              │
 │                │  agent_wake      │               │               │              │
 │                │─────────────────►│               │               │              │
 │                │                  │  路由到代理核心  │               │              │
 │                │                  │──────────────►│               │              │
 │                │                  │               │ 检查草稿箱（无）│              │
 │                │                  │               │               │              │
 │                │                  │   agent_ready │               │              │
 │                │◄─────────────────│               │               │              │
 │  播放 TTS 问候语 │                  │               │               │              │
 │◄─────────────  │                  │               │               │              │
 │                │                  │               │               │              │
 │  说"帮我缴医保"  │                  │               │               │              │
 │─────────────►  │                  │               │               │              │
 │                │  audio_chunk×N   │               │               │              │
 │                │─────────────────►│               │               │              │
 │                │                  │────────────────────────────────────────────►│
 │                │                  │               │               │  音频→文字    │
 │                │                  │◄───────────────────────────────────────────│
 │                │                  │  asr_result   │               │              │
 │                │◄─────────────────│  "帮我缴医保"  │               │              │
 │                │                  │               │               │              │
 │                │                  │  路由到代理核心  │               │              │
 │                │                  │──────────────►│               │              │
 │                │                  │  agent_thinking（LLM 调用前立即推送）          │
 │                │◄─────────────────│               │               │              │
 │                │ 显示"小浙正在想…"  │               │               │              │
 │                │                  │               │ 意图解析 prompt │              │
 │                │                  │               │──────────────►│              │
 │                │                  │               │ intent: yibao_jiaofei       │
 │                │                  │               │◄──────────────│              │
 │                │                  │               │ 生成复述话术    │              │
 │                │                  │               │──────────────►│              │
 │                │                  │               │ "帮您缴医保，对吗？"           │
 │                │                  │               │◄──────────────│              │
 │                │                  │               │ TTS 合成       │              │
 │                │                  │               │──────────────────────────── ►│
 │                │                  │               │ audio          │              │
 │                │                  │               │◄─────────────────────────────│
 │                │                  │  agent_reply  │               │              │
 │                │◄─────────────────│               │               │              │
 │  播放"帮您缴医保，对吗？"            │               │               │              │
 │◄─────────────  │                  │               │               │              │
 │                │                  │               │               │              │
 │  说"对"         │                  │               │               │              │
 │─────────────►  │                  │               │               │              │
 │                │  user_confirm    │               │               │              │
 │                │─────────────────►│──────────────►│               │              │
 │                │                  │               │ 状态机→executing              │
 │                │                  │               │               │              │
 │                │                  │  cmd_navigate │               │              │
 │                │◄─────────────────│  /elder/yibao-jiaofei        │              │
 │                │ 跳转到医保缴费页  │               │               │              │
 │                │ 播放"帮您打开医保缴费页面"         │               │              │
 │◄─────────────  │                  │               │               │              │
 │                │                  │               │               │              │
 │                │                  │  cmd_fill_field（缴费对象：本人）              │
 │                │◄─────────────────│               │               │              │
 │                │ 填入字段          │               │               │              │
 │                │ 播放"已帮您选择缴费对象：本人"      │               │              │
 │◄─────────────  │                  │               │               │              │
 │                │                  │               │               │              │
 │                │                  │  （缴费年度、金额 同理，省略）                  │
 │                │                  │               │               │              │
 │                │                  │ permission_request（身份证号）  │              │
 │                │◄─────────────────│               │               │              │
 │  播放"帮您填身份证号可以吗？"        │               │               │              │
 │◄─────────────  │                  │               │               │              │
 │                │                  │               │               │              │
 │  说"可以"       │                  │               │               │              │
 │─────────────►  │                  │               │               │              │
 │                │  permission_response (granted=true)              │              │
 │                │─────────────────►│──────────────►│               │              │
 │                │                  │               │               │              │
 │                │                  │  cmd_fill_field（身份证号，is_sensitive=true）  │
 │                │◄─────────────────│               │               │              │
 │                │ 填入字段（脱敏显示）│               │               │              │
 │                │                  │               │               │              │
 │                │                  │  cmd_highlight（"去支付"按钮）  │              │
 │                │◄─────────────────│               │               │              │
 │                │ 高亮按钮          │               │               │              │
 │  播放"表单已填好，请您点'去支付'"    │               │               │              │
 │◄─────────────  │                  │               │               │              │
 │                │                  │               │               │              │
 │  亲手点击"去支付"│                  │               │               │              │
 │─────────────►  │                  │               │               │              │
 │                │  task_done       │               │               │              │
 │                │─────────────────►│──────────────►│               │              │
 │                │                  │               │ 写操作记录到前端  │              │
 │                │                  │  task_done ack│               │              │
 │                │◄─────────────────│               │               │              │
 │  播放"好的，祝您顺利！"             │               │               │              │
 │◄─────────────  │                  │               │               │              │
```

**关键止损点说明**：
1. 身份证号填充前触发 `permission_request`，等待用户当场授权（原则 3）
2. 高亮"去支付"后代理停止操作，不发送任何 `cmd_fill_field` 或模拟点击（原则 2）
3. 整个流程代理才开始说话（原则 1）

### 5.2 其余 3 个场景与"医保缴费"的差异点

| 场景 | 能力上限 | 与医保缴费的核心差异 |
|---|---|---|
| **登录 · 刷脸** | L1 | 无 `cmd_fill_field`；无 `permission_request`（L1 不填字段）；刷脸动作在系统弹窗层，代理只做语音解释，不发任何指令介入弹窗 |
| **登录 · 验证码** | L2 | 有 `permission_request`（代读短信）；有 `cmd_fill_field`（验证码，非敏感）；止损点是"登录"按钮而非"去支付" |
| **医保/养老金查询** | L1-L2 全链路 | 无确定性按钮止损点——"查询"按钮是非确定性操作，代理可直接发 `cmd_press_button`；无 `permission_request`；流程最简，时序比医保缴费短约 40% |

**补充说明 · `cmd_press_button`（查询场景专用）**：

查询场景中代理可代按"查询"按钮，需增加一条消息类型：
```json
{
  "type": "cmd_press_button",
  "payload": {
    "button_key": "btn_query",
    "button_label": "查询",
    "is_deterministic": false,
    "voice_hint": "帮您查一下"
  },
  "ts": "2026-04-28T14:30:35+08:00"
}
```
`is_deterministic: false` 是前端的安全检查点——前端收到此指令时校验白名单，只有 `is_deterministic=false` 且 `button_key` 在允许列表内才执行；否则忽略指令并上报告警。

---

## 附录 A：代理运行时状态与 Agno 工具调度

### A.1 WebSocket Handler 状态机（外层，手写）

WebSocket Handler 维护连接级别的轻量状态，控制 Agno Agent 的生命周期：

```
                   ┌─────────┐
                   │  idle   │◄──────────────────────────────┐
                   └────┬────┘                               │
                        │ agent_wake                         │
                        ▼                                    │
                   ┌──────────┐                              │
                   │listening │◄──── asr_unclear (retry<3)   │
                   └────┬─────┘                              │
                        │ asr_result (final)                 │
                        ▼                                    │
                   ┌───────────┐                             │
                   │confirming │ ─── user_confirm(no) ───────┤
                   └─────┬─────┘                             │
                         │ user_confirm(yes)                 │
                         ▼                                   │
                   ┌───────────┐                             │
             ┌─── │ executing │  ← Agno Agent.run() 在此状态运行
             │    └─────┬─────┘                              │
    HITL pause│         │ task_done / out_of_scope           │
    (权限确认) │         ▼                                    │
             └──► ┌──────────┐                              │
                  │   done   │ ──────────────────────────────┘
                  └──────────┘
```

### A.2 Agno Agent 工具注册与 L1/L2/L3 能力分级

`executing` 状态下，WebSocket Handler 根据当前场景动态构造 Agno Agent，传入对应的工具列表：

| 场景 | 注册的工具 | 不注册的工具 |
|---|---|---|
| **登录·刷脸**（L1） | `cmd_navigate`、`cmd_highlight` | `fill_field_normal`、`fill_field_sensitive`、`read_sms` |
| **登录·验证码**（L2） | `cmd_navigate`、`cmd_highlight`、`read_sms`（HITL）、`fill_field_normal` | `fill_field_sensitive` |
| **医保缴费**（L2-L3） | `cmd_navigate`、`cmd_highlight`、`fill_field_normal`、`fill_field_sensitive`（HITL） | — |
| **查询场景**（L1-L2） | `cmd_navigate`、`cmd_highlight`、`fill_field_normal`、`cmd_press_button` | `fill_field_sensitive`、`read_sms` |

**HITL 工具**（标注 HITL 的工具使用 `requires_confirmation=True`）：`read_sms`、`fill_field_sensitive`。

**物理隔离保障**：确定性按钮操作（`btn_login`、`btn_go_payment` 等）永远不出现在任何场景的工具列表中，Agent 在代码层面无法调用。

---

## 附录 B：前端 element_key 与 widget key 映射规范

代理服务只知道语义 key（如 `btn_go_payment`），前端维护映射表：

```dart
const agentElementRegistry = {
  'btn_go_payment': Key('elder_yibao_jiaofei_btn_go_payment'),
  'btn_login':      Key('login_page_btn_login'),
  'btn_query':      Key('pension_query_btn_query'),
  // ...
};
```

新增可被代理操作的元素时，必须在此表注册——这也是前端安全边界（未注册的元素代理无法操作）。
