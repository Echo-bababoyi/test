import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/agent_element_registry.dart';

const _kOrange = Color(0xFFFF6D00);
const _kBg = Color(0xFFF5F5F5);
const _kSurface = Colors.white;
const _kShadow = BoxShadow(
  color: Color(0x0D000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

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

  InputDecoration _inputDecoration({String? label, IconData? prefix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 18, color: Color(0xFF999999)),
      prefixIcon: prefix != null ? Icon(prefix, color: const Color(0xFF999999)) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kOrange, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('验证码登录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [_kShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 56,
                    child: TextField(
                      key: _phoneKey,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(label: '手机号', prefix: Icons.phone),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: TextField(
                            key: _codeKey,
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(label: '验证码', prefix: Icons.sms),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          key: _sendBtnKey,
                          onPressed: _countdown == 0 ? _sendCode : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kOrange,
                            side: const BorderSide(color: _kOrange),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(
                            _countdown > 0 ? '${_countdown}s' : '发送',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                key: _loginBtnKey,
                onPressed: _canLogin ? () => context.go('/elder') : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange,
                  disabledBackgroundColor: const Color(0xFFFFB07A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('登录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
