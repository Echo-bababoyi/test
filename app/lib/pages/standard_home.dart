import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StandardHome extends StatelessWidget {
  const StandardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('小浙助手')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('欢迎使用小浙助手', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 56),
              ),
              child: const Text('登录', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/elder'),
              child: const Text('进入长辈版', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
