import 'package:flutter/material.dart';
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

Page<void> _slidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const StandardHome()),
    GoRoute(
      path: '/elder',
      pageBuilder: (_, __) => const NoTransitionPage(child: ElderHome()),
    ),
    GoRoute(path: '/login', pageBuilder: (c, s) => _slidePage(const LoginPage(), s)),
    GoRoute(path: '/login/face', pageBuilder: (c, s) => _slidePage(const FaceAuthPage(), s)),
    GoRoute(path: '/login/verify', pageBuilder: (c, s) => _slidePage(const VerifyPage(), s)),
    GoRoute(path: '/elder/yibao-jiaofei', pageBuilder: (c, s) => _slidePage(const YibaoJiaofeiPage(), s)),
    GoRoute(path: '/elder/yibao-query', pageBuilder: (c, s) => _slidePage(const YibaoQueryPage(), s)),
    GoRoute(path: '/elder/pension-query', pageBuilder: (c, s) => _slidePage(const PensionQueryPage(), s)),
    GoRoute(path: '/elder/search', pageBuilder: (c, s) => _slidePage(const SearchPage(), s)),
    GoRoute(
      path: '/elder/mine',
      pageBuilder: (_, __) => const NoTransitionPage(child: MinePage()),
    ),
    GoRoute(path: '/elder/operation-logs', pageBuilder: (c, s) => _slidePage(const OperationLogsPage(), s)),
    GoRoute(path: '/elder/drafts', pageBuilder: (c, s) => _slidePage(const DraftsPage(), s)),
  ],
);
