import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/design_tokens.dart';
import '../services/auth_state.dart';

/// 声明式登录引导横幅。
/// 挂载方：在 Scaffold.body 的 Stack 底层用
/// `Align(alignment: Alignment.bottomCenter, child: PersistentBanner())`。
/// 两个条件同时满足才显示：未登录 且 用户未点 × 关闭。
class PersistentBanner extends StatefulWidget {
  const PersistentBanner({super.key});

  @override
  State<PersistentBanner> createState() => _PersistentBannerState();
}

class _PersistentBannerState extends State<PersistentBanner> {
  // 静态变量：整个 App 生命周期内保持，组件重建也记住关闭状态
  static bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthState.instance.isLoggedIn;

    if (isLoggedIn || _dismissed) return const SizedBox.shrink();

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
              setState(() => _dismissed = true);
            },
          ),
          const Expanded(
            child: Text(
              '登录享受更多服务',
              style: TextStyle(color: Color(0xFFD0D0D0), fontSize: AppFontSize.caption),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFF6D00),
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
