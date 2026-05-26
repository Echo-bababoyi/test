# 修复方案：登录流程三个 UX 问题

> 作者：architect｜日期：2026-05-26｜状态：待开发实施（含 2 个需 PM 拍板的产品决策）

覆盖：
- **问题 1**：跳页前要有"预告"（"我带您去 XX 页"再跳）
- **问题 2**：一步直达目标登录页，不要穿越 我的→去登录→登录页→刷脸页→浮层→验证码页 一长串
- **问题 3**：刷脸登录后信任卡仍没弹

---

## ⚠️ 两个需 PM 先拍板的产品决策

> 问题 1/2 的技术实现依赖这两个决策，建议先确认再动手。

**D1：登录场景在引导级强制开放 cmd_navigate（代跳页）。**
现状：`AGENT_SPEC` 明确"引导级不可跳页"。但**登录时用户必然未登录、trust 必然是 guide**（`effectiveTrust = isLoggedIn ? trust : 'guide'`），所以登录场景永远拿不到 cmd_navigate——这正是问题 2 的根因。要让登录"一步直达"，**只能**像 `login_verify` 现在强制 `read_sms` 那样，用 `_SCENE_FORCE_TOOLS` 给登录场景强开 cmd_navigate。
- 推荐：**同意强开**。cmd_navigate 是纯 UI 代跳、非破坏性、无敏感数据，风险远低于已强开的 read_sms。养老金场景也已用 cmd_navigate 验证体验更好。

**D2：直达目标登录页会跳过 `/login` 页的"同意条款"勾选与手机号预输入。**
现状：SMS 验证码登录入口埋在 `/login → /login/face → 浮层 → /login/verify`，且 `chk_agree_terms` 只在 `/login` 页。直达 `/login/verify`（或 `/login/face`）会跳过 `/login`。经核查 `verify_page._confirmSmsCode` / `face_auth_page._onAllSuccess` **本来就不校验条款勾选**（`/login/verify` 页也无条款元素），即 App 现有设计下验证码/刷脸登录本就不强制条款——直达不会绕过任何 App 实际强制项。
- 待 PM 确认：合规上验证码/刷脸登录是否需要显式条款同意？若需要，应在目标页补条款元素，而非靠 `/login` 中转。

---

# 问题 2（+ 问题 1）：一步直达 + 预告

> 依赖 D1。改动 = 后端工具挂载 + 两个 login prompt 重写 + executor 前缀加预告规则。

## 后端文件 1：`backend/agent_core.py`

### 1.1 SCENE_TOOLS 给两个登录场景加 cmd_navigate（33-41 行）

当前：
```python
SCENE_TOOLS = {
    "login_face":    [cmd_highlight, cmd_say, cmd_wait_user],
    "login_verify":  [cmd_highlight, cmd_say, cmd_wait_user, read_sms, fill_field_normal],
    "yibao_jiaofei": [cmd_navigate, cmd_highlight, cmd_say,
                      fill_field_normal, fill_field_sensitive, cmd_wait_user],
    "pension_query": [cmd_navigate, cmd_highlight, cmd_say, cmd_wait_user],
    "yibao_query":   [cmd_navigate, cmd_highlight, cmd_say,
                      fill_field_normal, cmd_press_button],
}
```
把前两行改为（加 `cmd_navigate`）：
```python
    "login_face":    [cmd_navigate, cmd_highlight, cmd_say, cmd_wait_user],
    "login_verify":  [cmd_navigate, cmd_highlight, cmd_say, cmd_wait_user, read_sms, fill_field_normal],
```

### 1.2 _SCENE_FORCE_TOOLS 给两个登录场景强开 cmd_navigate（55 行）

当前：
```python
_SCENE_FORCE_TOOLS = {"login_verify": {"read_sms", "fill_field_normal"}}
```
改为：
```python
_SCENE_FORCE_TOOLS = {
    "login_face":   {"cmd_navigate"},
    "login_verify": {"cmd_navigate", "read_sms", "fill_field_normal"},
}
```
> 校验：`get_scene_tools("login_verify","guide")` = scene_max ∩ (guide ∪ forced) → 含 cmd_navigate ✓。与已交付的 C 修复无冲突：env block 走 `get_scene_tools`，登录场景现在 `'cmd_navigate' in available` 为 True，会正常输出"可通过 cmd_navigate 直接跳转"，不会再触发"无跳页权限"分支。

