import 'operation_log_store.dart';

const _sceneTitleMap = <String, String>{
  'yibao_jiaofei': '医保缴费',
  'yibao_query':   '医保查询',
  'pension_query': '养老金查询',
  'shebao_query':  '社保查询',
  'face_login':    '刷脸登录',
  'otp_login':     '验证码登录',
};

const _sensitiveKeys = <String>{
  'id_number', 'identity', 'card_no', 'password',
  'id_card', 'sfz', 'bei_jiaofei_sfz',
  'phone', 'mobile', 'tel', 'phone_number',
  'bank_no', 'bank_card', 'account', 'account_no',
  'address', 'addr',
};

class LogService {
  static int _seq = 0;

  static Future<void> saveFromTaskDone(Map<String, dynamic> payload) async {
    final scene = payload['scene'] as String? ?? '';
    final rawSteps = payload['steps'] as List<dynamic>? ?? [];
    final steps = _processSteps(rawSteps, 'agent');
    final hasSensitive = _hasSensitive(rawSteps);
    await OperationLogStore.saveLog({
      'log_id': _newId(),
      'scene': scene,
      'scene_title': _sceneTitleMap[scene] ?? scene,
      'trigger': 'voice',
      'status': payload['status'] as String? ?? 'completed',
      'summary': payload['summary'] as String? ?? '',
      'steps': steps,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'sensitive_actions_redacted': hasSensitive,
    });
  }

  static Future<void> saveManual({
    required String scene,
    required String summary,
    List<Map<String, dynamic>> steps = const [],
    String status = 'completed',
  }) async {
    final processed = _processSteps(steps, 'user');
    final hasSensitive = _hasSensitive(steps);
    await OperationLogStore.saveLog({
      'log_id': _newId(),
      'scene': scene,
      'scene_title': _sceneTitleMap[scene] ?? scene,
      'trigger': 'manual',
      'status': status,
      'summary': summary,
      'steps': processed,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'sensitive_actions_redacted': hasSensitive,
    });
  }

  static List<Map<String, dynamic>> _processSteps(
      List<dynamic> steps, String defaultBy) {
    int seq = 1;
    return steps.map((s) {
      final step = _redact(Map<String, dynamic>.from(s as Map));
      step['seq'] ??= seq;
      step['by'] ??= defaultBy;
      seq++;
      return step;
    }).toList();
  }

  static bool _hasSensitive(List<dynamic> steps) {
    for (final s in steps) {
      for (final key in (s as Map).keys) {
        if (_isSensitive(key as String)) return true;
      }
    }
    return false;
  }

  static Map<String, dynamic> _redact(Map<String, dynamic> step) {
    final result = Map<String, dynamic>.from(step);
    for (final key in result.keys.toList()) {
      final masked = _maskValue(key, result[key]?.toString() ?? '');
      if (masked != null) result[key] = masked;
    }
    return result;
  }

  static String? _maskValue(String key, String value) {
    final k = key.toLowerCase();
    if (k.contains('password')) return '[已隐藏]';
    if (k.contains('id_') || k.contains('identity') || k.contains('sfz') ||
        k == 'card_no' || k == 'id_number') {
      if (value.length < 7) return '[已隐藏]';
      return '${value.substring(0, 3)}****${value.substring(value.length - 4)}';
    }
    if (k.contains('phone') || k.contains('mobile') || k.contains('tel')) {
      if (value.length < 7) return '[已隐藏]';
      return '${value.substring(0, 3)}****${value.substring(value.length - 4)}';
    }
    if (k.contains('bank') || k.contains('account') || k.contains('card')) {
      if (value.length < 4) return '[已隐藏]';
      return '尾号 ${value.substring(value.length - 4)}';
    }
    if (k.contains('address') || k.contains('addr')) {
      return value.length > 6 ? '${value.substring(0, 6)}…' : value;
    }
    return null;
  }

  static bool _isSensitive(String key) =>
      _sensitiveKeys.any((s) => key.toLowerCase().contains(s));

  static String _newId() {
    _seq = (_seq % 999) + 1;
    final now = DateTime.now();
    final date = '${now.year}${_z(now.month)}${_z(now.day)}';
    final time = '${_z(now.hour)}${_z(now.minute)}${_z(now.second)}';
    return 'log_${date}_${time}_${_seq.toString().padLeft(3, '0')}';
  }

  static String _z(int n) => n.toString().padLeft(2, '0');
}
