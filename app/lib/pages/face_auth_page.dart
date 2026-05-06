import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FaceAuthPage extends StatefulWidget {
  const FaceAuthPage({super.key});

  @override
  State<FaceAuthPage> createState() => _FaceAuthPageState();
}

class _FaceAuthPageState extends State<FaceAuthPage> {
  bool _recognizing = false;

  Future<void> _startRecognition() async {
    setState(() => _recognizing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) context.go('/elder');
  }

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _recognizing
                      ? const CircularProgressIndicator(color: Color(0xFFFF6D00))
                      : const Icon(Icons.face, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _recognizing ? '正在识别…' : '请将面部对准框内',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _recognizing ? null : _startRecognition,
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
