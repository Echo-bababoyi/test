# 三级权限方案 v0.6（PM × 架构师 联合稿）

> **共识方**：架构师(@architect)× 产品经理(@pm)
> **日期**：2026-05-20
> **依据**：用户论文新定义 + AGENT_SPEC.md v1.0 差距分析 + 用户对决策 1/2 的两轮调整 + 决策 4 拒绝/跳过语义补充 + 引导级"不实际操作"边界澄清
> **流程**：6 轮收敛（v0.1 → v0.2 → v0.3 → v0.4 → v0.5 → v0.6）
> **v0.6 主要变更**：
> - **引导级工具集**`{cmd_highlight, cmd_say}`（去掉 cmd_navigate） —— 用户澄清「不实际操作」包含页面跳转
> - 引导级下代理只能高亮元素 + 说话，**连页面都不替用户跳**，由用户自己点
> - 行为矩阵、_LEVEL_TOOLS、相关用户故事（S4/S7/S8）已同步对齐

---

## § 1 背景与目标

### 1.1 来源
用户提供论文「三级权限」精确定义，与现行 `docs/AGENT_SPEC.md` v1.0 § 3.3「不存在用户可见的权限等级」**直接冲突**。本方案以**论文定义为权威**，更新 spec 至 v1.1。

### 1.2 论文定义（权威）
- **引导级**：代理仅提供步骤提示与语音引导，**不实际操作**
- **半委托级**：代理代填表单**普通字段**，**不提交**；**敏感字段**（身份证号、短信验证码等）需**单独逐次授权**
- **全委托级**：代理完成完整流程，**可填部分敏感字段**；**不可逆操作**（登录/提交/支付）和**密码类凭证**（登录密码/支付密码）仍由用户亲手 —— **硬性底线**

### 1.3 目标
- 用户可显式选择三级权限
- **未登录强制引导级**；**登录后首次进主页弹卡让用户选**；**关闭不选 = 引导级**
- 不破坏已有「三层防御 + 草稿箱 9 项修复 + 适老化字号规范」
- 工作量 ≤ 15h（一前端 + 一后端并行半天）

### 1.4 三道兜底机制

最终代理行为由三道独立约束 **AND** 决定：

```
effective_level = min(
    用户在设置页选的级别(或弹卡选的, 或默认 guide),  # 设置兜底
    登录态联动级别,                                  # 未登录 → guide
    场景固有上限                                      # 场景兜底
)
```

举例：
- 已登录 + 弹卡选半委托 + 医保缴费 → semi（含 cmd_navigate）
- 已登录 + 弹卡关闭 + 医保缴费 → guide（默认；只能 cmd_highlight + cmd_say）
- 已登录 + 全委托 + 刷脸登录 → guide（场景上限 L1；无 cmd_navigate）
- 未登录 + 任何场景 → guide（登录态联动；无 cmd_navigate）

### 1.5 v0.4 设计哲学：「主动授权扩权 + 默认保守」

为什么默认引导级而不是全委托？
- 论文创新点是「权限受控」，**默认保守 + 显式扩权**比「默认放权 + 显式收回」更贴合该精神
- 老人首次登录立即看到三选项，**主动选择**比被动接受默认值更尊重用户判断
- 用户随时可在设置页改；不愿做选择即沿用最安全的引导级

---

## § 2 用户故事 & 验收标准

**S1（登录后首次弹卡，v0.4 重写）** 用户登录成功跳转主页（`/elder`）→ 自动弹出三级权限选择 modal
**验收**：localStorage 中 `xiaozhe_first_choice_shown == false` 时触发；弹卡阻挡背景交互（barrier dimmed），顶部右上角有「✕」关闭按钮

**S1a** 用户在弹卡中选中某级 → 立即生效 + 关闭弹卡 + Toast「已设为 XX」
**验收**：localStorage 写入 `xiaozhe_trust_level` 和 `xiaozhe_first_choice_shown=true`；下次登录不再弹

**S1b** 用户直接关闭弹卡不选 → 默认引导级生效 + 不再弹
**验收**：localStorage 不写 `xiaozhe_trust_level`（保持默认 `guide`），但写 `xiaozhe_first_choice_shown=true`；下次登录不再弹

**S2** 用户在**设置页**从某级升级到更高级 → 弹 SystemDialog 二次确认
**验收**：点「取消」回滚选中态；点「确认切换」localStorage 更新 + Toast「已切换」
（注：S1 的首次弹卡选级**不弹二次确认**，因为本身就是显式选择）

