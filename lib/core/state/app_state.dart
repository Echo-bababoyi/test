import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

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
  void login(String name) =>
      state = LoginState(isLoggedIn: true, userName: name);
  void logout() => state = LoginState.loggedOut;
}

final loginProvider =
    NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);

/// ---- 当前模式（标准版 / 长辈版）----
class ModeNotifier extends Notifier<AppMode> {
  @override
  AppMode build() => AppMode.standard;
  void toElder() => state = AppMode.elder;
  void toStandard() => state = AppMode.standard;
  void toggle() =>
      state = state == AppMode.standard ? AppMode.elder : AppMode.standard;
}

final modeProvider = NotifierProvider<ModeNotifier, AppMode>(ModeNotifier.new);
