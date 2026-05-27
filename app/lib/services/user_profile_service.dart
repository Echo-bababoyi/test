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

  static const _mockBankCard = '6222021234567890';
  String get bankCard => _mockBankCard;

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
      case 'confirm_id_card':
        return idCard;
      case 'confirm_bank_card':
        return bankCard;
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