**S3（全委托同意路径）** 用户在全委托级 + 医保缴费 → 代理在第一个敏感字段步骤前弹**总授权**卡，用户**同意** → `_task_sensitive_authorized=true` → 本任务后续 sensitive 工具直接执行
**验收**：同意后本任务内不再弹卡；任务结束（task_done 或取消）后下次同类任务重新问

**S3a（全委托拒绝/跳过路径，v0.5 新增）** 用户在全委托级 + 任务中首次遇到敏感字段弹卡，用户**拒绝** → 该字段**跳过**（前端不收到 cmd_fill_field，字段保持空）→ 代理用 `cmd_say` 提示用户自填 → 任务**不取消**，继续后续步骤；**下一个**敏感字段再次弹卡
**验收**：`_task_sensitive_authorized` 保持 `false`；前端**未收到**该字段的 cmd_fill_field；下一个 sensitive 工具触发新一次 permission_request；execute_task 不终止

**S4（v0.6 修订）** 用户在引导级 + 医保缴费 → 代理只调 `cmd_highlight + cmd_say` → 每步高亮目标元素 + 语音提示，**不代填、不代跳**
**验收**：execute_task 全程**零 cmd_fill_field、零 cmd_navigate、零 cmd_press_button**；所有字段值和页面跳转都由用户手动完成

**S5** 用户任意级别 + 任意场景 → 代理永远不代按确定性按钮（登录/提交/支付）
**验收**：`cmd_press_button is_deterministic=False` 强制；前端守卫 `if (isDeterministic) return;`；密码字段在白名单永不填

**S6** 用户从全委托降级到引导级 → **不弹确认**，直接生效
**验收**：localStorage 立即更新 + Toast「已切换」，无 dialog

**S7（场景上限兜底，v0.6 修订）** 已登录 + 全委托 + 进入刷脸登录场景（场景固有上限 L1）→ 行为等同引导级，**不暴露"被降级"提示**
**验收**：`get_scene_tools("login_face", "full")` 返回 `{cmd_highlight, cmd_say}`（场景的 cmd_navigate 与引导级取交集后被裁掉）；UI 表现与"用户选 L1"一致

**S8（未登录兜底）** 未登录用户唤醒小浙 → 任何场景行为强制引导级，**与设置页选择无关**
**验收**：`agent_wake` payload 中 `trust_level == "guide"`；点悬浮窗**正常打开代理对话**，不弹权限选择卡片

**S9（设置页未登录态）** 未登录用户进入小浙设置页 → 三张权限卡**可见但灰显** + 顶部提示「登录后可调整小浙的工作方式」
**验收**：三张卡 InkWell.onTap 为 null；视觉 40% opacity；顶部黄色提示横条带「去登录」按钮 → 跳转 `/login`

---

## § 3 三级行为矩阵

| 能力 | 引导级 L1（**默认**） | 半委托级 L2 | 全委托级 L3 |
|---|:-:|:-:|:-:|
| 语音对话/理解 | ✓ | ✓ | ✓ |
| 复述确认 | ✓ | ✓ | ✓ |
| 元素高亮 cmd_highlight | ✓ | ✓ | ✓ |
| 纯语音提示 cmd_say | ✓ | ✓ | ✓ |
| 页面跳转 cmd_navigate | **✗** | ✓ | ✓ |
| 代填普通字段 fill_field_normal | ✗ | ✓ | ✓ |
| 代按非确定性按钮 cmd_press_button | ✗ | ✓ | ✓ |
| 代读短信 read_sms | ✗ | ✓（逐次授权） | ✓（一次总授权） |
| 代填敏感字段 fill_field_sensitive | ✗ | ✓（逐次授权） | ✓（一次总授权） |
| 代填密码字段 | ✗ | ✗ | ✗ **硬底线** |
| 代按确定性按钮（登录/提交/支付） | ✗ | ✗ | ✗ **硬底线** |

**最终能力 = min(用户选级, 登录态联动级, 场景固有上限)**

---

## § 4 UI 设计

### 4.1 登录后首次弹卡 modal（v0.4 核心新增）

形态：**全屏底部上滑 modal**（showModalBottomSheet, isScrollControlled: true），不可点空白关闭，只能选卡或点右上角「✕」。