### 1.3【问题 1】executor 前缀加"跳页前预告"全局规则（157 行后）

当前 _EXECUTOR_PREFIX 末段（152-158 附近）含：
```python
- cmd_navigate 是代理代跳，跳完通常会立刻接 cmd_say + cmd_highlight + cmd_wait_user，整组算一个 step（不要在 cmd_navigate 后单独 cmd_wait_user）。
```
在其后**新增一条**：
```python
- 调用 cmd_navigate 代跳页前，必须先用 cmd_say 预告要去哪（如"好的，我带您去 XX 页"），不要无声跳页。预告 cmd_say + cmd_navigate + cmd_wait_user 三个工具算同一个 step 一次性发出。
```

## 后端文件 2：`backend/prompts/scene_login_verify.txt`（整体重写为 6 步）

全文替换为：
```
【目标】带用户完成验证码登录。先代跳到验证码登录页，再引导用户输手机号、发验证码；验证码由您代读代填（需用户一次授权），最后引导用户亲手点"登录"。

【可用工具】
- cmd_say（语音播报 + 聊天气泡，引导话术唯一渠道）
- cmd_navigate（代跳页，纯 UI 操作，不发声）
- cmd_highlight（高亮页面元素，纯 UI 操作，不发声不入气泡）
- read_sms（读取本次短信验证码，需用户授权；调用后自动暂停弹授权卡，用户同意后返回形如 {"code": "……"} 的结果）
- fill_field_normal（把指定值填入页面输入框）
- cmd_wait_user（等用户操作 / 等跳页后目标页加载）
绝不能调用 fill_field_sensitive / cmd_press_button —— 这些工具未挂载，调用会失败。

【标准操作流程】

第 1 步（用户不在 /login/verify 时；已在则跳过，直接第 2 步）—— 预告 + 代跳
  cmd_say(voice_hint="好的，我带您去验证码登录页")
  cmd_navigate(target_route="/login/verify")
  cmd_wait_user(reason="等验证码登录页加载完成")
  说明：跳页后页面要时间加载，必须用 cmd_wait_user 等就绪；页面好了系统自动续传。本步预告 + 代跳 + 等待算一个 step。

第 2 步（/login/verify）—— 引导输手机号
  cmd_say(voice_hint="请输入您的手机号")
  cmd_highlight(element_key="input_phone", duration_ms=8000)
  cmd_wait_user(reason="等用户输入手机号")

第 3 步（/login/verify）—— 引导发验证码
  cmd_say(voice_hint="请点'发送验证码'按钮")
  cmd_highlight(element_key="btn_send_code", duration_ms=8000)
  cmd_wait_user(reason="等用户点发送验证码")

第 4 步（用户已点"发送验证码"）—— 代读验证码
  cmd_say(voice_hint="验证码马上到，我帮您读出来填好，您点一下'可以'就行")
  read_sms()
  说明：read_sms 是本步最后一个工具，调用后自动暂停弹授权卡。不要在 read_sms 后再调 cmd_wait_user。

第 5 步（用户授权通过后）—— 代填验证码
  fill_field_normal(field_key="input_verify_code", field_label="验证码", value=<把 read_sms 返回结果里的 code 字段原样填进来>)
  说明：read_sms 返回结果里 code 字段就是本次验证码，原样作为 value 传入，绝不要自己编造、修改或猜测。

第 6 步（验证码已填好）—— 引导点登录（最后一步）
  cmd_say(voice_hint="填好啦，请您点'登录'")
  cmd_highlight(element_key="btn_verify_login", duration_ms=8000)
  说明：最后一步，不要调 cmd_wait_user，直接输出【完成回复】。

【起点判断规则】
查看【环境信息】里"用户当前在"字段：
- 不在 /login/verify（含 /elder、/my、/login、/login/face 等任意页）→ 第 1 步（预告 + cmd_navigate 直达）
- /login/verify → 第 2 步

【用户在第 4 步拒绝授权（点了"不用了"）时的回退】
  不要再调 read_sms / fill_field_normal，改为引导用户自己填：
  cmd_say(voice_hint="好的，请您把短信里的验证码填到这里")
  cmd_highlight(element_key="input_verify_code", duration_ms=8000)
  cmd_wait_user(reason="等用户自己输入验证码")
  之后照常执行第 6 步引导点登录。

【准则】
- cmd_say 是唯一会播放语音 + 入聊天气泡的工具；cmd_navigate / cmd_highlight / read_sms / fill_field_normal 都是纯 UI / 数据操作，不发声不入气泡。要让用户听到 + 看到的话必须走 cmd_say(voice_hint=...)。
- 引导用户点按元素的标准模式：先 cmd_say(voice_hint="<人话指令>")，紧跟 cmd_highlight(element_key=<实际key>, duration_ms=8000)，一组两个工具缺一不可。
- 手机号由用户亲手输入；"发送验证码""登录"两个按钮都由用户亲手点击，绝不代劳。
- 验证码：用户授权后由您 read_sms 读取 + fill_field_normal 代填；拒绝授权则走上面的回退分支。
- 【完成回复】所有步骤执行完毕后，response.content 输出且仅输出：已引导您完成验证码登录步骤，请按提示操作
```

