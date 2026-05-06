import 'package:flutter/material.dart';

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6D00)),
  primaryColor: const Color(0xFFFF6D00),
  textTheme: const TextTheme(
    displayLarge:  TextStyle(fontSize: 32),
    displayMedium: TextStyle(fontSize: 28),
    displaySmall:  TextStyle(fontSize: 24),
    headlineLarge: TextStyle(fontSize: 24),
    headlineMedium: TextStyle(fontSize: 22),
    headlineSmall: TextStyle(fontSize: 20),
    titleLarge:    TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium:   TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
    titleSmall:    TextStyle(fontSize: 18),
    bodyLarge:     TextStyle(fontSize: 20),
    bodyMedium:    TextStyle(fontSize: 18),
    bodySmall:     TextStyle(fontSize: 18),
    labelLarge:    TextStyle(fontSize: 18),
    labelMedium:   TextStyle(fontSize: 18),
    labelSmall:    TextStyle(fontSize: 18),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
  ),
);
