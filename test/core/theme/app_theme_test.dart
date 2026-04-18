import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zlb_elder/core/theme/app_theme.dart';
import 'package:zlb_elder/core/theme/design_tokens.dart';

void main() {
  group('AppColors seed constants', () {
    test('standardPrimary is #2D74DC', () {
      expect(AppColors.standardPrimary, const Color(0xFF2D74DC));
    });

    test('elderPrimary is #FF6D00', () {
      expect(AppColors.elderPrimary, const Color(0xFFFF6D00));
    });
  });

  group('AppTheme.of', () {
    test('standard mode primary is blue-dominant', () {
      final theme = AppTheme.of(AppMode.standard);
      final p = theme.colorScheme.primary;
      expect(
        p.blue,
        greaterThan(p.red),
        reason: '标准版以蓝色为主色 (seed #2D74DC: blue=220 > red=45)',
      );
    });

    test('elder mode primary is red-dominant', () {
      final theme = AppTheme.of(AppMode.elder);
      final p = theme.colorScheme.primary;
      expect(
        p.red,
        greaterThan(p.blue),
        reason: '长辈版以橙红色为主色 (seed #FF6D00: red=255 > blue=0)',
      );
    });

    test('standard and elder themes have distinct primary colors', () {
      final std = AppTheme.of(AppMode.standard).colorScheme.primary;
      final eld = AppTheme.of(AppMode.elder).colorScheme.primary;
      expect(std, isNot(equals(eld)));
    });
  });
}
