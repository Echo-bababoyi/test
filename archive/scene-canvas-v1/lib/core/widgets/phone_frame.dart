import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Web 端把 App 包在固定 405×880 dp 的手机画框里：
/// - 外层灰底（模拟真机外的桌面背景）
/// - FittedBox 等比缩放以适配浏览器窗口
/// - 圆角 clip 模拟手机圆角屏
class PhoneFrame extends StatelessWidget {
  final Widget child;
  const PhoneFrame({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.phoneBg,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: DesignSize.width,
            height: DesignSize.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.phone),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
