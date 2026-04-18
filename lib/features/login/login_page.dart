import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/in_app_overlay.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEEAF8), // 淡蓝背景占位
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Column(
          children: [
            const SizedBox(height: Spacing.lg),
            // App 图标占位
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(AppRadius.xlarge),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            // 欢迎标题
            const Text(
              '欢迎使用"浙里办"',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            // 表单白卡
            Container(
              padding: const EdgeInsets.all(Spacing.lg),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 个人 / 法人 Tab 切换占位
                  Row(
                    children: [
                      Text(
                        '个人用户',
                        style: TextStyle(
                          color: AppColors.standardPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: Spacing.xl),
                      const Text(
                        '法人用户',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  const Divider(height: 1),
                  const SizedBox(height: Spacing.lg),
                  // 手机号输入
                  const Text(
                    '手机号/用户名/身份证',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: '请输入',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                        vertical: Spacing.md,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  // 条款勾选占位
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      const Expanded(
                        child: Text(
                          '已阅读并同意《用户服务协议》和《隐私政策》',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  // 登录按钮
                  FilledButton(
                    onPressed: () => _showTermsOverlay(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.standardPrimary,
                      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xlarge),
                      ),
                    ),
                    child: const Text('登录', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: Spacing.md),
                  // 辅助链接行
                  Row(
                    children: const [
                      Text('新用户注册',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      SizedBox(width: Spacing.md),
                      Text('忘记密码',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      Spacer(),
                      Text('登录遇到问题?',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  // 其他登录方式分割线
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: Spacing.sm),
                        child: Text(
                          '其他登录方式',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  const Center(
                    child: Text(
                      '其他证件',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsOverlay(BuildContext context) {
    InAppOverlay.show<void>(
      context,
      child: _TermsOverlayContent(
        onAgree: () {
          Navigator.of(context).pop();
          context.go(AppRoutes.faceAuth);
        },
        onDisagree: () => Navigator.of(context).pop(),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.lg),
        const Text(
          '我已阅读并同意《用户服务协议》和《隐私政策》',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: Spacing.xl),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDisagree,
                child: const Text('不同意'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: FilledButton(
                onPressed: onAgree,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.standardPrimary,
                ),
                child: const Text('同意并继续'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
