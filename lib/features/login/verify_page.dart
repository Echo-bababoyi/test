import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/state/app_state.dart';

class VerifyPage extends ConsumerWidget {
  const VerifyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('刷脸验证中')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('VerifyPage（Phase 0 占位）'),
            const SizedBox(height: 8),
            const Text('眨眼 / 摇头动画 + 屏幕变色 → Phase 3',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                ref.read(loginProvider.notifier).login('张老伯');
                context.go(AppRoutes.elderHome);
              },
              child: const Text('模拟认证通过 → 长辈版首页'),
            ),
          ],
        ),
      ),
    );
  }
}