## 后端文件 3：`backend/prompts/scene_login_face.txt`（整体重写为 5 步）

全文替换为：
```
【目标】带用户完成刷脸登录准备。先代跳到刷脸认证页，再引导用户开始刷脸、授权摄像头、进入活体检测。

【可用工具】
- cmd_say（语音播报 + 聊天气泡，引导话术唯一渠道）
- cmd_navigate（代跳页，纯 UI 操作，不发声）
- cmd_highlight（高亮页面元素，纯 UI 操作，不发声不入气泡）
- cmd_wait_user（等用户操作 / 等跳页后目标页加载）
绝不能调用 fill_field_normal / fill_field_sensitive / cmd_press_button / read_sms —— 这些工具未挂载，调用会失败。

【标准操作流程】

第 1 步（用户不在 /login/face 时；已在则跳过，直接第 2 步）—— 预告 + 代跳
  cmd_say(voice_hint="好的，我带您去刷脸登录页")
  cmd_navigate(target_route="/login/face")
  cmd_wait_user(reason="等刷脸认证页加载完成")
  说明：跳页后等页面就绪，系统自动续传。本步预告 + 代跳 + 等待算一个 step。

第 2 步（/login/face）
  cmd_say(voice_hint="请点'开始刷脸认证'按钮")
  cmd_highlight(element_key="btn_face_login", duration_ms=8000)
  cmd_wait_user(reason="等用户点开始刷脸认证")

第 3 步（/login/face 请求刷脸浮层弹出）
  cmd_say(voice_hint="请点'同意并继续'按钮")
  cmd_highlight(element_key="btn_face_request_agree", duration_ms=8000)
  cmd_wait_user(reason="等用户点同意刷脸认证")

第 4 步（系统摄像头权限弹窗弹出）
  cmd_say(voice_hint="请点'使用应用时允许'打开摄像头")
  cmd_highlight(element_key="btn_camera_permission_allow", duration_ms=8000)
  cmd_wait_user(reason="等用户授权摄像头")

第 5 步（活体检测开始，最后一步）
  cmd_say(voice_hint="请正对屏幕，跟着提示眨眼、左右摇头")
  说明：最后一步，不要调 cmd_wait_user，直接输出【完成回复】。

【起点判断规则】
- 不在 /login/face（含 /elder、/my、/login 等任意页）→ 第 1 步（预告 + cmd_navigate 直达）
- /login/face → 第 2 步

【准则】
- cmd_say 是唯一会播放语音 + 入聊天气泡的工具；cmd_navigate / cmd_highlight 都是纯 UI 操作，不发声不入气泡。要让用户听到 + 看到的话必须走 cmd_say(voice_hint=...)。
- 引导用户点按元素的标准模式：先 cmd_say(voice_hint="<人话指令>")，紧跟 cmd_highlight(element_key=<实际key>, duration_ms=8000)，一组两个工具缺一不可。
- 您绝不替用户点按 / 勾选（活体检测的眨眼转头由用户本人完成）。
- 【完成回复】所有步骤执行完毕后，response.content 输出且仅输出：已引导您完成刷脸登录准备，请按提示操作
```

