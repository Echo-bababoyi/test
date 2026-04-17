import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('SplashPage', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            const Text('启动页',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('进入主页'),
            ),
          ],
        ),
      ),
    );
  }
}
