import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _kOrange = Color(0xFFFF6D00);
const _kBg = Color(0xFFF5F5F5);
const _kSurface = Colors.white;
const _kShadow = BoxShadow(
  color: Color(0x0D000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

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
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('刷脸登录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [_kShadow],
              ),
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _recognizing ? _kOrange : const Color(0xFFE5E5E5),
                        width: 3,
                      ),
                    ),
                    child: _recognizing
                        ? const Center(child: CircularProgressIndicator(color: _kOrange, strokeWidth: 3))
                        : const Icon(Icons.face, size: 96, color: Color(0xFFCCCCCC)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _recognizing ? '正在识别，请保持不动…' : '请将面部对准框内',
                    style: const TextStyle(fontSize: 18, color: Color(0xFF666666)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _recognizing ? null : _startRecognition,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange,
                  disabledBackgroundColor: const Color(0xFFFFB07A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('开始识别', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
