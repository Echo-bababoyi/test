import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zlb_elder/core/router/app_router.dart';
import 'package:zlb_elder/core/widgets/phone_frame.dart';
import 'package:zlb_elder/features/home/elder_home_page.dart';

// Minimal router that includes only the routes ElderHomePage navigates to
GoRouter _makeRouter() => GoRouter(
      initialLocation: AppRoutes.elderHome,
      routes: [
        ShellRoute(
          builder: (_, _, child) => PhoneFrame(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.elderHome,
              pageBuilder: (_, _) =>
                  const NoTransitionPage(child: ElderHomePage()),
            ),
            GoRoute(
              path: AppRoutes.my,
              builder: (_, _) => const Scaffold(body: SizedBox()),
            ),
            GoRoute(
              path: AppRoutes.search,
              builder: (_, _) => const Scaffold(body: SizedBox()),
            ),
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) => const Scaffold(body: SizedBox()),
            ),
          ],
        ),
      ],
    );

void main() {
  testWidgets(
    'Tab switch: 政务热线区块 not rebuilt (ListenableBuilder partial-rebuild)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: _makeRouter())),
      );
      await tester.pumpAndSettle();

      // Hotline section should be in the tree before switch
      expect(find.byKey(const ValueKey('eld_hotline')), findsOneWidget);

      final hotlineBefore =
          tester.element(find.byKey(const ValueKey('eld_hotline')));

      // Tap '我的常用' tab (index 1)
      await tester.tap(find.text('我的常用').first);
      await tester.pump();

      final hotlineAfter =
          tester.element(find.byKey(const ValueKey('eld_hotline')));

      expect(
        identical(hotlineBefore, hotlineAfter),
        isTrue,
        reason: '政务热线区在 Tab 切换时 Element 身份不变 — ListenableBuilder 仅重建 IndexedStack',
      );
    },
  );

  testWidgets(
    'Tab switch: 线上一站办区块 not rebuilt',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: _makeRouter())),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('eld_online')), findsOneWidget);

      final onlineBefore =
          tester.element(find.byKey(const ValueKey('eld_online')));

      // Switch to tab 2 (我的订阅)
      await tester.tap(find.text('我的订阅').first);
      await tester.pump();

      final onlineAfter =
          tester.element(find.byKey(const ValueKey('eld_online')));

      expect(identical(onlineBefore, onlineAfter), isTrue);
    },
  );

  testWidgets('Tab labels are all visible on initial render', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _makeRouter())),
    );
    await tester.pumpAndSettle();

    expect(find.text('热门服务'), findsOneWidget);
    expect(find.text('我的常用'), findsOneWidget);
    expect(find.text('我的订阅'), findsOneWidget);
  });
}
