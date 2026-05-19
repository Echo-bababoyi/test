# 验证码登录流程 — 技术现状审查

> **审查范围**：手机号输入 → 获取验证码 → 输入验证码 → 登录成功 全链路
> **审查时间**：2026-05-19
> **审查人**：architect

---

## 1. 整体结论（TL;DR）

**当前的"验证码登录"是一条纯前端 mock 链路，后端没有任何登录/短信相关接口。** 验证码硬编码为 `123456`，手机号字段不参与任何验证或网络请求，登录态只在 Riverpod + 单例 `AuthState` 里翻一个 `bool`。流程在演示层面跑得通，但作为真实"登录"系统几乎是空壳。

此外，Agent 引导验证码登录的 prompt 与前端 element key 不一致，**代理引导走到第 6 步会高亮不到目标按钮**（详见 §4 问题 #4）。这是必须先修的 bug。

---

## 2. 链路逐步现状

### 2.1 入口 1：刷脸登录页（主入口）

`app/lib/pages/login_page.dart`

| 步骤 | 实现 | 说明 |
|---|---|---|
| 输入手机号 | `_phoneController`（行 18） | 无任何校验；值**从不被读取或传递** |
| 条款勾选 | `_agreed`（行 20）| 不控制按钮可用性；只决定点"登录"时是否弹条款浮层 |
| 点击"登录"（`btn_login`，行 19/205） | `onPressed`（行 206-212）| 已勾选 → `context.push(AppRoutes.faceAuth)`；未勾选 → 弹 `_TermsOverlayContent` 浮层，浮层"同意并继续" 也是 `push(AppRoutes.faceAuth)`（行 282） |

**这一页根本不"登录"，按钮语义错位**：它实际上是"前往刷脸"，但按钮文案与 element key 都叫 `登录`/`btn_login`。

### 2.2 入口 2：刷脸页 → 其他方式认证

`app/lib/pages/face_auth_page.dart`

- 默认态点"其他方式认证" → `_showOtherAuthOverlay`（行 138）→ `_OtherAuthContent`（行 1265）
- 弹层里"手机短信验证" → `context.push(AppRoutes.verify)`（行 144）
- "密码登录" `onTap: null`（行 1308），不可用

**用户想直接走验证码登录，必须先经过 LoginPage → FaceAuthPage → 其他方式 → VerifyPage**，三跳。

### 2.3 验证码页

`app/lib/pages/verify_page.dart`

| 步骤 | 实现 | 关键代码 |
|---|---|---|
| 手机号输入 | `_phoneController`（行 20）—— **新 controller，不接 LoginPage 的值** | 用户要再输一遍 |
| 手机号校验 | `_phoneValid`：`length == 11 && startsWith('1')` | 行 33-35 |
| 错误提示 | `_phoneInvalid` 红字 "请输入11位手机号（首位为1）" | 行 167-174 |
| 验证码输入 | `_codeController` | 无格式校验 |
| 获取验证码 | `_sendCode()` —— **不发任何请求**，仅启动 60s 倒计时 | 行 61-74 |
| 验证码正确性 | `_canLogin = _codeController.text == '123456'` —— **硬编码** | 行 39 |
| 确认登录 | `_confirmSmsCode` → `SystemDialog` 二次确认 → `loginProvider.login('用户')` + `context.go(AppRoutes.elderHome)` | 行 76-88 |

**`btn_send_code`、`btn_verify_login`、`input_phone`、`input_verify_code` 已注册到 `AgentElementRegistry`**（行 24-27），可被代理高亮 / 代填。

### 2.4 登录态写入

`app/lib/core/state/app_state.dart`

```dart
class LoginNotifier extends Notifier<LoginState> {
  void login(String name) {
    state = LoginState(isLoggedIn: true, userName: name);
    AuthState.instance.login(name: name);
  }
}
```

- 写入的 `userName` 全部硬编码为字符串 `'用户'`（face_auth_page.dart:38、verify_page.dart:84）
- 不存 token、不存手机号、不存过期时间；纯进程内 bool

### 2.5 后端

`backend/main.py` 暴露：

- `GET /health`
- `GET /api/status`
- `WS /ws/session/{session_id}`

**没有 `/api/auth/*`、`/api/sms/*`、`/api/login` 等任何登录/短信接口。** WS 不校验登录；`session_id` 由前端任意指定。

唯一"短信"语义在 `backend/tools/read_sms.py`：

```python
@tool(stop_after_tool_call=True)
def read_sms(voice_hint: str = "需要读取您的短信验证码，可以吗？") -> dict:
    return {"code": "123456", "voice_hint": voice_hint}
```

这是 Agno 工具（代理代读用），返回**硬编码 123456**，正好与前端 `_canLogin` 的硬编码吻合。它不是登录接口，是代理流程里的"读用户手机收到的验证码"模拟。

