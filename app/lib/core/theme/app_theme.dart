import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

enum AppMode { standard, elder }

class AppTheme {
  static ThemeData of(AppMode mode) {
    final primary = switch (mode) {
      AppMode.standard => AppColors.standardPrimary,
      AppMode.elder => AppColors.elderPrimary,
    };
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      splashColor: mode == AppMode.standard
          ? const Color(0x332D74DC)
          : const Color(0x33FF6D00),
      highlightColor: mode == AppMode.standard
          ? const Color(0x1A2D74DC)
          : const Color(0x1AFF6D00),
      hoverColor: mode == AppMode.standard
          ? const Color(0x0A2D74DC)
          : const Color(0x0AFF6D00),
    );
  }
}
