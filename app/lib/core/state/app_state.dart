import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../services/auth_state.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// ---- 登录态 ----
class LoginState {
  final bool isLoggedIn;
  final String? userName;
  const LoginState({required this.isLoggedIn, this.userName});
  static const loggedOut = LoginState(isLoggedIn: false);
}

class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => LoginState.loggedOut;
  void login(String name) {
    state = LoginState(isLoggedIn: true, userName: name);
    AuthState.instance.login(name: name);
  }
  void logout() {
    state = LoginState.loggedOut;
    AuthState.instance.logout();
  }
}

final loginProvider =
    NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);

/// ---- 当前模式（标准版 / 长辈版）----
class ModeNotifier extends Notifier<AppMode> {
  static const _kModeKey = 'app_mode';

  @override
  AppMode build() {
    final v = html.window.localStorage[_kModeKey];
    return v == 'elder' ? AppMode.elder : AppMode.standard;
  }

  void toElder() {
    state = AppMode.elder;
    html.window.localStorage[_kModeKey] = 'elder';
  }

  void toStandard() {
    state = AppMode.standard;
    html.window.localStorage[_kModeKey] = 'standard';
  }

  void toggle() {
    if (state == AppMode.standard) {
      toElder();
    } else {
      toStandard();
    }
  }
}

final modeProvider = NotifierProvider<ModeNotifier, AppMode>(ModeNotifier.new);

/// ---- 登录引导 Banner 关闭状态（session 级，不随登出重置）----
class LoginBannerDismissedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void dismiss() => state = true;
}

final loginBannerDismissedProvider =
    NotifierProvider<LoginBannerDismissedNotifier, bool>(
        LoginBannerDismissedNotifier.new);
