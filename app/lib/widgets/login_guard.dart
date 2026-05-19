import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../services/auth_state.dart';
import 'system_dialog.dart';

/// 入口级登录守卫：未登录时弹 SystemDialog 引导去登录。
/// 直接读 AuthState.instance.isLoggedIn（与 loginProvider 同步），
/// 调用方无需 WidgetRef，可在 StatelessWidget 中一行替换 context.push。
class LoginGuard {
  /// 已登录 → push 目标路由；未登录 → 弹"请先登录"对话框。
  static void tryNavigate(BuildContext context, String route) {
    if (AuthState.instance.isLoggedIn) {
      context.push(route);
      return;
    }
    SystemDialog.show(
      context,
      title: '请先登录',
      message: '该功能需要登录后才能使用，是否前往登录？',
      confirmLabel: '去登录',
      denyLabel: '取消',
      onConfirm: () => context.go(AppRoutes.login),
    );
  }
}
