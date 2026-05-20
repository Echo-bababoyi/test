# 「操作记录」功能完善 PM 规格文档

> 版本：v1.0 | 日期：2026-05-20 | 作者：PM（session-11b）
> 上游：`docs/YIBAO_JIAOFEI_FLOW_AUDIT.md` → architect 审查报告（D.1.1–D.3.6）
> 下游：frontend 实施

---

## 1. 需求背景与决策摘要

### 1.1 背景

architect 审查报告发现「操作记录」功能存在根本性问题：

- **写入触点过窄**：仅 agent `task_done` 消息触发写入；用户手动完成的 7 页支付链全程不写入，子女拿手机看到的记录页**常年空白**。
- **入口标签错误**：mine_page 仍显示「办事记录」，违反 UI_UX_DESIGN §1.3 规范。
- **缺子标题**：「小浙帮您做了什么，一目了然」未实现。
- **字段残缺**：4 个规范字段（scene_title / trigger / status / sensitive_actions_redacted）缺失。
- **展示体验差**：steps 直接拼 key/value，老人看不懂；无日期分组；空态无引导。

### 1.2 关键决策总表

| 决策项 | 选项 | 本文决策 | 理由 |
|---|---|---|---|
| 写入策略 | A 仅 agent / B 全量手工 / C 双轨 | **C 双轨 + trigger 字段** | 演示可用 + 保留监护语义 |
| 缴费记录 vs 操作记录 | 合并 / 打通 / 分离 | **分离，明确边界** | 两者语义不同，合并增加复杂度 |
| 清空 UI | 不加 / 仅整体清空 / 清空+单删 | **整体清空（P0）+ 单条删除（P2）** | 子女隐私需求；单删适老化风险 P2 处理 |
| 日期分组 | 不分组 / 今天昨天更早 / 按月 | **今天 / 昨天 / 更早** | 老人最关心"刚做的" |
| 场景过滤 chip | 加 / 不加 | **不加（P2 可选）** | 50 条上限 + 日期分组已足够 |
| 空态引导 | 仅文字 / 加 CTA | **加引导文案** | 首次进入体验 |

---

## 2. 写入策略：双轨制（Option C）

### 2.1 策略定义

```
trigger = "voice"   → 代理后端 task_done 消息触发（现有路径）
trigger = "manual"  → 用户手工完成关键节点时前端主动写入（新增路径）
```

两条路径写入**同一个 IndexedDB store（operation_logs）**，统一展示。UI 用徽章区分来源，让子女一眼分辨「小浙代办的」和「老人自己操作的」。

### 2.2 为何不选 A / B

- **方案 A（仅 agent）**：当前 agent `task_done` 实现不完整；演示时子女查看页面永远空白，毕设演示失败。
- **方案 B（仅手工全量）**：失去「小浙代办」的监护语义，AGENT_SPEC §8.3 核心价值丧失。
- **方案 C 优势**：`trigger` 字段保留语义区分；子女仍可筛选「小浙做了什么 vs 老人自己做了什么」；演示时两条路都有记录可展示。

### 2.3 手工触点清单（新增 trigger=manual 写入）

| 写入位置 | 触发条件 | scene 值 | status 值 |
|---|---|---|---|
| `pay_result_page.dart` | 支付成功，用户看到绿色成功页 | `yibao_jiaofei` | `completed` |
| `yibao_query_page.dart` | 查询接口返回成功结果 | `yibao_query` | `completed` |
| `pension_query_page.dart` | 查询接口返回成功结果 | `pension_query` | `completed` |
| `face_auth_page.dart` | 人脸验证通过（状态 S9 PASS） | `face_login` | `completed` |
| `verify_page.dart` | 验证码登录成功（mockLogin 通过） | `otp_login` | `completed` |

> **不写入**的场景：
> - 用户浏览页面（无操作完成）
> - 草稿保存（内部操作，不是"办事"）
> - shebaoJiaona 手工填表（社保税务渠道，非本 APP 代办）

### 2.4 代理触点（现有，确认保留）

`agent_fab.dart:551` 的 `task_done` 分支继续调用 `LogService.saveFromTaskDone(payload)`，无需改动触发逻辑，只需补齐字段（见第 3 节）。

---

## 3. 数据结构规范（补齐字段）

### 3.1 完整字段定义

```json
{
  "log_id": "log_20260520_143022_001",
  "created_at": "2026-05-20T14:30:22.000Z",
  "scene": "yibao_jiaofei",
  "scene_title": "医保缴费",
  "trigger": "manual",
  "status": "completed",
  "summary": "为本人缴纳 2026 年城乡居民医保，金额 380 元",
  "steps": [
    { "seq": 1, "action": "选择险种", "target": "城乡居民医保", "by": "user" },
    { "seq": 2, "action": "选择档次", "target": "一档（380元）", "by": "user" },
    { "seq": 3, "action": "确认支付", "target": "尾号 6789", "by": "user" }
  ],
  "sensitive_actions_redacted": true
}
```