---

## 3. PRD / ARCHITECTURE 设计原意（对照）

- **PRD §场景 2**：L2 代理代读代填验证码，**用户亲手按"登录"按钮**（确定性操作）。
- **ARCHITECTURE 原则 2**：确定性按钮（"登录"等）**不注册为代理工具**，Agent 物理上无法调用。
- **ARCHITECTURE 原则 3**：`read_sms`、`fill_field_sensitive` 走 `requires_confirmation=True`，HITL 一事一授。
- **`prompts/scene_login_verify.txt` 步骤**：navigate → highlight phone → highlight send → read_sms (HITL) → fill verify code → highlight 登录按钮。

设计原意是清晰的：**用户实际的"按登录"动作仍由用户亲手完成；代理只读短信 + 填验证码 + 高亮指引。** 当前前端架构能配合这套原则——但下面有几个具体问题阻碍它跑通。

---

## 4. 发现的问题（按严重程度排序）

### 🔴 P0 — 必须修

**#1 Agent prompt 引用了不存在的 element key（代理引导链断裂）**
- `backend/prompts/scene_login_verify.txt:10` 第 6 步：`cmd_highlight(element_key="btn_login", ...)`
- VerifyPage 的"确认"按钮注册名是 **`btn_verify_login`**（verify_page.dart:27）
- `btn_login` 只存在于 **LoginPage（手机号入口页）**（login_page.dart:19）
- **影响**：代理走完验证码代填后，第 6 步高亮"登录"会作用在错误页面 / 找不到元素；用户失去最后一步引导。
- **修复**（开发动手）：`backend/prompts/scene_login_verify.txt:10` 把 `element_key="btn_login"` 改为 `element_key="btn_verify_login"`。

**#2 后端没有真实的发码 / 验码接口**
- 整个登录链路没有任何后端校验，验证码 `123456` 写死两份（前端 + 工具）。
- **影响**：项目自我定位是"信息服务 APP"原型，但登录从安全角度看完全不存在。论文/答辩可被诘问"代理代填的代码是真的吗"。
- **修复方向**（需 PM 决策范围）：
  - 选项 A — 保持 mock，但在文档中明确标注"演示用 mock，真实部署需对接政务短信网关"，并把硬编码集中在一处（建议 `backend/config.py` 暴露 `MOCK_SMS_CODE`）。
  - 选项 B — 引入 `POST /api/auth/sms/send` + `POST /api/auth/sms/verify`，后端用内存 dict 存 `{phone: (code, expire_at)}`，60s 限流，5min 过期；`read_sms` 工具内部去调本地 mock，让前后端走"真请求"。

### 🟠 P1 — 体验/语义阻塞

**#3 LoginPage 的"登录"按钮语义错位**
- 文案/key 都叫"登录/btn_login"，行为是"跳转到刷脸"。
- 用户输入手机号也没用——不读、不传、不校验。
- **修复方向**：要么把 LoginPage 退化为"刷脸认证入口"（去掉手机号输入框，按钮改"开始刷脸"），要么把手机号通过 query 参数传到 FaceAuth/Verify。建议前者，因为 PRD 场景 1 就是从首页直接进刷脸，根本不需要手机号。

**#4 LoginPage 的手机号不会传到 VerifyPage**
- LoginPage `_phoneController` 与 VerifyPage `_phoneController` 是两个独立 controller，用户被迫输两次。
- **修复方向**（与 #3 联动）：要么 VerifyPage 通过 `GoRouter` 的 `extra` / query 接收来源页手机号；要么干脆只在 VerifyPage 输入。

**#5 登录后强制跳 elderHome，无视 modeProvider**
- `face_auth_page.dart:39` 与 `verify_page.dart:85` 都写死 `context.go(AppRoutes.elderHome)`。
- **影响**：标准版用户从底部"我的"或登录入口走登录，登录成功后被强制带去长辈版。这与"两版独立"的产品定位冲突。
- **修复**（开发动手）：
  - `face_auth_page.dart:39` 改为：
    ```dart
    final mode = ref.read(modeProvider);
    context.go(mode == AppMode.elder ? AppRoutes.elderHome : AppRoutes.home);
    ```
  - `verify_page.dart:85` 同改。

**#6 登录身份完全丢失**
- `loginProvider.login('用户')` 在两处都硬编码——不保存手机号、没有 userId。
- **修复**：登录调用至少要传输入的手机号：`login(_phoneController.text)`。如果引入后端接口（#2 选项 B），则保存后端返回的 userId。

### 🟡 P2 — 健壮性 / 体验细节