```
┌─────────────────────────────────────────┐
│                                     ✕   │
│  小浙能帮您做多少                          │
│  您可以现在选一种，以后随时在设置里调整      │
├─────────────────────────────────────────┤
│  ┌──────────────────────────────────┐   │
│  │  🗣  我自己做，小浙提醒我          │   │
│  │  小浙用语音教您每一步，您亲手操作    │   │
│  │                              ○   │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  ✋  小浙帮我填，我自己点提交        │   │
│  │  小浙帮您填表单，敏感信息会问您     │   │
│  │                              ○   │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  🤖  小浙全程代办，关键步骤我确认   │   │
│  │  小浙能填身份证等，登录支付要您动手  │   │
│  │                              ○   │   │
│  └──────────────────────────────────┘   │
│                                         │
│  🔒 登录、提交、支付始终由您亲手完成        │
│     小浙不会代替您操作                     │
└─────────────────────────────────────────┘
```

- 默认无任何卡选中（三个 ○），等用户主动选
- 点中某卡 → 立即关闭 modal + 立即生效 + Toast「已设为 XX」
- 点右上角「✕」 → 关闭 modal + 落地默认引导级 + 不再弹

### 4.2 设置页三卡区块（结构同 modal，复用组件）

```
┌─────────────────────────────────────────┐
│  小浙能帮您做多少                          │
├─────────────────────────────────────────┤
│  ┌──────────────────────────────────┐   │
│  │  🗣  我自己做，小浙提醒我          │   │
│  │  小浙用语音教您每一步，您亲手操作    │   │
│  │                              ●   │   │  ← 默认选中（首次弹卡关闭时）
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  ✋  小浙帮我填，我自己点提交        │   │
│  │  小浙帮您填表单，敏感信息会问您     │   │
│  │                              ○   │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  🤖  小浙全程代办，关键步骤我确认   │   │
│  │  小浙能填身份证等，登录支付要您动手  │   │
│  │                              ○   │   │
│  └──────────────────────────────────┘   │
│                                         │
│  🔒 登录、提交、支付始终由您亲手完成        │
│     小浙不会代替您操作                     │
└─────────────────────────────────────────┘
```

### 4.3 视觉规范
- 卡片标题 **20sp**，副标题 **18sp**（适老化对齐 F9），信任声明 **16sp**
- 选中态：橙色边框 2px + 实心圆点 ●；未选中：灰色描边 + 空心圆点 ○
- 整卡可点（不只圆点），命中区 ≥80×80dp
- 仅**设置页**升级方向弹二次确认 SystemDialog（L1→L2、L2→L3、L1→L3）；降级不弹；**首次弹卡不弹二次确认**
- 三卡组件 **modal 与设置页共用**（提取 `_TrustLevelCards` widget）

### 4.4 设置页未登录态
三卡 InkWell.onTap = null；整体 Opacity 0.4；顶部加黄色提示横条：

```
┌────────────────────────────────────────────────┐
│ ⚠ 登录后可调整小浙的工作方式      [去登录 ▶]   │
└────────────────────────────────────────────────┘
```

- 「去登录」跳转 `/login`，横条字号 16sp

### 4.5 全委托总授权弹卡（复用 AuthCard）
- 触发：全委托级 + 任务内首次遇到 sensitive 工具
- 文案：「本次办理「{场景名}」需要填写您的**身份证号等敏感信息**。本次都由小浙代填，可以吗？」
- 按钮：「不用了」/「可以」（同 AuthCard 现有样式）

---

## § 5 技术架构

### 5.1 前端

**A. `services/agent_settings_service.dart`**（+10 行）
```dart
static const _keyTrust = 'xiaozhe_trust_level';
String get trustLevel => html.window.localStorage[_keyTrust] ?? 'guide';  // v0.4 默认引导
set trustLevel(String v) => html.window.localStorage[_keyTrust] = v;

static const _keyFirstChoice = 'xiaozhe_first_choice_shown';
bool get firstChoiceShown => html.window.localStorage[_keyFirstChoice] == 'true';
set firstChoiceShown(bool v) => html.window.localStorage[_keyFirstChoice] = v.toString();
```

**B. `widgets/trust_level_cards.dart`** —— **新建组件**（+80 行）
- 三卡 widget，对外接收 `String selected`、`ValueChanged<String> onChanged`、`bool readonly`
- modal 和设置页共用，readonly=true 时整体灰显且禁点
- 默认 selected 为 `''` 时三卡均未选中（用于首次弹卡）

