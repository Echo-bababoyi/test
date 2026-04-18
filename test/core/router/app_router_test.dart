import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zlb_elder/core/router/app_router.dart';
import 'package:zlb_elder/core/widgets/phone_frame.dart';
import 'package:zlb_elder/features/splash/splash_page.dart';
import 'package:zlb_elder/features/home/standard_home_page.dart';
import 'package:zlb_elder/features/home/elder_home_page.dart';
import 'package:zlb_elder/features/login/login_page.dart';
import 'package:zlb_elder/features/login/face_auth_page.dart';
import 'package:zlb_elder/features/login/verify_page.dart';
import 'package:zlb_elder/features/search/search_page.dart';
import 'package:zlb_elder/features/search/search_result_page.dart';
import 'package:zlb_elder/features/service/social_insurance_page.dart';
import 'package:zlb_elder/features/service/pension_query_page.dart';
import 'package:zlb_elder/features/my/my_page.dart';

// Creates a fresh GoRouter (same shape as appRouter) to avoid shared state.
GoRouter _makeFreshRouter(String initialLocation) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        ShellRoute(
          builder: (context, state, child) => PhoneFrame(child: child),
          routes: [
            GoRoute(
                path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
            GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const StandardHomePage()),
            GoRoute(
              path: AppRoutes.elderHome,
              pageBuilder: (_, _) =>
                  const NoTransitionPage(child: ElderHomePage()),
            ),
            GoRoute(
                path: AppRoutes.login, builder: (_, _) => const LoginPage()),
            GoRoute(
                path: AppRoutes.faceAuth,
                builder: (_, _) => const FaceAuthPage()),
            GoRoute(
                path: AppRoutes.verify, builder: (_, _) => const VerifyPage()),
            GoRoute(
                path: AppRoutes.search,
                builder: (_, _) => const SearchPage()),
            GoRoute(
                path: AppRoutes.searchResult,
                builder: (_, _) => const SearchResultPage()),
            GoRoute(
                path: AppRoutes.socialInsurance,
                builder: (_, _) => const SocialInsurancePage()),
            GoRoute(
                path: AppRoutes.pensionQuery,
                builder: (_, _) => const PensionQueryPage()),
            GoRoute(
              path: AppRoutes.my,
              pageBuilder: (_, _) =>
                  const NoTransitionPage(child: MyPage()),
            ),
          ],
        ),
      ],
    );

void main() {
  // 11 route smoke tests — each verifies: no crash + PhoneFrame wrapping
  for (final (name, path) in AppRoutes.all) {
    testWidgets('Smoke: $name renders inside PhoneFrame', (tester) async {
      // searchResult requires a query param; provide one
      final initLoc =
          path == AppRoutes.searchResult ? '$path?q=smoke' : path;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: _makeFreshRouter(initLoc),
          ),
        ),
      );

      // For SplashPage, advance past its 1500 ms timer to avoid "pending timer"
      // assertion failure. For all other routes a single pump is sufficient.
      if (path == AppRoutes.splash) {
        await tester.pump(const Duration(milliseconds: 1500));
        await tester.pump(); // settle navigation
      } else {
        await tester.pump();
      }

      // Every route is wrapped in ShellRoute → PhoneFrame
      expect(
        find.byType(PhoneFrame),
        findsOneWidget,
        reason: 'ShellRoute should wrap $name in PhoneFrame',
      );

      // Every page widget is a Scaffold
      expect(find.byType(Scaffold), findsWidgets);
    });
  }
}