**#7 `_canLogin` 仅做相等比对，没有"验证码错误"反馈**
- `verify_page.dart:39`：`_canLogin = code == '123456'`。错的话按钮永远灰。
- 用户感受不到"输错了"，只看到按钮不亮。
- **修复**：移除按钮 disabled 逻辑；点击时若不匹配，弹 SnackBar "验证码错误，请重新输入"，并清空 `_codeController`。

**#8 SystemDialog 二次确认冗余**
- 用户输入正确验证码 → 点"确认" → 弹"验证码已验证，即将完成登录"对话框 → 再点"确认"才登录。多此一举。
- **修复**：`verify_page.dart:76-88` 去掉 `SystemDialog.show`，直接 `login + go`。

**#9 倒计时不持久化、不防刷新**
- `_countdown` 是 `_VerifyPageState` 字段；离开页面、刷新都归零，可无限制刷验证码。
- 真实场景里这是限流漏洞。mock 阶段优先级低，但接 #2 选项 B 时必须服务端限流。

**#10 无验证码错误分支 UI**
- PRD 场景 2 默认验证码"代填一遍就对"。没有"验证码已过期"/"超过 5 次"/"账号被锁"的展示。原型阶段可以接受，但论文章节"健壮性"会缺料。

**#11 "登录"按钮始终可点击 → 不校验勾选**
- login_page.dart:206-212：按钮一直可点，靠 `_agreed` 分支去弹浮层。
- 这是适老化刻意改造（R7：不灰按钮，弹层引导），不算 bug。会话 9 feedback 也确认过；保留。

### 🔵 P3 — 后端工具一致性

**#12 `read_sms` 没有手机号入参**
- `backend/tools/read_sms.py:5`：签名仅 `voice_hint`，返回固定 `code: 123456`。
- 一旦 #2 选项 B 落地，`read_sms` 应改成 `read_sms(phone: str)` 去查后端发码记录；目前的签名不利于后续演进。

---

## 5. 建议的修复顺序

| 顺序 | 项 | 谁动手 | 工作量 |
|---|---|---|---|
| 1 | #1 Agent prompt key 改 `btn_verify_login` | 开发（1 行） | <5 min |
| 2 | #5 登录后跳转按 modeProvider 分流（2 处） | 开发（4-6 行） | 10 min |
| 3 | #8 删除 SystemDialog 二次确认 | 开发 | 5 min |
| 4 | #6 `login(_phoneController.text)`（2 处） | 开发 | 5 min |
| 5 | #3 + #4 LoginPage 语义改造（去掉手机号输入 / 按钮改"开始刷脸"） | 需 PM 决策 → 开发 | 30 min |
| 6 | #7 验证码错误反馈 | 开发 | 15 min |
| 7 | #2 后端真实发码/验码接口（如要做） | 需 PM 决策 → 后端 + 工具 + 前端 | 2-3h |

**建议本轮先做 1-4，5 之前找 PM 拍板，6 与 5 一起做，7 看是否纳入毕设演示范围。**

---

## 6. 风险与权衡

- **保留 mock 还是上真发码？** 答辩演示场景下 mock 完全够用；但论文"系统实现"章节如果不提"真实发码已实现/未实现"会被质疑。建议至少做"#2 选项 B（本地 mock 端点）"，让架构图里 `/api/auth/*` 不是空白。
- **手机号字段去留？** 现在的 LoginPage 既有手机号输入又紧跟刷脸（不需要手机号），是设计冗余。要么删字段，要么改为"刷脸前先识别用户身份"——但这又需要后端"按手机号查用户"接口。建议删字段最简洁，与 PRD 场景 1 一致。
- **代理代填登录按钮是否要放开？** PRD/ARCH 明确要求用户亲手按。当前实现遵循该原则。建议保留，不要因便利性破坏"确定性操作代理止步"。

---

## 附：关键文件清单

- `app/lib/pages/login_page.dart`（413 行）— 入口页 + 条款浮层
- `app/lib/pages/face_auth_page.dart`（1314 行）— 刷脸 + 其他方式入口
- `app/lib/pages/verify_page.dart`（256 行）— 验证码页
- `app/lib/core/state/app_state.dart`（51 行）— loginProvider / modeProvider
- `app/lib/services/auth_state.dart`（17 行）— AuthState 单例
- `app/lib/router.dart` 行 28-30, 95-106 — 路由声明
- `backend/main.py`（48 行）— FastAPI 入口，无 auth 接口
- `backend/tools/read_sms.py`（7 行）— mock 代读工具
- `backend/prompts/scene_login_verify.txt`（17 行）— 代理引导 prompt
- `docs/PRD.md` §场景 2（行 118-138）— 设计原意
- `docs/ARCHITECTURE.md` 原则 2/3、§场景能力矩阵 — 设计约束
