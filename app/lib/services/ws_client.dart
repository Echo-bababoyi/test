import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsClient {
  static final WsClient instance = WsClient._();
  WsClient._();

  static const _baseUrl = 'ws://localhost:8000/ws/session/';

  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  bool _connected = false;

  bool get isConnected => _connected;

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  Future<void> connect(String sessionId) async {
    final uri = Uri.parse('$_baseUrl$sessionId');
    debugPrint('[WsClient] connecting to $uri');
    _channel = WebSocketChannel.connect(uri);
    await _channel!.ready;
    _connected = true;
    debugPrint('[WsClient] connected session=$sessionId');

    _channel!.stream.listen(
      (raw) {
        final data = jsonDecode(raw as String) as Map<String, dynamic>;
        debugPrint('[WsClient] recv type=${data['type']}');
        _controller.add(data);
      },
      onDone: () {
        debugPrint('[WsClient] connection closed');
        _connected = false;
      },
      onError: (err) {
        debugPrint('[WsClient] connection error: $err');
        _connected = false;
      },
    );
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _connected = false;
  }

  void send(String type, Map<String, dynamic> payload) {
    if (!_connected || _channel == null) {
      debugPrint('[WsClient] send skipped (not connected): type=$type');
      return;
    }
    debugPrint('[WsClient] send type=$type');
    final msg = jsonEncode({
      'type': type,
      'payload': payload,
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
    _channel!.sink.add(msg);
  }
}
