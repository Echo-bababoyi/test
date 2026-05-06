import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// 声明式登录引导横幅。
/// 挂载方：在 Scaffold.body 的 Stack 底层用
/// `Align(alignment: Alignment.bottomCenter, child: PersistentBanner())`。
/// 两个条件同时满足才显示：未登录 且 用户未点 × 关闭。
class PersistentBanner extends ConsumerWidget {
  const PersistentBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(loginProvider).isLoggedIn;
    final isDismissed = ref.watch(loginBannerDismissedProvider);
    final mode = ref.watch(modeProvider);

    if (isLoggedIn || isDismissed) return const SizedBox.shrink();

    final buttonColor = mode == AppMode.elder
        ? AppColors.elderPrimary
        : AppColors.bannerButton;

    return Container(
      margin: const EdgeInsets.all(Spacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.bannerBg,
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
      ),
      child: Row(
        children: [
          // × 关闭按钮
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFFAAAAAA), size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              ref.read(loginBannerDismissedProvider.notifier).dismiss();
            },
          ),
          const Expanded(
            child: Text(
              '登录享受更多服务',
              style: TextStyle(color: Color(0xFFD0D0D0), fontSize: AppFontSize.caption),
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            style: TextButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xlarge),
              ),
            ),
            child: const Text('立即登录', style: TextStyle(fontSize: AppFontSize.caption)),
          ),
        ],
      ),
    );
  }
}
