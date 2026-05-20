import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/splash_page.dart';
import 'pages/standard_home.dart';
import 'pages/elder_home.dart';
import 'pages/login_page.dart';
import 'pages/face_auth_page.dart';
import 'pages/verify_page.dart';
import 'pages/search_page.dart';
import 'pages/search_result_page.dart';
import 'pages/mine_page.dart';
import 'pages/shebao_jiaona_page.dart';
import 'pages/shebao_query_page.dart';
import 'pages/pension_query_page.dart';
import 'pages/yibao_jiaofei_page.dart';
import 'pages/yibao_query_page.dart';
import 'pages/yibao_hub_page.dart';
import 'pages/pay_confirm_page.dart';
import 'pages/pay_password_page.dart';
import 'pages/pay_result_page.dart';
import 'pages/operation_logs_page.dart';
import 'pages/drafts_page.dart';
import 'pages/agent_settings_page.dart';
import 'pages/wireframe_page.dart';
import 'widgets/phone_frame.dart';

class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const elderHome = '/elder';
  static const login = '/login';
  static const faceAuth = '/login/face';
  static const verify = '/login/verify';
  static const search = '/search';
  static const searchResult = '/search/result';
  static const my = '/my';
  static const shebaoJiaona = '/service/shebao-jiaona';
  static const shebaoQuery = '/service/shebao-query';
  static const pensionQuery = '/service/pension-query';
  static const yibaoJiaofei = '/service/yibao-jiaofei';
  static const yibaoQuery = '/service/yibao-query';
  static const yibaoHub = '/service/yibao-hub';
  static const yibaoJiaofeiConfirm = '/service/yibao-jiaofei/confirm';
  static const yibaoJiaofeiPay = '/service/yibao-jiaofei/pay';
  static const yibaoJiaofeiResult = '/service/yibao-jiaofei/result';
  static const operationLogs = '/elder/operation-logs';
  static const drafts = '/elder/drafts';
  static const agentSettings = '/elder/agent-settings';
  static const wireframe0 = '/wireframe/0';
  static const wireframe1 = '/wireframe/1';
  static const wireframe2 = '/wireframe/2';
  static const wireframe3 = '/wireframe/3';
  static const wireframe4 = '/wireframe/4';
  static const wireframe5 = '/wireframe/5';

  static const all = [
    ('闪屏页', splash),
    ('标准首页', home),
    ('长辈首页', elderHome),
    ('登录', login),
    ('刷脸认证', faceAuth),
    ('验证码', verify),
    ('搜索', search),
    ('搜索结果', searchResult),
    ('我的', my),
    ('社保费缴纳', shebaoJiaona),
    ('社保查询', shebaoQuery),
    ('养老金查询', pensionQuery),
    ('医保 hub', yibaoHub),
    ('医保缴费', yibaoJiaofei),
    ('医保查询', yibaoQuery),
    ('操作日志', operationLogs),
    ('草稿箱', drafts),
    ('小浙设置', agentSettings),
  ];
}

Page<T> _fadePage<T>(Widget child) => CustomTransitionPage<T>(
      child: child,
      transitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (ctx, animation, secondary, child) =>
          FadeTransition(opacity: animation, child: child),
    );

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    ShellRoute(
      builder: (context, state, child) => PhoneFrame(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          pageBuilder: (ctx, st) => const NoTransitionPage(child: SplashPage()),
        ),
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (ctx, st) => _fadePage(const StandardHome()),
        ),
        GoRoute(
          path: AppRoutes.elderHome,
          pageBuilder: (ctx, st) => const NoTransitionPage(child: ElderHome()),
        ),
        GoRoute(
          path: AppRoutes.login,
          pageBuilder: (ctx, st) => _fadePage(const LoginPage()),
        ),
        GoRoute(
          path: AppRoutes.faceAuth,
          pageBuilder: (ctx, st) => _fadePage(const FaceAuthPage()),
        ),
        GoRoute(
          path: AppRoutes.verify,
          pageBuilder: (ctx, st) => _fadePage(const VerifyPage()),
        ),
        GoRoute(
          path: AppRoutes.search,
          pageBuilder: (ctx, st) => _fadePage(const SearchPage()),
        ),
        GoRoute(
          path: AppRoutes.searchResult,
          pageBuilder: (ctx, st) => _fadePage(const SearchResultPage()),
        ),
        GoRoute(
          path: AppRoutes.my,
          pageBuilder: (ctx, st) => const NoTransitionPage(child: MinePage()),
        ),
        GoRoute(
          path: AppRoutes.shebaoJiaona,
          pageBuilder: (ctx, st) => _fadePage(const ShebaoJiaonaPage()),
        ),
        GoRoute(
          path: AppRoutes.shebaoQuery,
          pageBuilder: (ctx, st) => _fadePage(const ShebaoQueryPage()),
        ),
        GoRoute(
          path: AppRoutes.pensionQuery,
          pageBuilder: (ctx, st) => _fadePage(const PensionQueryPage()),
        ),
        GoRoute(
          path: AppRoutes.yibaoJiaofei,
          pageBuilder: (ctx, st) => _fadePage(const YibaoJiaofeiPage()),
        ),
        GoRoute(
          path: AppRoutes.yibaoQuery,
          pageBuilder: (ctx, st) => _fadePage(const YibaoQueryPage()),
        ),
        GoRoute(
          path: AppRoutes.yibaoHub,
          pageBuilder: (ctx, st) => _fadePage(const YibaoHubPage()),
        ),
        GoRoute(
          path: AppRoutes.yibaoJiaofeiConfirm,
          pageBuilder: (ctx, st) => _fadePage(const PayConfirmPage()),
        ),
        GoRoute(
          path: AppRoutes.yibaoJiaofeiPay,
          pageBuilder: (ctx, st) => _fadePage(const PayPasswordPage()),
        ),
        GoRoute(
          path: AppRoutes.yibaoJiaofeiResult,
          pageBuilder: (ctx, st) => _fadePage(const PayResultPage()),
        ),
        GoRoute(
          path: AppRoutes.operationLogs,
          pageBuilder: (ctx, st) => _fadePage(const OperationLogsPage()),
        ),
        GoRoute(
          path: AppRoutes.drafts,
          pageBuilder: (ctx, st) => _fadePage(const DraftsPage()),
        ),
        GoRoute(
          path: AppRoutes.agentSettings,
          pageBuilder: (ctx, st) => _fadePage(const AgentSettingsPage()),
        ),
        GoRoute(path: AppRoutes.wireframe0, pageBuilder: (ctx, st) => _fadePage(const WireframePage(index: 0))),
        GoRoute(path: AppRoutes.wireframe1, pageBuilder: (ctx, st) => _fadePage(const WireframePage(index: 1))),
        GoRoute(path: AppRoutes.wireframe2, pageBuilder: (ctx, st) => _fadePage(const WireframePage(index: 2))),
        GoRoute(path: AppRoutes.wireframe3, pageBuilder: (ctx, st) => _fadePage(const WireframePage(index: 3))),
        GoRoute(path: AppRoutes.wireframe4, pageBuilder: (ctx, st) => _fadePage(const WireframePage(index: 4))),
        GoRoute(path: AppRoutes.wireframe5, pageBuilder: (ctx, st) => _fadePage(const WireframePage(index: 5))),
      ],
    ),
  ],
);
