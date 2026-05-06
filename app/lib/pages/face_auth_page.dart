import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FaceAuthPage extends StatelessWidget {
  const FaceAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('刷脸登录')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.face, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('请将面部对准框内', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/elder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('开始识别', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
