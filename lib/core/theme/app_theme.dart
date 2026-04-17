import 'package:flutter/material.dart';
import 'design_tokens.dart';

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
    );
  }
}
