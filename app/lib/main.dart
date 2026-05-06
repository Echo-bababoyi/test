import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

void main() {
  runApp(const XiaozheApp());
}

class XiaozheApp extends StatelessWidget {
  const XiaozheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '小浙助手',
      theme: appTheme,
      routerConfig: appRouter,
    );
  }
}
