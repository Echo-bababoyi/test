import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/system_dialog.dart';

/// VerifyPage — 短信验证码页（备选登录分支）
/// 路由：/login/verify
/// 从 FaceAuthPage 点「其他方式认证 → 手机短信验证」进入
class VerifyPage extends ConsumerWidget {
  const VerifyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEEAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg, Spacing.lg, Spacing.lg, 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            const Text(
              '请输入验证码',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            // 说明文字
            const Text(
              '我们已向182****6655发送验证码短信，\n请查看短信并输入验证码',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: Spacing.xl),
            // 6格 OTP 输入框
            const _OtpInputRow(),
            const SizedBox(height: Spacing.lg),
            // 重新发送倒计时
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 4),
                Text(
                  '重新发送 55秒',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            // 确认按钮
            FilledButton(
              onPressed: () => _confirmSmsCode(context, ref),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.standardPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xlarge),
                ),
              ),
              child: const Text('确认', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSmsCode(BuildContext context, WidgetRef ref) {
    SystemDialog.show(
      context,
      title: '验证码确认',
      message: '验证码已验证，即将完成登录',
      confirmLabel: '确认',
      denyLabel: '取消',
      onConfirm: () {
        ref.read(loginProvider.notifier).login('用户');
        context.go(AppRoutes.elderHome);
      },
    );
  }
}

// ─── 6格 OTP 输入行 ───────────────────────────────────────────────────────────

class _OtpInputRow extends StatelessWidget {
  const _OtpInputRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < 6; i++)
          Container(
            width: 44,
            height: 54,
            decoration: BoxDecoration(
              color: i == 0 ? Colors.white : const Color(0xFFF0F5FF),
              border: Border.all(
                color: i == 0
                    ? AppColors.standardPrimary
                    : const Color(0xFFDDDDDD),
                width: i == 0 ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: i == 0
                ? const Center(
                    child: SizedBox(
                      width: 2,
                      height: 20,
                      child: ColoredBox(color: AppColors.standardPrimary),
                    ),
                  )
                : null,
          ),
      ],
    );
  }
}
