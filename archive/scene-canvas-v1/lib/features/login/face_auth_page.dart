import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/in_app_overlay.dart';
import '../../core/widgets/permission_flow_helper.dart';

class FaceAuthPage extends ConsumerStatefulWidget {
  const FaceAuthPage({super.key});

  @override
  ConsumerState<FaceAuthPage> createState() => _FaceAuthPageState();
}

class _FaceAuthPageState extends ConsumerState<FaceAuthPage> {
  bool _isAuthenticating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _isAuthenticating ? Colors.white : const Color(0xFFDEEAF8),
      appBar: _isAuthenticating
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: () => setState(() => _isAuthenticating = false),
              ),
            )
          : AppBar(
              backgroundColor: const Color(0xFFDEEAF8),
              elevation: 0,
              foregroundColor: AppColors.textPrimary,
              title: const Text('身份验证'),
            ),
      body: _isAuthenticating
          ? _AuthenticatingView(
              onComplete: () {
                ref.read(loginProvider.notifier).login('用户');
                context.go(AppRoutes.elderHome);
              },
            )
          : _DefaultView(
              onStartAuth: () => _showFaceAuthOverlay(context),
              onOtherMethod: () => _showOtherAuthOverlay(context),
            ),
    );
  }

  void _showFaceAuthOverlay(BuildContext context) {
    PermissionFlowHelper.request(
      context: context,
      guideContentBuilder: (onProceed) => _FaceAuthRequestContent(
        onAgree: onProceed,
        onExit: () => Navigator.of(context).pop(),
      ),
      systemTitle: '"浙里办"请求使用摄像头',
      systemMessage: '用于进行刷脸身份验证',
      systemConfirmLabel: '使用应用时允许',
      systemDenyLabel: '禁止',
      onGranted: () => setState(() => _isAuthenticating = true),
    );
  }

  void _showOtherAuthOverlay(BuildContext context) {
    InAppOverlay.show<void>(
      context,
      child: _OtherAuthContent(
        onSmsVerify: () {
          Navigator.of(context).pop();
          context.go(AppRoutes.verify);
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}

// ─── 默认状态（双按钮 + 白卡）────────────────────────────────────────────────

class _DefaultView extends StatelessWidget {
  final VoidCallback onStartAuth;
  final VoidCallback onOtherMethod;

  const _DefaultView({required this.onStartAuth, required this.onOtherMethod});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Spacing.sm),
          // 白色圆角卡片（姓名 + 扫描框 + 说明）
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.xl, Spacing.xl, Spacing.xl, Spacing.lg,
              ),
              child: Column(
                children: [
                  const Text(
                    '**澄',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  const _FaceScanFrame(),
                  const SizedBox(height: Spacing.lg),
                  const Text(
                    '请进行刷脸认证',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  const Text(
                    '为保障您的账号隐私与信息安全，\n"浙里办"将获取您的人脸信息进行实人验证',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          // 开始认证（主按钮）
          FilledButton(
            onPressed: onStartAuth,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.standardPrimary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xlarge),
              ),
            ),
            child: const Text('开始认证', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: Spacing.md),
          // 其他方式认证（次要按钮）
          OutlinedButton(
            onPressed: onOtherMethod,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppColors.standardPrimary,
              side: const BorderSide(color: AppColors.standardPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xlarge),
              ),
            ),
            child: const Text('其他方式认证', style: TextStyle(fontSize: 16)),
          ),
          const Spacer(),
          // 页脚
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sync, size: 16, color: AppColors.standardPrimary),
              SizedBox(width: 4),
              Text(
                '浙里办  |  伴你一生大小事',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.standardPrimary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
        ],
      ),
    );
  }
}

// ─── 人脸扫描框（蓝色四角 + 圆形头像）────────────────────────────────────────

class _FaceScanFrame extends StatelessWidget {
  const _FaceScanFrame();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        children: [
          // 圆形头像
          const Positioned.fill(
            child: Center(child: _FaceAvatar()),
          ),
          // 四角蓝色 L 形
          const Positioned(top: 0, left: 0, child: _CornerBracket()),
          Positioned(
            top: 0,
            right: 0,
            child: Transform.flip(flipX: true, child: const _CornerBracket()),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Transform.flip(flipY: true, child: const _CornerBracket()),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Transform.flip(
              flipX: true,
              flipY: true,
              child: const _CornerBracket(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceAvatar extends StatelessWidget {
  const _FaceAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFD6E8F8),
        border: Border.all(color: const Color(0xFFCCCCCC)),
      ),
      child: const Icon(Icons.person, size: 80, color: Color(0xFF90AECB)),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  const _CornerBracket();

  static const double _len = 24.0;
  static const double _thick = 3.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _len,
      height: _len,
      child: Stack(
        children: const [
          Positioned(
            top: 0,
            left: 0,
            child: ColoredBox(
              color: AppColors.standardPrimary,
              child: SizedBox(width: _len, height: _thick),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: ColoredBox(
              color: AppColors.standardPrimary,
              child: SizedBox(width: _thick, height: _len),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 认证中子状态（Phase 3 实现动效，Phase 2 样式占位）──────────────────────

class _AuthenticatingView extends StatelessWidget {
  final VoidCallback onComplete;

  const _AuthenticatingView({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Spacing.xl),
          const Text(
            '拿起手机，眨眨眼',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.xxl),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 浅蓝外环（Phase 3 替换为脉冲动效）
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x4D2D74DC), // standardPrimary @ 30%
                      width: 6,
                    ),
                  ),
                ),
                // 人脸圆框
                Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFD6E8F8),
                  ),
                  child: const Icon(
                    Icons.face,
                    size: 90,
                    color: Color(0xFF90AECB),
                  ),
                ),
                // 动作提示叠字
                const Positioned(
                  top: 30,
                  child: Text(
                    '眨眨眼',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Phase 3 自动跳转；Phase 2 暂留手动触发入口
          FilledButton(
            onPressed: onComplete,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.standardPrimary,
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xlarge),
              ),
            ),
            child: const Text('进入下一步'),
          ),
          const SizedBox(height: Spacing.lg),
        ],
      ),
    );
  }
}

// ─── 请求刷脸认证浮层内容（InAppOverlay，非阻塞）────────────────────────────

class _FaceAuthRequestContent extends StatelessWidget {
  final VoidCallback onAgree;
  final VoidCallback onExit;

  const _FaceAuthRequestContent({
    required this.onAgree,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '请求刷脸认证',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.md),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: AppFontSize.body,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
            children: [
              TextSpan(
                text: '为保障您的账号隐私与信息安全，"浙里办"将获取您的人脸信息进行实人认证：\n\n请阅读并同意',
              ),
              TextSpan(
                text: '《人脸识别功能协议》',
                style: TextStyle(color: AppColors.standardPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xl),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: AppColors.standardPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xlarge),
                  ),
                ),
                child: const Text('退出'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: FilledButton(
                onPressed: onAgree,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.standardPrimary,
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xlarge),
                  ),
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

// ─── 其他认证方式浮层内容（InAppOverlay，非阻塞）────────────────────────────

class _OtherAuthContent extends StatelessWidget {
  final VoidCallback onSmsVerify;
  final VoidCallback onCancel;

  const _OtherAuthContent({
    required this.onSmsVerify,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('取消'),
            ),
            const Expanded(
              child: Text(
                '其他认证方式',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 56),
          ],
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.email_outlined),
          title: const Text('手机短信验证'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onSmsVerify,
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('密码登录'),
          trailing: const Icon(Icons.chevron_right),
          onTap: null,
        ),
      ],
    );
  }
}