### 3.2 字段变更说明

| 字段 | 现状 | 目标规范 | 说明 |
|---|---|---|---|
| `log_id` | 16字节随机 hex | `log_YYYYMMDD_HHmmss_NNN` | NNN = 同秒内序列（001起，前端用 `DateTime.now()` + 随机3位兜底） |
| `scene_title` | 缺失 | 见 §3.3 映射表 | 中文场景名，展示层直接用，无需 hardcode 在页面 |
| `trigger` | 缺失 | `"voice"` \| `"manual"` | 决定 UI 徽章样式 |
| `status` | 缺失 | `"completed"` \| `"cancelled"` \| `"failed"` | 手工触点只写 completed；agent 路径视 task_done payload |
| `steps[].by` | 不稳定 | `"agent"` \| `"user"` | agent 路径由 log_service 强制注入；手工路径写 `"user"` |
| `sensitive_actions_redacted` | 缺失 | `true`（有脱敏） \| `false`（无）| 由 LogService 脱敏后设置 |

### 3.3 scene → scene_title 映射表（白名单扩充）

```dart
const _sceneTitleMap = {
  'yibao_jiaofei':  '医保缴费',
  'yibao_query':    '医保查询',
  'pension_query':  '养老金查询',
  'shebao_query':   '社保查询',
  'face_login':     '刷脸登录',
  'otp_login':      '验证码登录',
};
```

### 3.4 steps 字段名 → 可读标签映射表

展示层用此表把技术字段名翻译为中文，**代替**直接拼 `key: value`：

```dart
const _fieldLabelMap = {
  'jiaofei_niandu':      '缴费年度',
  'jiaofei_duixiang':    '缴费对象',
  'jiaofei_jine':        '缴费金额',
  'xian_zhong':          '险种',
  'dang_ci':             '档次',
  'id_card':             '证件号',
  'bei_jiaofei_xingming':'被缴费人姓名',
  'bei_jiaofei_sfz':     '被缴费人证件号',
  'query_year':          '查询年度',
  'result_status':       '查询结果',
  'bank_card':           '支付银行卡',
  'amount':              '金额',
};
// 未命中的 key：原样显示，无需报错
```

渲染格式：`「${label}：${value}」`，例如：`「缴费年度：2026 年」`

---

## 4. 敏感脱敏白名单扩充

### 4.1 扩充后白名单

`log_service.dart` 中 `_sensitiveKeys` 扩充为：

```dart
static const _sensitiveKeys = {
  // 现有
  'id_number', 'identity', 'card_no', 'password',
  // 新增
  'id_card', 'sfz', 'bei_jiaofei_sfz',   // 身份证类
  'phone', 'mobile', 'tel', 'phone_number', // 手机号类
  'bank_no', 'bank_card', 'account', 'account_no', // 银行卡类
  'address', 'addr',                        // 地址类
};
```

### 4.2 脱敏规则

| 字段类型 | 脱敏格式 | 示例 |
|---|---|---|
| 身份证号 | 前3后4明文，中间 `****` | `330****2518` |
| 手机号 | 前3后4明文，中间 `****` | `138****8888` |
| 银行卡 | 仅显示「尾号XXXX」| `尾号 6789` |
| 密码类 | 固定 `[已隐藏]` | `[已隐藏]` |
| 地址 | 保留前6字符 + `…` | `浙江省杭州…` |

---

## 5. 入口改造：mine_page.dart

### 5.1 改动项

文件：`app/lib/pages/mine_page.dart`，定位 `_MyActivitySection` 中「办事记录」入口。

| 改动内容 | 改前 | 改后 |
|---|---|---|
| 入口主标签 | 「办事记录」 | **「操作记录」** |
| 图标 | `Icons.work_outline` | `Icons.manage_search`（或保留） |
| 副标题（新增） | 无 | **「小浙帮您做了什么，一目了然」** 16sp 灰色 `Color(0xFF9E9E9E)` |

### 5.2 UI 示意

```
┌─────────────────────────────────────────────┐
│  [icon] 操作记录                   ›        │
│         小浙帮您做了什么，一目了然           │
└─────────────────────────────────────────────┘
```

副标题字号 16sp，颜色 `Colors.grey`（#9E9E9E），在主标签下方。

---

## 6. operation_logs_page.dart UI 规范

### 6.1 AppBar

| 元素 | 规范 |
|---|---|
| 标题 | 「操作记录」22sp 白色 |
| 背景色 | `Color(0xFFFF6D00)`（橙色，与长辈版统一） |
| 右侧操作区 | 仅在列表非空时显示「清空」文字按钮（白色，14sp） |

