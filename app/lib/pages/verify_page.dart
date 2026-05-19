import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/state/app_state.dart';
import '../router.dart';
import '../theme/design_tokens.dart';
import '../widgets/agent_fab.dart';
import '../widgets/system_dialog.dart';
import '../services/agent_element_registry.dart';

class VerifyPage extends ConsumerStatefulWidget {
  const VerifyPage({super.key});

  @override
  ConsumerState<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends ConsumerState<VerifyPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();

  final _phoneKey = AgentElementRegistry.register('input_phone');
  final _sendBtnKey = AgentElementRegistry.register('btn_send_code');
  final _codeKey = AgentElementRegistry.register('input_verify_code');
  final _loginBtnKey = AgentElementRegistry.register('btn_verify_login');

  int _countdown = 0;
  Timer? _timer;

  bool get _phoneValid {
    final p = _phoneController.text;
    return p.length == 11 && p.startsWith('1');
  }

  bool get _phoneInvalid => _phoneController.text.isNotEmpty && !_phoneValid;

  bool get _canLogin => _codeController.text == '123456';

  @override
  void initState() {
    super.initState();
    AgentElementRegistry.registerController('input_phone', _phoneController);
    AgentElementRegistry.registerController('input_verify_code', _codeController);
    _phoneController.addListener(() => setState(() {}));
    _codeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    AgentElementRegistry.unregister('input_phone');
    AgentElementRegistry.unregister('input_verify_code');
    _phoneController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _sendCode() {
    if (!_phoneValid) return;
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
    _codeFocusNode.requestFocus();
  }

  void _confirmSmsCode(BuildContext context) {
    SystemDialog.show(
      context,
      title: '验证码确认',
      message: '验证码已验证，即将完成登录',
      confirmLabel: '确认',
      denyLabel: '取消',
      onConfirm: () {
        ref.read(loginProvider.notifier).login('用户');
        context.go(AppRoutes.elderHome);
      },
    );
  }

  InputDecoration _inputDecoration({String? label, IconData? prefix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: AppFontSize.elderBody, color: AppColors.textSecondary),
      prefixIcon: prefix != null ? Icon(prefix, color: AppColors.textSecondary) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.standardPrimary, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEEAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('短信验证登录'),
      ),
      body: Stack(
        children: [
          Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '请输入验证码',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            const Text(
              '输入手机号并获取验证码完成登录',
              style: TextStyle(fontSize: AppFontSize.body, color: AppColors.textSecondary),
            ),
            const SizedBox(height: Spacing.xl),
            // 输入卡片
            Container(
              padding: const EdgeInsets.all(Spacing.xl),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.large),
                boxShadow: const [
                  BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
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
                      style: const TextStyle(fontSize: AppFontSize.elderBody),
                    ),
                  ),
                  if (_phoneInvalid)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        '请输入11位手机号（首位为1）',
                        style: TextStyle(fontSize: AppFontSize.caption, color: Color(0xFFFF3B30)),
                      ),
                    ),
                  const SizedBox(height: Spacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: TextField(
                            key: _codeKey,
                            controller: _codeController,
                            focusNode: _codeFocusNode,
                            keyboardType: TextInputType.number,
                            autofocus: false,
                            decoration: _inputDecoration(label: '验证码', prefix: Icons.sms),
                            style: const TextStyle(fontSize: AppFontSize.elderBody),
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          key: _sendBtnKey,
                          onPressed: (_countdown == 0 && _phoneValid) ? _sendCode : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.standardPrimary,
                            side: const BorderSide(color: AppColors.standardPrimary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.medium),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                          ),
                          child: Text(
                            _countdown > 0 ? '${_countdown}s 后重发' : '发送',
                            style: const TextStyle(fontSize: AppFontSize.bodyLarge, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  // 重新发送倒计时提示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _countdown > 0 ? '重新发送 $_countdown秒' : '点击"发送"获取验证码',
                        style: const TextStyle(fontSize: AppFontSize.body, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xl),
            // 确认登录按钮
            FilledButton(
              key: _loginBtnKey,
              onPressed: _canLogin ? () => _confirmSmsCode(context) : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.standardPrimary,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xlarge),
                ),
              ),
              child: const Text('确认', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
          const Positioned.fill(
            child: AgentFab(currentPath: AppRoutes.verify),
          ),
        ],
      ),
    );
  }
}