**C. `pages/elder_home.dart`** —— **v0.4 新增触发点**（+30 行）
```dart
// initState 或 PostFrameCallback
WidgetsBinding.instance.addPostFrameCallback((_) {
  final isLoggedIn = ref.read(loginProvider).isLoggedIn;
  final firstShown = AgentSettingsService.instance.firstChoiceShown;
  if (isLoggedIn && !firstShown) {
    _showFirstTrustChoice();
  }
});

Future<void> _showFirstTrustChoice() async {
  await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,    // 不允许点空白关闭
    enableDrag: false,
    builder: (_) => _FirstTrustChoiceSheet(),  // 内含 ✕ 按钮
  );
  // 无论用户选了还是 ✕，都标记 shown
  AgentSettingsService.instance.firstChoiceShown = true;
  // 用户没选 → trustLevel 保持默认 'guide'
}
```

**D. `pages/agent_settings_page.dart`**（+150 行）
- 顶部权限区块用 `_TrustLevelCards` 组件
- `ConsumerStatefulWidget` + `ref.watch(loginProvider)` 实时响应登录态
- 未登录态：readonly=true + 顶部黄色「去登录」横条
- 登录态：升级时 `showDialog<bool>` 二次确认
- 顺手做字号普调（`_SectionHeader 13→15`、`_HelpCard desc 14→16`）

**E. `widgets/agent_fab.dart` `_initSession`**（+4 行）—— 登录态联动核心
```dart
final isLoggedIn = ref.read(loginProvider).isLoggedIn;
final effectiveTrust = isLoggedIn
    ? AgentSettingsService.instance.trustLevel  // 用户选的（或默认 guide）
    : 'guide';                                  // 未登录强制 L1

_ws.send('agent_wake', {
  'session_id': id, 'trigger': 'button',
  'current_page': widget.currentPath ?? '',
  'trust_level': effectiveTrust,
});
```

**F. `services/agent_command_executor.dart`**（+3 行）
```dart
case 'cmd_say':
  _speakHint(payload['voice_hint'] as String? ?? '');
```

### 5.2 后端

**G. `backend/models.py`** —— `AgentWakePayload` 加：
```python
trust_level: Literal["guide", "semi", "full"] = "guide"  # v0.4 默认改为 guide
```

**H. `backend/agent_core.py`** —— 核心改动（同 v0.3）：
```python
_PASSWORD_FIELDS = {
    "input_pay_password", "input_login_password",
    "input_old_password", "input_new_password",
}

def _is_password_field(field_key: str) -> bool:
    return (field_key in _PASSWORD_FIELDS
            or "password" in field_key.lower()
            or "pwd" in field_key.lower())

SCENE_TOOLS = {
    "login_face":     [cmd_navigate, cmd_highlight, cmd_say],          # L1
    "login_verify":   [cmd_navigate, cmd_highlight, cmd_say],          # L1
    "yibao_jiaofei":  [cmd_navigate, cmd_highlight, cmd_say, fill_field_normal, fill_field_sensitive],
    "pension_query":  [cmd_navigate, cmd_highlight, cmd_say, fill_field_normal, cmd_press_button],
    "yibao_query":    [cmd_navigate, cmd_highlight, cmd_say, fill_field_normal, cmd_press_button],
}
# read_sms 当前未挂载，保留备用于未来非登录类敏感场景

_LEVEL_TOOLS = {
    "guide": {cmd_highlight, cmd_say},   # v0.6：去掉 cmd_navigate
    "semi":  {cmd_navigate, cmd_highlight, cmd_say,
              fill_field_normal, cmd_press_button, read_sms, fill_field_sensitive},
    "full":  {cmd_navigate, cmd_highlight, cmd_say,
              fill_field_normal, cmd_press_button, read_sms, fill_field_sensitive},
}

def get_scene_tools(scene_id: str, trust_level: str) -> list:
    scene_max = set(SCENE_TOOLS.get(scene_id, [cmd_navigate, cmd_highlight]))
    user_max = _LEVEL_TOOLS.get(trust_level, _LEVEL_TOOLS["guide"])  # v0.4 兜底改 guide
    return list(scene_max & user_max)

class AgentCore:
    def __init__(self, session_id, ws_handler, trust_level="guide"):  # v0.4 默认改
        self.trust_level = trust_level
        self._task_sensitive_authorized: bool = False
        ...

    async def execute_task(self, intent_summary):
        self._task_sensitive_authorized = False
        tools = get_scene_tools(scene_id, self.trust_level)
        ...
        while True:
            response = await self._executor.arun(input_msg)
            stopped_tool = self._get_stopped_tool(response)

            if stopped_tool in _SENSITIVE_TOOLS:
                # 先推送所有非 stopped 的工具结果（不含敏感工具本身）
                await self._push_tool_results(response, skip_stopped=stopped_tool)

                # ① 密码字段硬拒（永不填）
                if stopped_tool == "fill_field_sensitive" and _is_password_field(field_key):
                    await self._send_fn("agent_reply", {"text": "这步需要您亲手输入密码", ...})
                    input_msg = "用户必须自己输入密码，请用 cmd_say 提示后继续后续步骤"
                    continue

                # ② 全委托 + 已总授权 → 直接推 stopped tool + 继续
                if self.trust_level == "full" and self._task_sensitive_authorized:
                    await self._push_stopped_tool(response, stopped_tool)
                    input_msg = "用户已授权，继续执行"
                    continue

                # ③ 弹 permission_request 等待用户
                granted = await self._send_and_wait_permission(stopped_tool)
                if granted:
                    await self._push_stopped_tool(response, stopped_tool)  # 真正填写
                    if self.trust_level == "full":
                        self._task_sensitive_authorized = True             # 仅同意时置位
                    input_msg = "用户已授权，继续执行"
                else:
                    # 拒绝 = 跳过该字段（v0.5）：不推 stopped tool，不取消任务
                    # _task_sensitive_authorized 保持 false，下个敏感工具再弹
                    input_msg = (f"用户拒绝代填该字段，请用 cmd_say 提示用户自己填写，"
                                  f"然后继续后续步骤")
                continue

            # 非敏感工具：正常推送 + 退出
            await self._push_tool_results(response)
            return response.content or ""
```

