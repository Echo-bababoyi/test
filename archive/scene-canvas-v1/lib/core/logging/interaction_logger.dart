import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 扩展点 4：交互日志
/// Phase 0 实现：写入内存环形缓冲 + debug console 打印。
/// 后续：写本地文件 / 上报服务端 / 作为智能代理决策输入。
class InteractionEvent {
  final DateTime at;
  final String type;   // "tap" / "nav" / "dwell" / "back" / "popup"
  final String target; // 路由路径 / 组件 id
  final Map<String, Object?> payload;
  const InteractionEvent(this.at, this.type, this.target, this.payload);
}

class InteractionLogger {
  static const int _maxBuffer = 500;
  final List<InteractionEvent> _buffer = [];

  void log(String type, String target, {Map<String, Object?>? payload}) {
    final e =
        InteractionEvent(DateTime.now(), type, target, payload ?? const {});
    _buffer.add(e);
    if (_buffer.length > _maxBuffer) _buffer.removeAt(0);
    if (kDebugMode) {
      // ignore: avoid_print
      print('[log] $type @$target ${e.payload.isEmpty ? "" : e.payload}');
    }
  }

  List<InteractionEvent> get events => List.unmodifiable(_buffer);
}

final interactionLoggerProvider =
    Provider<InteractionLogger>((ref) => InteractionLogger());
