import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_state.dart';

const _kOrange = Color(0xFFFF6D00);
const _kBg = Color(0xFFF5F5F5);

class StandardHome extends StatefulWidget {
  const StandardHome({super.key});

  @override
  State<StandardHome> createState() => _StandardHomeState();
}

class _StandardHomeState extends State<StandardHome> {
  @override
  void initState() {
    super.initState();
    // 已登录直接进长辈版
    if (AuthState.instance.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/elder');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // 顶部 logo + 标题区
              Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _kOrange,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _kOrange.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.security, color: Colors.white, size: 56),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '浙里办',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '小浙助手 · 适老化政务服务',
                    style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // 进入长辈版主按钮
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/elder'),
                  icon: const Icon(Icons.accessibility_new, size: 24),
                  label: const Text('进入长辈版', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 登录文字按钮
              TextButton(
                onPressed: () => context.push('/login'),
                child: const Text(
                  '登录账号',
                  style: TextStyle(fontSize: 18, color: _kOrange),
                ),
              ),

              const Spacer(flex: 1),

              // 底部版本信息
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Version 1.0.0  ·  浙江政务服务平台',
                  style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
