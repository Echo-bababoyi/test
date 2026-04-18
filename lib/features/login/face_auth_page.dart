import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/in_app_overlay.dart';
import '../../core/widgets/system_dialog.dart';

class FaceAuthPage extends ConsumerStatefulWidget {
  const FaceAuthPage({super.key});

  @override
  ConsumerState<FaceAuthPage> createState() => _FaceAuthPageState();
}

class _FaceAuthPageState extends ConsumerState<FaceAuthPage> {
  // FaceAuthPage 内部子状态：false = 默认双按钮，true = 认证中占位
  bool _isAuthenticating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('身份验证')),
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

  // 请求刷脸认证 InAppOverlay（非阻塞）
  void _showFaceAuthOverlay(BuildContext context) {
    InAppOverlay.show<void>(
      context,
      child: _FaceAuthRequestContent(
        onAgree: () {
          Navigator.of(context).pop();
          _showCameraSystemDialog(context);
        },
        onExit: () => Navigator.of(context).pop(),
      ),
    );
  }

  // 摄像头权限 SystemDialog（阻塞式，自绘 Android 样式）
  void _showCameraSystemDialog(BuildContext context) {
    SystemDialog.show(
      context,
      title: '"浙里办"请求使用摄像头',
      message: '用于进行刷脸身份验证',
      confirmLabel: '使用应用时允许',
      denyLabel: '禁止',
      onConfirm: () {
        // 允许 → 切换到认证中子状态，不跳路由
        setState(() => _isAuthenticating = true);
      },
      // 拒绝 → 弹窗关闭，留在默认状态（onDeny = null 即可）
    );
  }

  // 其他认证方式 InAppOverlay（非阻塞）
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

// ─── 默认状态（双按钮）────────────────────────────────────────────────────────

class _DefaultView extends StatelessWidget {
  final VoidCallback onStartAuth;
  final VoidCallback onOtherMethod;

  const _DefaultView({
    required this.onStartAuth,
    required this.onOtherMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Spacing.xl),
          // 人脸扫描卡片占位
          Container(
            padding: const EdgeInsets.all(Spacing.xl),
            color: Colors.grey[100],
            child: Column(
              children: [
                // 用户名占位（脱敏）
                const Text(
                  '**澄',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: Spacing.xl),
                // 人脸扫描框占位
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                // 说明文字
                const Text(
                  '请进行刷脸认证',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                const Text(
                  '为保障您的账号隐私与信息安全，"浙里办"将获取您的人脸信息进行实人验证',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),
          // 开始认证（主按钮）
          FilledButton(
            onPressed: onStartAuth,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.standardPrimary,
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            ),
            child: const Text('开始认证', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: Spacing.md),
          // 其他方式认证（次要按钮）
          OutlinedButton(
            onPressed: onOtherMethod,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              foregroundColor: AppColors.standardPrimary,
            ),
            child: const Text('其他方式认证', style: TextStyle(fontSize: 16)),
          ),
          const Spacer(),
          // 页脚
          const Center(
            child: Text(
              '浙里办 | 伴你一生大小事',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 认证中子状态（Phase 3 实现动效，Phase 1 静态占位）──────────────────────

class _AuthenticatingView extends StatelessWidget {
  final VoidCallback onComplete;

  const _AuthenticatingView({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 人脸框占位
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.face, size: 80, color: Colors.grey),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          const Text(
            '眨眼 / 摇头动画 — Phase 3 实现',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.xxl),
          // Phase 1 模拟认证成功
          FilledButton(
            onPressed: onComplete,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.standardPrimary,
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            ),
            child: const Text('模拟认证成功 → 长辈版首页'),
          ),
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
        const Text(
          '为保障您的账号隐私与信息安全，"浙里办"将获取您的人脸信息进行实人认证：\n\n请阅读并同意《人脸识别功能协议》',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: Spacing.xl),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onExit,
                child: const Text('退出'),
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
            TextButton(onPressed: onCancel, child: const Text('取消')),
            const Expanded(
              child: Text(
                '其他认证方式',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
            // 右侧占位，保持标题居中
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
          onTap: null, // Phase 1 暂不联通
        ),
      ],
    );
  }
}