### 6.2 空态（列表为空时）

```
          [Icons.manage_search, 64dp, grey400]
      
       暂无操作记录
       (20sp, grey600)
       
  小浙助手帮您办事后，记录会显示在这里
  (16sp, grey400, 居中)
```

无跳转按钮（避免让老人困惑）。

### 6.3 加载态

保持现有转圈样式，居中。

### 6.4 日期分组

列表按 `created_at` 降序排列（最新在上），用三组粘性分组标题：

| 分组 | 判断逻辑 |
|---|---|
| 今天 | `created_at` 日期 == 今日 |
| 昨天 | `created_at` 日期 == 昨日 |
| 更早 | 其余 |

分组标题样式：16sp 灰色，左边距 16dp，上下各 8dp padding，背景白色（非粘性，随列表滚动）。

```
  今天
  ├─ [卡片]
  ├─ [卡片]
  昨天
  ├─ [卡片]
  更早
  └─ [卡片]
```

### 6.5 记录卡片设计

每张卡片包含：

```
┌────────────────────────────────────────────────┐
│  ● [场景图标 24dp]  医保缴费      [代理徽章]   │
│     05月20日 14:30                              │
│     为本人缴纳 2026 年城乡居民医保，金额 380 元 │  ← summary 最多 2 行
│                                                 │
│  ▼ 查看步骤详情（可展开）                       │  ← 可展开区域
└────────────────────────────────────────────────┘
```

**代理徽章**：
- `trigger = "voice"` → 「小浙代办」橙色浅底标签（背景 `Color(0xFFFFF3E0)`，文字 `Color(0xFFFF6D00)`，8sp，圆角 4dp）
- `trigger = "manual"` → 「自行操作」灰色浅底标签（背景 `Color(0xFFF5F5F5)`，文字 `Color(0xFF757575)`，8sp，圆角 4dp）

**场景图标映射**（24dp，颜色继承橙色主题）：

```dart
const _sceneIconMap = {
  'yibao_jiaofei':  Icons.health_and_safety,
  'yibao_query':    Icons.search,
  'pension_query':  Icons.account_balance,
  'shebao_query':   Icons.search,
  'face_login':     Icons.face_retouching_natural,
  'otp_login':      Icons.phone_android,
};
// 未命中：Icons.task_alt（通用）
```

**时间格式**：`MM月DD日 HH:mm`（不显示年，老人更易读）

**summary**：最多 2 行，`TextOverflow.ellipsis`，18sp

**status 状态标记**（仅 failed / cancelled 时显示）：
- `failed` → summary 前加红色「✕ 失败」标记
- `cancelled` → summary 前加灰色「⊘ 已取消」标记
- `completed` → 不显示额外标记（默认成功态）

### 6.6 可展开 steps 区域

点击卡片下方「查看步骤详情 ▼」展开，再点「收起 ▲」折叠。

每条 step 渲染规则：

```
  1. 选择险种：城乡居民医保  [agent]
  2. 选择档次：一档（380元） [agent]
  3. 确认支付：尾号 6789     [user]
```

- `by = "agent"` → 右侧显示「小浙」标签（橙色 8sp）
- `by = "user"` → 右侧显示「您」标签（灰色 8sp）
- `action` + `「${_fieldLabelMap[target] ?? target}：${value}」` 拼接
- 无法查到映射的 key → 原样显示，但不显示技术符号（下划线等不用翻译）

### 6.7 整体清空功能

**触发**：AppBar 右侧「清空」按钮（仅列表非空时显示）

**交互**：

```
点击「清空」
  → 弹出 AlertDialog:
    标题：「清空操作记录」
    内容：「确认清空全部 N 条操作记录？此操作不可撤销。」
    按钮：[取消]  [确认清空（橙色）]
  → 确认 → 调用 IndexedDB 全量删除 → 列表刷新为空态
  → 取消 → 关闭弹窗，无操作
```

按钮文字「确认清空」颜色：`Color(0xFFFF6D00)`。

### 6.8 单条删除（P2，优先级较低）

P2 实现：长按卡片 → 弹出 AlertDialog「删除此条记录？」→ 确认调用 `deleteLog(logId)` → 列表刷新。

> 注意：不用 Dismissible 滑动删除，避免老人误触。

---

## 7. 缴费记录 vs 操作记录边界声明

两者**不合并、不打通**，各自职责清晰：

