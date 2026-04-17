import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/in_app_overlay.dart';
import '../../core/widgets/system_dialog.dart';

class FaceAuthPage extends ConsumerWidget {
  const FaceAuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('刷脸身份验证')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('FaceAuthPage（Phase 0 占位）'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _requestFaceAuth(context),
              child: const Text('开始认证'),
            ),
          ],
        ),
      ),
    );
  }

  void _requestFaceAuth(BuildContext context) {
    InAppOverlay.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('请求刷脸认证（应用内 · 非阻塞）',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestCameraPermission(context);
            },
            child: const Text('同意并继续'),
          ),
        ],
      ),
    );
  }

  void _requestCameraPermission(BuildContext context) {
    SystemDialog.show(
      context,
      title: '允许"浙里办"访问摄像头？',
      message: '用于进行身份认证',
      confirmLabel: '允许',
      denyLabel: '拒绝',
      onConfirm: () => context.go(AppRoutes.verify),
    );
  }
}
