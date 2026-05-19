import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../theme/design_tokens.dart';
import '../widgets/agent_fab.dart';
import '../widgets/in_app_overlay.dart';
import '../services/agent_element_registry.dart';
import '../services/login_page_snackbar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _loginBtnKey = AgentElementRegistry.register('btn_login');
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    LoginPageSnackbar.showIfPending(context);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEEAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Stack(
        children: [
          Column(
        children: [
          // 顶部：图标 + 欢迎语
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.xl),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.elderPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.xlarge),
                  ),
                  child: const Icon(Icons.sync, color: Colors.white, size: 40),
                ),
                const SizedBox(height: Spacing.lg),
                const Text(
                  '欢迎使用"浙里办"',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1B6E),
                  ),
                ),
              ],
            ),
          ),
          // 底部：白色圆角卡片
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg, Spacing.lg, Spacing.lg, 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 个人 / 法人 Tab
                    Row(
                      children: [
                        const _LoginTab(label: '个人用户', selected: true),
                        Container(
                          width: 1,
                          height: 16,
                          margin: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                          color: AppColors.divider,
                        ),
                        const _LoginTab(label: '法人用户', selected: false),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),
                    // 输入框标签
                    const Text(
                      '手机号/用户名/身份证',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: '请输入',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          borderSide: const BorderSide(
                            color: AppColors.elderPrimary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.md,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    // 条款勾选（装饰性，不控制按钮）
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => setState(() => _agreed = !_agreed),
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _agreed ? AppColors.elderPrimary : null,
                                    border: Border.all(
                                      color: _agreed
                                          ? AppColors.elderPrimary
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  child: _agreed
                                      ? const Icon(Icons.check,
                                          size: 18, color: Colors.white)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(text: '已阅读并同意'),
                                TextSpan(
                                  text: '《用户服务协议》',
                                  style: TextStyle(color: AppColors.elderPrimary),
                                ),
                                TextSpan(text: '和'),
                                TextSpan(
                                  text: '《隐私政策》',
                                  style: TextStyle(color: AppColors.elderPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),
                    // 登录按钮（始终可点击，R7 处理）
                    FilledButton(
                      key: _loginBtnKey,
                      onPressed: () {
                        if (_agreed) {
                          context.push(AppRoutes.faceAuth);
                        } else {
                          _showTermsOverlay(context);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.elderPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xlarge),
                        ),
                      ),
                      child: const Text(
                        '登录',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    // 辅助链接行
                    Row(
                      children: [
                        InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            child: Text('新用户注册',
                                style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            child: Text('忘记密码',
                                style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            child: Text('登录遇到问题?',
                                style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
          const Positioned.fill(
            child: AgentFab(currentPath: AppRoutes.login),
          ),
        ],
      ),
    );
  }

  void _showTermsOverlay(BuildContext context) {
    InAppOverlay.show<void>(
      context,
      child: _TermsOverlayContent(
        onAgree: () {
          Navigator.of(context).pop();
          context.push(AppRoutes.faceAuth);
        },
        onDisagree: () => Navigator.of(context).pop(),
      ),
    );
  }
}

// ─── 个人/法人 Tab 项 ──────────────────────────────────────────────────────────

class _LoginTab extends StatelessWidget {
  final String label;
  final bool selected;

  const _LoginTab({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(4),
      splashColor: AppColors.elderPrimary.withValues(alpha: 0.15),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.elderPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 52,
              color: selected ? AppColors.elderPrimary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 同意条款浮层内容（InAppOverlay，非阻塞）─────────────────────────────────

class _TermsOverlayContent extends StatelessWidget {
  final VoidCallback onAgree;
  final VoidCallback onDisagree;

  const _TermsOverlayContent({
    required this.onAgree,
    required this.onDisagree,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '请阅读并同意以下条款',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.lg),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            children: [
              TextSpan(text: '我已阅读并同意'),
              TextSpan(
                text: '《用户服务协议》',
                style: TextStyle(color: AppColors.elderPrimary),
              ),
              TextSpan(text: '和'),
              TextSpan(
                text: '《隐私政策》',
                style: TextStyle(color: AppColors.elderPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xl),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onDisagree,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: AppColors.elderPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xlarge),
                  ),
                ),
                child: const Text('不同意', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: FilledButton(
                onPressed: onAgree,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.elderPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xlarge),
                  ),
                ),
                child: const Text('同意并继续', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
