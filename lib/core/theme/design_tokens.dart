import 'package:flutter/material.dart';

/// 设计基准分辨率（逻辑像素 dp）
/// 源：32 张截图统一的 1216×2640 物理像素 ÷ DPR 3
/// 从截图量任何尺寸 ÷3 即为 Flutter 里的 dp 值。
class DesignSize {
  static const double width = 405.0;
  static const double height = 880.0;
  static const double pixelRatio = 3.0;
}

/// 主色调
class AppColors {
  static const Color standardPrimary = Color(0xFF2D74DC); // 标准版蓝
  static const Color elderPrimary = Color(0xFFFF6D00);    // 长辈版橙
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF999999);
  static const Color divider = Color(0xFFE5E5E5);
  // 登录引导 Banner
  static const Color bannerBg = Color(0xFF333333);
  static const Color bannerButton = Color(0xFF2D74DC); // 复用标准版蓝
}

class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppFontSize {
  static const double small = 12;
  static const double body = 14;
  static const double bodyLarge = 16;
  static const double subtitle = 18;
  static const double title = 20;
  static const double titleLarge = 24;
  // 长辈版专用（更大）
  static const double elderBody = 18;
  static const double elderTitle = 24;
  static const double elderLarge = 32;
}

class AppRadius {
  static const double small = 4;
  static const double medium = 8;
  static const double large = 12;
  static const double xlarge = 16;
}
