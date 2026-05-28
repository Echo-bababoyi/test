import 'dart:html' as html; // ignore: avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';

void main() {
  _maybeResetStorage();
  _clearSessionScopedKeys();
  runApp(const ProviderScope(child: ZlbElderApp()));
}

void _maybeResetStorage() {
  if (!Uri.base.queryParameters.containsKey('reset')) return;
  final store = html.window.localStorage;
  final keys = store.keys.where((k) => k.startsWith('xiaozhe_')).toList();
  for (final k in keys) {
    store.remove(k);
  }
  store.remove('app_mode');
  html.window.indexedDB?.deleteDatabase('xiaozhe_draft');
  final loc = html.window.location;
  html.window.history.replaceState(null, '', '${loc.pathname}${loc.hash}');
}

void _clearSessionScopedKeys() {
  final store = html.window.localStorage;
  store.remove('xiaozhe_trust_level');
  store.remove('xiaozhe_first_choice_shown');
  store.remove('xiaozhe_profile_phone');
  store.remove('xiaozhe_profile_idcard');
}

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
