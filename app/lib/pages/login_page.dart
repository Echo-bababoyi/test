import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/agent_element_registry.dart';

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
      appBar: AppBar(title: const Text('登录')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Text('选择登录方式', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              key: _faceBtnKey,
              onPressed: _agreed ? () => context.push('/login/face') : null,
              icon: const Icon(Icons.face),
              label: const Text('刷脸登录', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: _verifyBtnKey,
              onPressed: _agreed ? () => context.push('/login/verify') : null,
              icon: const Icon(Icons.sms),
              label: const Text('验证码登录', style: TextStyle(fontSize: 20)),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            ),
            const Spacer(),
            Row(
              children: [
                Checkbox(
                  key: _chkKey,
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                ),
                const Expanded(
                  child: Text('我已阅读并同意《用户协议》和《隐私政策》', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