**I. `backend/ws_handler.py` `_on_agent_wake`** —— 1 行：
```python
self._agent_core = AgentCore(
    session_id=self.session_id, ws_handler=self,
    trust_level=payload.trust_level,
)
```

**J. `backend/tools/say.py`**（新建 5 行）+ **K. `_TOOL_TO_MSG_TYPE`** 加 `"cmd_say": "cmd_say"`

**L. prompt 改动**：
- `scene_login_verify.txt` 重写：去掉 read_sms + fill_field_normal，改为 cmd_say 提示用户自查短信 + cmd_highlight 验证码框
- 5 个 scene prompt：`value="4800"` 等 mock 替换为 `value="[来自用户已授权的实际数据]"`

### 5.3 协议层

| 字段 | 位置 | 默认 | 说明 |
|---|---|---|---|
| `trust_level` | `agent_wake` payload | `"guide"` | guide/semi/full；前端组合（未登录强制 guide） |
| `cmd_say` | 出站消息类型 | — | 仅含 voice_hint 字段 |

**向后兼容**：旧前端不带 trust_level → Pydantic 默认 guide（v0.4 改）→ 最保守行为。

---

## § 6 文件清单 + 工作量

| # | 文件 | 改动 | 责任方 |
|---|---|---|---|
| 1 | `app/lib/services/agent_settings_service.dart` | +trustLevel（默认 guide）+ firstChoiceShown | 前端 |
| 2 | `app/lib/widgets/trust_level_cards.dart` | **新建**，三卡组件，modal + 设置页共用 | 前端 |
| 3 | `app/lib/pages/elder_home.dart` | **v0.4 新增**首次弹卡触发逻辑 | 前端 |
| 4 | `app/lib/pages/agent_settings_page.dart` | 嵌入 TrustLevelCards + 未登录灰显 + 字号普调 | 前端 |
| 5 | `app/lib/widgets/agent_fab.dart` | agent_wake payload 组合 effective_trust_level | 前端 |
| 6 | `app/lib/services/agent_command_executor.dart` | +cmd_say case | 前端 |
| 7 | `backend/models.py` | AgentWakePayload +trust_level（默认 guide） | 后端 |
| 8 | `backend/agent_core.py` | get_scene_tools + 密码白名单 + 总授权标记 + SCENE_TOOLS 登录场景降 L1 + read_sms 移除挂载 | 后端 |
| 9 | `backend/ws_handler.py` | _on_agent_wake 传 trust_level | 后端 |
| 10 | `backend/tools/say.py` | 新建 | 后端 |
| 11 | `backend/prompts/scene_login_verify.txt` | **v0.3 重写**（砍 read_sms + fill_field_normal） | 后端 |
| 12 | `backend/prompts/scene_*.txt`（5 个） | value mock 替换为占位 | 后端 |
| 13 | `docs/AGENT_SPEC.md` | v1.0→v1.1，§3.3 + §6.1 重写 + 新增「登录后首次主动询问」机制 | 文档 |

