import 'package:go_router/go_router.dart';

import '../widgets/phone_frame.dart';

import '../../features/splash/splash_page.dart';
import '../../features/home/standard_home_page.dart';
import '../../features/home/elder_home_page.dart';
import '../../features/login/login_page.dart';
import '../../features/login/face_auth_page.dart';
import '../../features/login/verify_page.dart';
import '../../features/search/search_page.dart';
import '../../features/search/search_result_page.dart';
import '../../features/service/social_insurance_page.dart';
import '../../features/service/pension_query_page.dart';
import '../../features/my/my_page.dart';

class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const elderHome = '/elder';
  static const login = '/login';
  static const faceAuth = '/login/face-auth';
  static const verify = '/login/verify';
  static const search = '/search';
  static const searchResult = '/search/result';
  static const socialInsurance = '/service/social-insurance';
  static const pensionQuery = '/service/pension-query';
  static const my = '/my';

  /// Phase 0 开发导航用：全部 11 个路由的 (显示名, 路径) 列表
  static const List<(String, String)> all = [
    ('SplashPage', splash),
    ('HomePage · 标准版', home),
    ('ElderHomePage · 长辈版', elderHome),
    ('LoginPage', login),
    ('FaceAuthPage', faceAuth),
    ('VerifyPage', verify),
    ('SearchPage', search),
    ('SearchResultPage', searchResult),
    ('SocialInsurancePage', socialInsurance),
    ('PensionQueryPage', pensionQuery),
    ('MyPage', my),
  ];
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    ShellRoute(
      builder: (context, state, child) => PhoneFrame(child: child),
      routes: [
        GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
        GoRoute(path: AppRoutes.home, builder: (_, _) => const StandardHomePage()),
        GoRoute(path: AppRoutes.elderHome, builder: (_, _) => const ElderHomePage()),
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
        GoRoute(path: AppRoutes.faceAuth, builder: (_, _) => const FaceAuthPage()),
        GoRoute(path: AppRoutes.verify, builder: (_, _) => const VerifyPage()),
        GoRoute(path: AppRoutes.search, builder: (_, _) => const SearchPage()),
        GoRoute(path: AppRoutes.searchResult, builder: (_, _) => const SearchResultPage()),
        GoRoute(path: AppRoutes.socialInsurance, builder: (_, _) => const SocialInsurancePage()),
        GoRoute(path: AppRoutes.pensionQuery, builder: (_, _) => const PensionQueryPage()),
        GoRoute(path: AppRoutes.my, builder: (_, _) => const MyPage()),
      ],
    ),
  ],
);