> 启动期 `_validate_prompts_against_knowledge` 校验：两份新 prompt 引用的 element_key（input_phone / btn_send_code / input_verify_code / btn_verify_login / btn_face_login / btn_face_request_agree / btn_camera_permission_allow）与 target_route（/login/verify、/login/face）均已在 `backend/knowledge/pages.py` 中定义 ✓，不会触发启动校验报错。

---

# 问题 3：刷脸登录后信任卡不弹

## 根因（确诊）

1. `face_auth_page._onAllSuccess`(face_auth_page.dart:51-62) **确实**调了 `login('用户')`(52) 翻转 loginProvider，且 `context.go(/elder)`(61) 在其后——时序正确，`ref.listen` 也能捕获到这次翻转（ElderHome 在栈底存活，监听订阅有效）。
2. **真正的 bug 是消费时序**：`/elder` 用 `NoTransitionPage`(router.dart:102)，但登录页用 `_fadePage`(106/110/114)。`go(/elder)` 后，正在淡出的 FaceAuthPage 仍占据栈顶，导致 ElderHome 的 `ModalRoute.isCurrent` 在淡出动画结束前一直是 **false**。而当前实现(elder_home.dart build 内)只在**那一次** build 里判 `_trustChoicePending && isCurrent`——此刻 isCurrent=false → 跳过；动画结束后 ElderHome 变 current 但**没有任何东西触发它重建**，于是永远不再消费 pending → 卡不弹。
3. 次要隐患：`_maybeShowFirstTrustChoice` 在**弹卡前**就把 `firstChoiceShown=true` 持久化(elder_home.dart:48)。若任何一次触发了它但卡没真正显示（如本 bug），该标志会卡死为 true，**之后再登录也永不弹**。（这也解释了为何日志有 `trust_changed→full` 却没卡：full 是 localStorage 里早先持久化的值，经 ensureSession/wake 同步上去的，与卡无关。）

## 修复（前端，`app/lib/pages/elder_home.dart`）

### 3.1 build() 内：去掉一次性 isCurrent 判定，改由 ref.listen 启动逐帧轮询

当前 build 顶部（已交付版本）：
```dart
  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginProvider, (prev, next) {
      if (next.isLoggedIn && !(prev?.isLoggedIn ?? false)) {
        _trustChoicePending = true;
      }
    });
    if (_trustChoicePending && (ModalRoute.of(context)?.isCurrent ?? false)) {
      _trustChoicePending = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowFirstTrustChoice());
    }
    return Scaffold(
```
改为：
```dart
  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginProvider, (prev, next) {
      if (next.isLoggedIn && !(prev?.isLoggedIn ?? false)) {
        _scheduleTrustChoice();
      }
    });
    return Scaffold(
```

### 3.2 新增轮询方法（放在 `_maybeShowFirstTrustChoice` 附近）

```dart
  void _scheduleTrustChoice() {
    if (_trustChoicePending) return;        // 防重入（一次登录只起一个轮询）
    _trustChoicePending = true;
    _pollTrustChoice(0);
  }

  void _pollTrustChoice(int attempt) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !ref.read(loginProvider).isLoggedIn) {
        _trustChoicePending = false;
        return;
      }
      // 等 ElderHome 真正成为栈顶（登录页淡出动画结束）再弹，避免被遮挡
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        _trustChoicePending = false;
        _maybeShowFirstTrustChoice();
      } else if (attempt < 240) {           // ~4s 上限，覆盖 verify 的 1.5s 延迟跳转 + 淡出
        _pollTrustChoice(attempt + 1);
      } else {
        _trustChoicePending = false;        // 兜底放弃，不无限轮询
      }
    });
  }
```
> 为什么用轮询：登录页（fade）淡出期间 ElderHome 不是 current，且 go(/elder) 不保证再次触发 ElderHome.build（NoTransitionPage + const 复用）。轮询每帧检查 isCurrent，命中即弹，是对"登录→跳首页"时序最鲁棒的钩子。`verify_page` 登录后延迟 1.5s 才 go（verify_page.dart:140-143），轮询期间空转无害，240 帧上限足够覆盖。

