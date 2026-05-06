import 'dart:math';
import 'operation_log_store.dart';

const _sensitiveKeys = {'id_number', 'identity', 'card_no', 'password'};

class LogService {
  static Future<void> saveFromTaskDone(Map<String, dynamic> taskDonePayload) async {
    final logId = _newId();
    final steps = taskDonePayload['steps'] as List<dynamic>? ?? [];
    final redactedSteps = steps.map((s) => _redactSensitive(Map<String, dynamic>.from(s as Map))).toList();
    await OperationLogStore.saveLog({
      'log_id': logId,
      'scene': taskDonePayload['scene'] as String? ?? '',
      'summary': taskDonePayload['summary'] as String? ?? '',
      'steps': redactedSteps,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Map<String, dynamic> _redactSensitive(Map<String, dynamic> step) {
    final result = Map<String, dynamic>.from(step);
    for (final key in result.keys.toList()) {
      if (_sensitiveKeys.any((s) => key.toLowerCase().contains(s))) {
        result[key] = '[已隐藏]';
      }
    }
    return result;
  }

  static String _newId() {
    final rand = Random.secure();
    return List.generate(16, (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
