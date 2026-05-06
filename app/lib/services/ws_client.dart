import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsClient {
  static const _baseUrl = 'ws://localhost:8000/ws/session/';

  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  bool _connected = false;

  bool get isConnected => _connected;

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  Future<void> connect(String sessionId) async {
    final uri = Uri.parse('$_baseUrl$sessionId');
    _channel = WebSocketChannel.connect(uri);
    await _channel!.ready;
    _connected = true;

    _channel!.stream.listen(
      (raw) {
        final data = jsonDecode(raw as String) as Map<String, dynamic>;
        _controller.add(data);
      },
      onDone: () => _connected = false,
      onError: (_) => _connected = false,
    );
  }

  void disconnect() {
    _channel?.sink.close();
    _connected = false;
  }

  void send(String type, Map<String, dynamic> payload) {
    if (!_connected) return;
    final msg = jsonEncode({
      'type': type,
      'payload': payload,
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
    _channel!.sink.add(msg);
  }
}
