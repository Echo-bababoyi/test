import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';

class ZlbElderApp extends ConsumerWidget {
  const ZlbElderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);
    return MaterialApp.router(
      title: '浙里办长辈版',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.of(mode),
      routerConfig: appRouter,
    );
  }
}
