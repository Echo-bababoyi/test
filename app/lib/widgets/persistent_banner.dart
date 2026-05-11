import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/state/app_state.dart';
import '../router.dart';
import '../theme/design_tokens.dart';
import 'press_scale_wrapper.dart';

class PersistentBanner extends ConsumerWidget {
  const PersistentBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(loginProvider).isLoggedIn;
    final isDismissed = ref.watch(loginBannerDismissedProvider);

    if (isLoggedIn || isDismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.md),
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
          PressScaleWrapper(
            pressedScale: 0.85,
            pressedOpacity: 0.5,
            onTap: () => ref.read(loginBannerDismissedProvider.notifier).dismiss(),
            customBorder: const CircleBorder(),
            builder: (_) => const SizedBox(
              width: 32,
              height: 32,
              child: Icon(Icons.close, color: Color(0xFFAAAAAA), size: 18),
            ),
          ),
          const Expanded(
            child: Text(
              '登录享受更多服务',
              style: TextStyle(color: Color(0xFFD0D0D0), fontSize: AppFontSize.caption),
            ),
          ),
          PressScaleWrapper(
            pressedScale: 0.94,
            onTap: () => context.go(AppRoutes.login),
            borderRadius: BorderRadius.circular(AppRadius.xlarge),
            builder: (pressed) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: pressed ? const Color(0xFF1A5CAF) : const Color(0xFF2D74DC),
                borderRadius: BorderRadius.circular(AppRadius.xlarge),
              ),
              child: const Text(
                '立即登录',
                style: TextStyle(fontSize: AppFontSize.caption, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
