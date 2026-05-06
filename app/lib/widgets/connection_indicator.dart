import 'package:flutter/material.dart';
import '../services/ws_client.dart';

class ConnectionIndicator extends StatefulWidget {
  const ConnectionIndicator({super.key});

  @override
  State<ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator> {
  late bool _connected;

  @override
  void initState() {
    super.initState();
    _connected = WsClient.instance.isConnected;
    // Poll every second — WsClient doesn't expose a stream for connection state
    _startPolling();
  }

  void _startPolling() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      final now = WsClient.instance.isConnected;
      if (now != _connected) setState(() => _connected = now);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Tooltip(
        message: _connected ? '小浙已连接' : '小浙未连接',
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _connected ? const Color(0xFF4CAF50) : const Color(0xFFBBBBBB),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
