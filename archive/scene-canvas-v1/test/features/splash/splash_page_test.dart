import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zlb_elder/features/splash/splash_page.dart';

GoRouter _makeRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SplashPage()),
        GoRoute(
          path: '/home',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('home'))),
        ),
      ],
    );

void main() {
  testWidgets('navigates to /home after 1500 ms', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _makeRouter()));
    await tester.pump(); // initial frame

    // Still on splash before timer
    expect(find.byType(SplashPage), findsOneWidget);

    // Advance exactly 1500 ms to fire the delayed callback
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle(); // settle route transition + animations

    expect(find.text('home'), findsOneWidget);
    expect(find.byType(SplashPage), findsNothing);
  });

  testWidgets('mounted guard: no crash when page disposed before timer fires',
      (tester) async {
    late GoRouter router;
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SplashPage()),
        GoRoute(
          path: '/home',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('home'))),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    // Navigate away imperatively before the 1500 ms timer fires
    // → SplashPage.dispose() is called, _navigated still false
    router.go('/home');
    await tester.pump();

    // Now advance past 1500 ms — the delayed callback fires but mounted=false
    // → should be a no-op, no crash
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump();

    expect(find.text('home'), findsOneWidget); // still on /home
  });

  testWidgets('_navigated guard prevents redundant navigation', (tester) async {
    // Pump, wait for timer, verify exactly one navigation occurred
    final router = _makeRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();

    expect(find.text('home'), findsOneWidget);
    // Advance further — _navigated=true means no second go() is called
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    expect(find.text('home'), findsOneWidget);
  });
}
