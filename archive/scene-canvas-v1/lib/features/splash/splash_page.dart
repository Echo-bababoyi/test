import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_navigated) {
        _navigated = true;
        context.go(AppRoutes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo 灰块占位（Phase 2 替换为真实 Logo）
            Container(
              width: 80,
              height: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: Spacing.lg),
            // 应用名称灰块占位
            Container(
              width: 120,
              height: 24,
              color: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}