### 3.3 修复 firstChoiceShown 卡死：成功选择后再持久化

当前 `_maybeShowFirstTrustChoice`(elder_home.dart:42-68)：
```dart
  Future<void> _maybeShowFirstTrustChoice() async {
    if (!mounted) return;
    final isLoggedIn = ref.read(loginProvider).isLoggedIn;
    if (!isLoggedIn) return;
    if (AgentSettingsService.instance.firstChoiceShown) return;

    AgentSettingsService.instance.firstChoiceShown = true;

    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FirstTrustChoiceSheet(),
    );

    if (picked != null && mounted) {
      AgentSettingsService.instance.trustLevel = picked;
      AgentSession.instance.sendTrustChanged(picked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已设为「${_trustTitleFor(picked)}」'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
```
改为（去掉弹卡前置真、改为成功选择后再置真；加 in-memory 防重入 `_trustSheetShowing`）：
```dart
  Future<void> _maybeShowFirstTrustChoice() async {
    if (!mounted || _trustSheetShowing) return;
    if (!ref.read(loginProvider).isLoggedIn) return;
    if (AgentSettingsService.instance.firstChoiceShown) return;

    _trustSheetShowing = true;
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FirstTrustChoiceSheet(),
    );
    _trustSheetShowing = false;

    if (picked != null && mounted) {
      AgentSettingsService.instance.firstChoiceShown = true;   // 成功选择后才持久化
      AgentSettingsService.instance.trustLevel = picked;
      AgentSession.instance.sendTrustChanged(picked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已设为「${_trustTitleFor(picked)}」'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
```
加成员（`_trustChoicePending` 已存在，新增一个）：
```dart
  bool _trustSheetShowing = false;
```
> 卡是 isDismissible:false / enableDrag:false，正常只能靠选择关闭（picked 非 null），所以把 firstChoiceShown 移到选择成功后是安全的，且杜绝"标志卡死再不弹"。

---

# 验证步骤

> 重测前先清掉可能卡死的本地标志：浏览器 DevTools → Application → Local Storage 删除 `xiaozhe_first_choice_shown`（及调试期想重置时删 `xiaozhe_trust_level`）。

### 用例 1【问题 1+2，验证码登录】
1. 登出态长辈版首页，打开小浙，说"帮我登录"→ 选"验证码登录"。
2. **预期**：小浙先说"好的，我带您去验证码登录页"（预告）→ **一步直接跳到 `/login/verify`**，中间不再经过 我的 / 登录页 / 刷脸页 / 浮层。
3. 后续仅引导：输手机号 → 发验证码 → 授权读码（卡）→ 自动填码 → 点"登录"。后端日志该场景应出现 `cmd_navigate {'target_route': '/login/verify'}`，无 `cmd_navigate not found`。

### 用例 2【问题 1+2，刷脸登录】
1. 登出态说"刷脸登录"。
2. **预期**：预告"我带您去刷脸登录页"→ 一步跳 `/login/face`，再引导 开始刷脸 → 同意并继续 → 允许摄像头 → 活体检测。

### 用例 3【问题 3，信任卡必弹】
1. 清掉 `xiaozhe_first_choice_shown`。登出态走刷脸登录至成功 → 自动 `go(/elder)`。
2. **预期**：淡出动画结束、回到首页后**弹出信任选择卡**；选完后 `已设为「…」` snackbar + 后端日志 `trust_changed → <级别>`。
3. 同样验证"验证码登录成功（1.5s 后跳首页）"也能弹卡（轮询覆盖延迟）。

### 回归
- 已登录用户冷启动直接进首页（initState 老路径）仍能弹卡（若 firstChoiceShown 未置）。
- 已登录态、聊天里再次触发登录类意图不应重复弹卡（firstChoiceShown=true 守卫）。
- 养老金 / 医保等非登录场景行为不变。
