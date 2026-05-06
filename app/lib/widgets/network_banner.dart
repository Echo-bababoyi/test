import 'package:flutter/material.dart';

class NetworkBanner extends StatelessWidget {
  final bool visible;
  const NetworkBanner({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      height: 40,
      color: const Color(0xFFFF3B30),
      alignment: Alignment.center,
      child: const Text(
        '网络已断开，请检查连接',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
