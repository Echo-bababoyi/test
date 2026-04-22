import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zlb_elder/core/state/app_state.dart';
import 'package:zlb_elder/core/widgets/persistent_banner.dart';

// ─── Notifier overrides for test fixtures ─────────────────────────────────────

class _LoggedInNotifier extends LoginNotifier {
  @override
  LoginState build() => const LoginState(isLoggedIn: true, userName: 'test');
}

class _DismissedNotifier extends LoginBannerDismissedNotifier {
  @override
  bool build() => true;
}

// ─── Test helper ─────────────────────────────────────────────────────────────

Widget _scaffold() => Scaffold(
      body: Stack(children: const [
        Align(
          alignment: Alignment.bottomCenter,
          child: PersistentBanner(),
        ),
      ]),
    );

GoRouter _makeRouter() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => _scaffold()),
        GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: SizedBox())),
      ],
    );

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('PersistentBanner visibility', () {
    testWidgets('visible: not logged in + not dismissed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: _makeRouter())),
      );
      await tester.pumpAndSettle();
      expect(find.text('登录享受更多服务'), findsOneWidget);
    });

    testWidgets('hidden: logged in (regardless of dismiss)', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [loginProvider.overrideWith(_LoggedInNotifier.new)],
        child: MaterialApp.router(routerConfig: _makeRouter()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('登录享受更多服务'), findsNothing);
    });

    testWidgets('hidden: dismissed (regardless of login)', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          loginBannerDismissedProvider.overrideWith(_DismissedNotifier.new)
        ],
        child: MaterialApp.router(routerConfig: _makeRouter()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('登录享受更多服务'), findsNothing);
    });

    testWidgets('hidden: logged in + dismissed', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          loginProvider.overrideWith(_LoggedInNotifier.new),
          loginBannerDismissedProvider.overrideWith(_DismissedNotifier.new),
        ],
        child: MaterialApp.router(routerConfig: _makeRouter()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('登录享受更多服务'), findsNothing);
    });
  });

  group('PersistentBanner × button', () {
    testWidgets('tap × sets dismissed=true and hides banner', (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: _makeRouter())),
      );
      await tester.pumpAndSettle();

      expect(find.text('登录享受更多服务'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.text('登录享受更多服务'), findsNothing);
    });
  });
}
