import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_state.dart';

/// 扩展点 3：意图层（AppIntent）
/// 所有跨页面动作通过 AppIntent 触发；go_router / Riverpod 是执行器。
/// 这样后续智能代理可以发相同的 intent 代用户操作 UI，而不必触达具体控件。
sealed class AppIntent {
  const AppIntent();
}

class NavigateTo extends AppIntent {
  final String path;
  const NavigateTo(this.path);
}

class GoBack extends AppIntent {
  const GoBack();
}

class SwitchMode extends AppIntent {
  const SwitchMode();
}

class DoLogin extends AppIntent {
  final String userName;
  const DoLogin(this.userName);
}

class DoLogout extends AppIntent {
  const DoLogout();
}

class IntentDispatcher {
  final GoRouter router;
  final Ref ref;
  IntentDispatcher(this.router, this.ref);

  void dispatch(AppIntent intent) {
    switch (intent) {
      case NavigateTo(:final path):
        router.go(path);
      case GoBack():
        if (router.canPop()) router.pop();
      case SwitchMode():
        ref.read(modeProvider.notifier).toggle();
      case DoLogin(:final userName):
        ref.read(loginProvider.notifier).login(userName);
      case DoLogout():
        ref.read(loginProvider.notifier).logout();
    }
  }
}