**工时**：前端 7-8h（含弹卡 modal + 组件抽取）+ 后端 4-5h + 文档 1h + 联调 2h = **14-16h**

---

## § 7 不在本次范围

- 标准蓝标准版小浙入口（标准版当前无小浙）
- 跨设备级别同步（localStorage 单端即可）
- 自动级别推荐算法（论文不要求）
- UI 形态从右下角小气泡 → 底部滑上对话区（spec 7.1 留待原型阶段）
- `read_sms` 工具代码删除（保留作为未来非登录类敏感场景的备用工具）

---

## § 8 文档更新

`docs/AGENT_SPEC.md` v1.0 → v1.1：
- § 3.3「权限一事一授」改为「三级模型 + 任务级一事一授」
- 新增 § 5.2「三级权限矩阵 vs L1/L2/L3 能力矩阵」对照表
- 新增 § 7.4「登录后首次主动询问机制」（v0.4 新增）：
  > 用户登录成功跳转主页时，自动弹出三级权限选择 modal。用户主动选择或关闭，关闭即落地引导级。机制仅触发一次（localStorage 标记），与「原则 1 代理永远不主动」不冲突 —— 登录成功是用户主动产生的状态转换，弹卡是该转换的配套询问，不属于"主动挑事"
- § 6.1「场景能力上限」表述改写：
  > 原：「验证码分支展示 L2 代填 + 确定性按钮不代做」
  > 改为：「**登录场景统一限定为 L1 引导级**，体现敏感入口的最高保守态势；**医保缴费场景**承担 L2/L3 切换演示职责（普通字段直填 + 敏感字段授权 + 不可逆操作止步）」
- § 8.2「信任分级推进」保留作为半委托级的子机制

---

## § 9 拍板状态

**全部 6 项已拍板**，可直接进入开发。

1. ✅ **决策 1**（v0.3 + v0.4）：未登录强制引导；登录后弹卡让用户选；关闭默认引导
2. ✅ **决策 2** 文案 D 方案三标题：我自己做 / 小浙帮我填我自己点提交 / 小浙全程代办关键步骤我确认
3. ✅ **决策 3** 升级弹确认 / 降级不弹
4. ✅ **决策 4** 全委托级一次性总授权（任务结束失效）
5. ✅ **决策 5** 密码字段全级别禁填
6. ✅ **决策 6** scene_*.txt prompt 中的 mock 参数本 PR 同期改为占位

---

## § 10 后续延伸（v0.5 候选，不阻塞 v0.4）

- 论文「业务知识库」补强（医保术语 / 养老金算法 prompt 知识层）—— 答辩刚需
- 草稿恢复 + 代理接续（agent_wake 携带 filled_fields）
- 多轮纠错意图（spec 9.2「那个年度改成 2026」）
- Web Speech API ASR（NEXT_PLAN N1）
- `read_sms` 重新挂载到「绑定手机变更」等非登录类敏感场景

---

## 收敛过程回顾

- **v0.1**：架构师出差距分析 + 8 个决策点 → PM 出方案（8 Q 全答 + 5 个延伸点）
- **v0.2-pre**：架构师 4 项微调（字号 / 升级弹降级不弹 / 总授权任务级 / 新增 cmd_say）+ 3 项剩余风险
- **v0.2-final**：PM approve 全文 + 4 处微改（S7 场景兜底 / 首次气泡文案 / 总授权字段名概括 / 决策 6 加 prompt 同期改）→ 架构师整合发本稿
- **v0.3**：用户调整决策 1（登录态联动 + 默认全委托）→ PM 全 yes + 3 项增补（学术价值改述 / read_sms 不挂场景 / S7 S8 分写）→ 架构师整合
- **v0.4**：用户再次调整（默认全委托→引导级；登录后弹首次选择卡，关闭默认 guide）+ 用户对决策 3-6 视为确认 → 架构师同步 PM 后整合发本稿
- **v0.5**：用户补充决策 4 拒绝/跳过语义（拒绝≠取消任务、拒绝时不置位、下个字段再弹）→ 架构师重构 execute_task 流程（先授权后推 sensitive cmd）→ 全部决策最终确认，进入开发
- **v0.6**：用户澄清「引导级 = 不实际操作」包含页面跳转 → 引导级工具集去掉 cmd_navigate，仅保留 `{cmd_highlight, cmd_say}` → 行为矩阵 + S4/S7 + _LEVEL_TOOLS 同步对齐

**6 轮收敛达成共识**。全部决策已拍板，**可立即启动开发**。
