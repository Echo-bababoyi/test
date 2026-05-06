import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/agent_element_registry.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  final _phoneKey = AgentElementRegistry.register('input_phone');
  final _sendBtnKey = AgentElementRegistry.register('btn_send_code');
  final _codeKey = AgentElementRegistry.register('input_verify_code');
  final _loginBtnKey = AgentElementRegistry.register('btn_login');

  int _countdown = 0;
  Timer? _timer;

  bool get _canLogin => _codeController.text == '123456';

  @override
  void initState() {
    super.initState();
    AgentElementRegistry.registerController('input_phone', _phoneController);
    AgentElementRegistry.registerController('input_verify_code', _codeController);
    _codeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    AgentElementRegistry.unregister('input_phone');
    AgentElementRegistry.unregister('input_verify_code');
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _sendCode() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdown <= 1) {
        _timer?.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('验证码登录')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            TextField(
              key: _phoneKey,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '手机号',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: _codeKey,
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '验证码',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sms),
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  key: _sendBtnKey,
                  onPressed: _countdown == 0 ? _sendCode : null,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(100, 56)),
                  child: Text(
                    _countdown > 0 ? '${_countdown}s' : '发送',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              key: _loginBtnKey,
              onPressed: _canLogin ? () => context.go('/elder') : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('登录', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
