# 实施方案：用户档案预填（手机号 / 身份证号）

> 作者：architect｜日期：2026-05-26｜状态：待实施
>
> 思路：档案存**前端 localStorage**，登录时写入；代理代填时只发占位符 `@档案`，**前端**按 field_key 取真实值替换。后端 AgentCore / models / ws_handler 一律不动，真实身份证不经 LLM、不上传 API。

依赖顺序：先建 `UserProfileService`（前端其余三处都依赖它），再改两个登录页 + executor；prompt 可并行。

---

# 前端

## 1. 新建 `app/lib/services/user_profile_service.dart`

```dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// 登录后保存的用户档案（demo：localStorage mock，无后端 DB）。
/// 代理代填时用占位符 "@档案"，由 agent_command_executor 按 field_key 取真实值。
class UserProfileService {
  UserProfileService._();
  static final instance = UserProfileService._();

  static const _kPhone = 'xiaozhe_profile_phone';
  static const _kIdCard = 'xiaozhe_profile_idcard';

  String? get phone => html.window.localStorage[_kPhone];
  String? get idCard => html.window.localStorage[_kIdCard];

  void setProfile({String? phone, required String idCard}) {
    if (phone != null && phone.isNotEmpty) {
      html.window.localStorage[_kPhone] = phone;
    }
    html.window.localStorage[_kIdCard] = idCard;
  }

  /// 把代填的 field_key 映射到档案字段；无对应则返回 null。
  String? valueForField(String fieldKey) {
    switch (fieldKey) {
      case 'input_id_card':
        return idCard;
      case 'input_phone':
        return phone;
    }
    return null;
  }

  void clear() {
    html.window.localStorage.remove(_kPhone);
    html.window.localStorage.remove(_kIdCard);
  }
}
```

## 2. `app/lib/pages/verify_page.dart`

### 2.1 import（第 12 行 `import '../services/agent_session.dart';` 后加一行）
```dart
import '../services/user_profile_service.dart';
```

### 2.2 `_confirmSmsCode`：登录成功后写档案（第 130 行后）
当前（125、130 行）：
```dart
    final phone = _phoneController.text;
    ...
    ref.read(loginProvider.notifier).login('用户');
```
在 `ref.read(loginProvider.notifier).login('用户');`（第 130 行）后加：
```dart
    UserProfileService.instance.setProfile(
      phone: phone,
      idCard: '330102194505061234',
    );
```
> `phone` 是用户登录时真实输入的手机号（第 125 行已取）；身份证号为 demo mock 固定值。

## 3. `app/lib/pages/face_auth_page.dart`

### 3.1 import（第 12 行 `import '../widgets/system_dialog.dart';` 后加一行）
```dart
import '../services/user_profile_service.dart';
```

### 3.2 `_onAllSuccess`：登录成功后写档案（第 52 行后）
当前（52 行）：
```dart
    ref.read(loginProvider.notifier).login('用户');
```
其后加（刷脸路径没让用户输手机号，用 mock 手机号）：
```dart
    UserProfileService.instance.setProfile(
      phone: '13800138000',
      idCard: '330102194505061234',
    );
```

## 4. `app/lib/services/agent_command_executor.dart`

### 4.1 import（第 8 行 `import 'agent_session.dart';` 后加一行）
```dart
import 'user_profile_service.dart';
```

### 4.2 `_onFillField`：占位符替换（113-117 行）
当前（113-117）：
```dart
  Future<void> _onFillField(Map<String, dynamic> payload) async {
    final elementKey = payload['field_key'] as String?;
    final value = payload['value'] as String? ?? '';
    final isSensitive = payload['is_sensitive'] as bool? ?? false;
    if (elementKey == null) return;
```
改为（`final value` → `var value`，并在 null 检查后插入替换逻辑）：
```dart
  Future<void> _onFillField(Map<String, dynamic> payload) async {
    final elementKey = payload['field_key'] as String?;
    var value = payload['value'] as String? ?? '';
    final isSensitive = payload['is_sensitive'] as bool? ?? false;
    if (elementKey == null) return;

    if (value == '@档案') {
      final pv = UserProfileService.instance.valueForField(elementKey);
      if (pv == null || pv.isEmpty) return;  // 无档案则跳过，留给用户自填
      value = pv;
    }
```
> 119 行起的 currentRoute / controller / redact / autosave 逻辑全部不变。敏感字段经 `_redactValue` 脱敏后仍 18 字符，`_canSubmit` 的 `length==18` 通过。

---

# 后端

## 5. `backend/prompts/scene_yibao_jiaofei.txt` 第 2 步（仅改两处，不动其它步骤/准则）

### 5.1 "必问项"列表里删掉身份证那条
当前：
```
  - 本人身份证号（用户没给 18 位才问）：放到下面下拉框都填好之后再问。
```
**删除此行**（身份证不再问，改从档案取）。

### 5.2 末尾"最后"那段：cmd_ask_user 改为直接从档案代填
当前：
```
  最后（下拉框都填好后再问本人身份证并代填）：
  cmd_ask_user(question="请告诉我您的18位身份证号", options=[]) → fill_field_sensitive(field_key="input_id_card", field_label="身份证号", value=<本人18位身份证号>)
  说明：险种/年度/档次三项即使用户没提也必须填默认值（页面这三个下拉框无预设，不填则"去支付"一直灰着）；档次依赖险种，务必先填险种再填档次；fill_field_sensitive 会暂停等授权（全委托级仅首个敏感字段弹一次卡），系统自动处理。
```
替换为：
```
  最后（本人身份证号已在用户档案，直接代填、无需询问）：
  fill_field_sensitive(field_key="input_id_card", field_label="身份证号", value="@档案")
  说明：本人身份证号已存档，value 一律写固定占位符 "@档案"，系统会自动取档案里的真实身份证号代填，绝不要向用户询问、也不要自己编造数字。险种/年度/档次三项即使用户没提也必须填默认值（页面这三个下拉框无预设，不填则"去支付"一直灰着）；档次依赖险种，务必先填险种再填档次；fill_field_sensitive 会暂停等授权（全委托级仅首个敏感字段弹一次卡），系统自动处理。
```

> 被缴费人姓名 / 证件号（家人路径）仍用 cmd_ask_user 询问——属家属信息、不在本人档案（如需也存，二期做"家属档案"列表）。缴费对象选择卡不变。`_validate_prompts_against_knowledge` 只校验 element_key / target_route，不涉及工具与 value，本改动不影响启动校验。

---

# 验证

> 重测前清掉 localStorage 旧值：`xiaozhe_profile_phone`、`xiaozhe_profile_idcard`（以及之前的 `xiaozhe_first_choice_shown` 若仍需测信任卡）。

1. **验证码登录路径**：登录时输入手机号 X → 登录成功。再做医保缴费：选缴费对象"本人" → 险种/年度/档次默认代填 → **身份证号自动从档案代填（弹一次授权卡，不再问用户打字）** → "去支付"点亮。检查身份证脱敏显示对应 mock 值 `330102194505061234`。
2. **刷脸登录路径**：刷脸成功后做医保缴费，身份证同样自动代填。
3. **家人路径**：缴费对象选"配偶/子女" → 仍会问被缴费人姓名/证件号（家属信息），本人身份证仍从档案取。
4. **回归**：未登录直接到缴费页（不应发生，scene 需登录）；若档案为空，`@档案` 替换跳过、字段留空、"去支付"灰着——可接受的兜底。
