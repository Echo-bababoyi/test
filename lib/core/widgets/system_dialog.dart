import 'package:flutter/material.dart';

/// 系统弹窗（阻塞式）：自绘组件模拟 Android 系统权限/提示对话框外观。
/// 在代码里与 InAppOverlay **物理分开**，不共用基类，避免混淆。
/// Phase 0 骨架：样式粗略，Phase 2 再精修。
class SystemDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String denyLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onDeny;

  const SystemDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = '允许',
    this.denyLabel = '拒绝',
    this.onConfirm,
    this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDeny?.call();
                  },
                  child: Text(denyLabel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm?.call();
                  },
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = '允许',
    String denyLabel = '拒绝',
    VoidCallback? onConfirm,
    VoidCallback? onDeny,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 阻塞行为
      builder: (_) => SystemDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        denyLabel: denyLabel,
        onConfirm: onConfirm,
        onDeny: onDeny,
      ),
    );
  }
}
