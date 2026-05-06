import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/agent_element_registry.dart';

const _kOrange = Color(0xFFFF6D00);
const _kBannerBg = Color(0xFFFFF3E0);

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
      backgroundColor: _kBannerBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 顶部 logo/标题区（橙色调背景）
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _kOrange,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _kOrange.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.security, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 16),
                const Text(
                  '小浙助手',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 6),
                const Text(
                  '安全便捷，一站式政务服务',
                  style: TextStyle(fontSize: 15, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),

          // 底部白色圆角卡片（登录方式选择 + 协议）
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('选择登录方式', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                    const SizedBox(height: 28),

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
                    const SizedBox(height: 32),

                    // 协议勾选区
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: Checkbox(
                            key: _chkKey,
                            value: _agreed,
                            activeColor: _kOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (v) => setState(() => _agreed = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                              children: [
                                TextSpan(text: '我已阅读并同意'),
                                TextSpan(text: '《用户协议》', style: TextStyle(color: _kOrange)),
                                TextSpan(text: '和'),
                                TextSpan(text: '《隐私政策》', style: TextStyle(color: _kOrange)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_agreed)
                      const Text(
                        '请先勾选同意协议才能登录',
                        style: TextStyle(fontSize: 13, color: Color(0xFFFF6D00)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
