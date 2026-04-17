import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/in_app_overlay.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('LoginPage（Phase 0 占位）'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _showTermsOverlay(context),
              child: const Text('登录（弹同意条款）'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsOverlay(BuildContext context) {
    InAppOverlay.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('同意条款弹窗（应用内 · 非阻塞）',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(AppRoutes.faceAuth);
            },
            child: const Text('同意并继续'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
