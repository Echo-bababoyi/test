import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// 应用内浮层（非阻塞）：底部出现，可点击蒙层或手势下滑关闭。
/// 在代码里与 SystemDialog **物理分开**，不共用基类。
/// Phase 0 骨架：样式粗略，Phase 2 再精修。
class InAppOverlay extends StatelessWidget {
  final Widget child;
  const InAppOverlay({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xlarge)),
      ),
      padding: const EdgeInsets.all(Spacing.lg),
      child: SafeArea(top: false, child: child),
    );
  }

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: true,   // 点蒙层可关闭（非阻塞）
      enableDrag: true,      // 手势下滑可关闭
      backgroundColor: Colors.transparent,
      builder: (_) => InAppOverlay(child: child),
    );
  }
}