| 维度 | 操作记录（本页） | 缴费记录（shebaoJiaona Tab） |
|---|---|---|
| 语义 | 「小浙/我做了什么」行为审计 | 「本次缴了什么」交易明细 |
| 存储 | IndexedDB 持久化 | Riverpod 内存（关页丢失） |
| 受众 | 子女 + 老人事后复查 | 老人当次确认 |
| 字段 | 步骤、触发方式、状态 | 险种、档次、金额、缴费年度 |
| 生命周期 | 50 条滚动保留 | 页面会话内 |

**跨引用方式**：PayResultPage 成功页底部加一行灰色提示文字：
「本次操作已记录至「我的」→「操作记录」」（16sp 灰色，仅展示，不跳转）

---

## 8. 实施优先级

### P0 — 演示阻塞（本轮必须完成）

| ID | 改动内容 | 文件 |
|---|---|---|
| P0-1 | mine_page「办事记录」→「操作记录」+ 加副标题 | `mine_page.dart` |
| P0-2 | 新增手工写入触点 × 5（见 §2.3） | `pay_result_page.dart` `yibao_query_page.dart` `pension_query_page.dart` `face_auth_page.dart` `verify_page.dart` |
| P0-3 | LogService 补齐 4 个缺失字段（scene_title / trigger / status / sensitive_actions_redacted） | `log_service.dart` |
| P0-4 | 操作记录页空态加引导文案 | `operation_logs_page.dart` |
| P0-5 | AppBar 加「清空」按钮 + AlertDialog | `operation_logs_page.dart` |

### P1 — 规范对齐（本轮完成）

| ID | 改动内容 | 文件 |
|---|---|---|
| P1-1 | `log_id` 格式改为 `log_YYYYMMDD_HHmmss_NNN` | `log_service.dart` |
| P1-2 | steps[].by 字段强制注入 (`agent`/`user`) | `log_service.dart` |
| P1-3 | 敏感脱敏白名单扩充（见 §4.1） | `log_service.dart` |
| P1-4 | 场景图标白名单扩充到 6 个场景 | `operation_logs_page.dart` |
| P1-5 | 日期分组（今天/昨天/更早） | `operation_logs_page.dart` |
| P1-6 | Steps 字段名可读化渲染（见 §3.4 映射表） | `operation_logs_page.dart` |
| P1-7 | 代理徽章（小浙代办 / 自行操作） | `operation_logs_page.dart` |

### P2 — 体验提升（时间充裕再做）

| ID | 改动内容 |
|---|---|
| P2-1 | 单条删除（长按卡片） |
| P2-2 | 场景过滤 chip（顶部） |
| P2-3 | PayResultPage 跨引用提示文字 |

---

## 9. 验收标准

### AC-1 入口改名（P0-1）
- 输入：打开「我的」页面
- 操作：查看活动区入口文字
- 期望：显示「操作记录」，副标题「小浙帮您做了什么，一目了然」16sp 灰色

### AC-2 手工支付写入（P0-2）
- 输入：用户手动完成医保缴费全流程（yibaoJiaofei → PayConfirm → PayPassword 输入 123456 → PayResult）
- 操作：进入「我的」→「操作记录」
- 期望：列表出现一条记录，scene=yibao_jiaofei，trigger=manual，status=completed，徽章显示「自行操作」

### AC-3 代理写入区分（P0-3）
- 输入：通过小浙语音完成一次医保查询（agent task_done）
- 操作：进入「操作记录」
- 期望：列表出现一条记录，trigger=voice，徽章显示「小浙代办」

### AC-4 清空功能（P0-5）
- 输入：操作记录列表有 ≥1 条记录
- 操作：点 AppBar「清空」→ 确认
- 期望：列表清空，显示空态；点「取消」则无变化

### AC-5 空态（P0-4）
- 输入：IndexedDB 中 operation_logs 无记录
- 期望：页面显示图标 + 「暂无操作记录」+ 「小浙助手帮您办事后，记录会显示在这里」

### AC-6 日期分组（P1-5）
- 输入：操作记录跨越今天和昨天
- 期望：出现「今天」「昨天」分组标题，今天记录在上，昨天在下

### AC-7 Steps 可读化（P1-6）
- 输入：含字段 `{field: jiaofei_niandu, value: 2026}` 的 step
- 操作：展开 steps 区域
- 期望：显示「缴费年度：2026」，不显示原始 key 名

### AC-8 敏感脱敏（P1-3）
- 输入：log 中含身份证 `330102199001012518`
- 期望：展示层显示 `330****2518`，`sensitive_actions_redacted=true`

---

## 10. 超出本次范围（不做）

- 远程共享操作记录给子女（AGENT_SPEC 明确不做）
- 子女专属查看端（AGENT_SPEC 明确不做）
- 操作记录导出 PDF
- 操作记录搜索框

---

*文档完。frontend 可直接按第 8 节优先级顺序实施，PM idle 等待 team-lead 派活。*
