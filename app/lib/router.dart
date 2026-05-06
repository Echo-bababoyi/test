import 'package:go_router/go_router.dart';
import 'pages/standard_home.dart';
import 'pages/elder_home.dart';
import 'pages/login_page.dart';
import 'pages/face_auth_page.dart';
import 'pages/verify_page.dart';
import 'pages/yibao_jiaofei_page.dart';
import 'pages/yibao_query_page.dart';
import 'pages/pension_query_page.dart';
import 'pages/search_page.dart';
import 'pages/mine_page.dart';
import 'pages/operation_logs_page.dart';
import 'pages/drafts_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const StandardHome()),
    GoRoute(path: '/elder', builder: (_, __) => const ElderHome()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/login/face', builder: (_, __) => const FaceAuthPage()),
    GoRoute(path: '/login/verify', builder: (_, __) => const VerifyPage()),
    GoRoute(path: '/elder/yibao-jiaofei', builder: (_, __) => const YibaoJiaofeiPage()),
    GoRoute(path: '/elder/yibao-query', builder: (_, __) => const YibaoQueryPage()),
    GoRoute(path: '/elder/pension-query', builder: (_, __) => const PensionQueryPage()),
    GoRoute(path: '/elder/search', builder: (_, __) => const SearchPage()),
    GoRoute(path: '/elder/mine', builder: (_, __) => const MinePage()),
    GoRoute(path: '/elder/operation-logs', builder: (_, __) => const OperationLogsPage()),
    GoRoute(path: '/elder/drafts', builder: (_, __) => const DraftsPage()),
  ],
);
