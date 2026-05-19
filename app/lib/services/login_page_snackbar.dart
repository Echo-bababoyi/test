import 'package:flutter/material.dart';

/// 跨页 SnackBar 队列：face_auth E2/E4 退回登录页前 `enqueue` 一条文案，
/// LoginPage initState 调 `showIfPending` 弹出。
class LoginPageSnackbar {
  static String? _pending;

  static void enqueue(String message) {
    _pending = message;
  }

  static void showIfPending(BuildContext context) {
    final msg = _pending;
    if (msg == null) return;
    _pending = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFFF6D00),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );
    });
  }
}
