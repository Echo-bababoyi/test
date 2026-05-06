import 'package:flutter/material.dart';
import 'in_app_overlay.dart';
import 'system_dialog.dart';

/// 三段式权限请求流封装（SearchPage 麦克风 / FaceAuthPage 摄像头 共用）：
/// 1. 弹 guideContentBuilder 构造的 InAppOverlay（非阻塞）
/// 2. 用户点"去开启"(onProceed) → 关闭浮层 → 弹 SystemDialog（阻塞）
/// 3. 用户点"允许" → 调 onGranted
/// 任一步取消都不调 onGranted。
class PermissionFlowHelper {
  static void request({
    required BuildContext context,
    required Widget Function(VoidCallback onProceed) guideContentBuilder,
    required String systemTitle,
    required String systemMessage,
    String systemConfirmLabel = '允许',
    String systemDenyLabel = '禁止',
    required VoidCallback onGranted,
  }) {
    InAppOverlay.show<void>(
      context,
      child: guideContentBuilder(() {
        Navigator.of(context).pop();
        SystemDialog.show(
          context,
          title: systemTitle,
          message: systemMessage,
          confirmLabel: systemConfirmLabel,
          denyLabel: systemDenyLabel,
          onConfirm: onGranted,
        );
      }),
    );
  }
}
