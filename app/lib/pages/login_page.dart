import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/agent_element_registry.dart';

const _kOrange = Color(0xFFFF6D00);
const _kBg = Color(0xFFF5F5F5);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _agreed = false;

  final _chkKey = AgentElementRegistry.register('chk_agree_terms');
  final _faceBtnKey = AgentElementRegistry.register('btn_face_login');
  final _verifyBtnKey = AgentElementRegistry.register('btn_verify_login');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部 logo/标题区
            Container(
              color: _kOrange,
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security, size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text('小浙助手', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text('安全登录，享受便民服务', style: TextStyle(fontSize: 16, color: Colors.white70)),
                ],
              ),
            ),

            // 中部表单区（登录方式选择）
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('选择登录方式', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        key: _faceBtnKey,
                        onPressed: _agreed ? () => context.push('/login/face') : null,
                        icon: const Icon(Icons.face, size: 24),
                        label: const Text('刷脸登录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kOrange,
                          disabledBackgroundColor: const Color(0xFFFFB07A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        key: _verifyBtnKey,
                        onPressed: _agreed ? () => context.push('/login/verify') : null,
                        icon: const Icon(Icons.sms, size: 24),
                        label: const Text('验证码登录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kOrange,
                          side: const BorderSide(color: _kOrange, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 底部协议区
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                children: [
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      key: _chkKey,
                      value: _agreed,
                      activeColor: _kOrange,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                    ),
                  ),
                  const Expanded(
                    child: Text('我已阅读并同意《用户协议》和《隐私政策》', style: TextStyle(fontSize: 15, color: Color(0xFF666666))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
