import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/state/app_state.dart';
import '../router.dart';
import '../theme/design_tokens.dart';
import '../widgets/agent_fab.dart';
import '../widgets/in_app_overlay.dart';
import '../widgets/permission_flow_helper.dart';
import '../services/agent_element_registry.dart';

class FaceAuthPage extends ConsumerStatefulWidget {
  const FaceAuthPage({super.key});

  @override
  ConsumerState<FaceAuthPage> createState() => _FaceAuthPageState();
}

class _FaceAuthPageState extends ConsumerState<FaceAuthPage> {
  static const _kDemoMode = bool.fromEnvironment('DEMO_MODE');
  bool _isAuthenticating = _kDemoMode;

  final _faceBtnKey = AgentElementRegistry.register('btn_face_login');
  final _otherBtnKey = AgentElementRegistry.register('btn_other_auth');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: AppColors.textPrimary,
              title: const Text('身份验证'),
            ),
      extendBodyBehindAppBar: !_isAuthenticating,
      body: Container(
        decoration: _isAuthenticating
            ? const BoxDecoration(color: Colors.white)
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF3E0), Color(0xFFFFF8F2), Color(0xFFFFFBF8)],
                ),
              ),
        child: Stack(
          children: [
            if (!_isAuthenticating) ...[
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0x15FF6D00), const Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0x10FF6D00), const Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
            ],
            _isAuthenticating
                ? _AuthenticatingView(
                    onComplete: () {
                      ref.read(loginProvider.notifier).login('用户');
                      context.go(AppRoutes.elderHome);
                    },
                  )
                : _DefaultView(
                    startAuthKey: _faceBtnKey,
                    otherMethodKey: _otherBtnKey,
                    onStartAuth: () => _showFaceAuthOverlay(context),
                    onOtherMethod: () => _showOtherAuthOverlay(context),
                  ),
            Positioned.fill(
              child: AgentFab(currentPath: AppRoutes.faceAuth),
            ),
          ],
        ),
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
          context.push(AppRoutes.verify);
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
  final GlobalKey? startAuthKey;
  final GlobalKey? otherMethodKey;

  const _DefaultView({
    required this.onStartAuth,
    required this.onOtherMethod,
    this.startAuthKey,
    this.otherMethodKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 72),
          // 白色圆角卡片（姓名 + 扫描框 + 说明）
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x0FFF6D00), blurRadius: 24, offset: Offset(0, 8)),
                BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFFF8A3C), Color(0xFFFF6D00)]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    children: [
                      const Text(
                        '**澄',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: Spacing.lg),
                      const _FaceScanFrame(),
                      const SizedBox(height: Spacing.lg),
                      const Text(
                        '请进行刷脸认证',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: Spacing.sm),
                      const Text(
                        '为保障您的账号隐私与信息安全，\n"浙里办"将获取您的人脸信息进行实人验证',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          // 开始认证（主按钮 — 渐变 + 阴影 + 图标）
          Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF8A3C), Color(0xFFFF6D00)]),
              borderRadius: BorderRadius.circular(AppRadius.xlarge),
              boxShadow: const [
                BoxShadow(color: Color(0x33FF6D00), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.xlarge),
              child: InkWell(
                key: startAuthKey,
                onTap: onStartAuth,
                borderRadius: BorderRadius.circular(AppRadius.xlarge),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('开始认证', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          // 其他方式认证（次要按钮）
          OutlinedButton(
            key: otherMethodKey,
            onPressed: onOtherMethod,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppColors.elderPrimary,
              side: const BorderSide(color: AppColors.elderPrimary),
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
              Icon(Icons.sync, size: 16, color: AppColors.elderPrimary),
              SizedBox(width: 4),
              Text(
                '浙里办  |  伴你一生大小事',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.elderPrimary,
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
          const Positioned.fill(child: Center(child: _FaceAvatar())),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0E6), Color(0xFFFFF8F2)],
        ),
        border: Border.all(
          color: const Color(0xFFFF8A3C).withValues(alpha: 0.4),
          width: 2.5,
        ),
      ),
      child: const Icon(Icons.face_retouching_natural, size: 64, color: Color(0xFFFF8A3C)),
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
      child: const Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: ColoredBox(
              color: const Color(0xFFFF6D00),
              child: SizedBox(width: _len, height: _thick),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: ColoredBox(
              color: const Color(0xFFFF6D00),
              child: SizedBox(width: _thick, height: _len),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 认证中子状态 ──────────────────────────────────────────────────────────────

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
          const SizedBox(height: 60),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x4DFF6D00),
                      width: 6,
                    ),
                  ),
                ),
                Container(
                  width: 190,
                  height: 190,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFF0E6),
                  ),
                  child: const Icon(Icons.face, size: 100, color: Color(0xFFFF8A3C)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '请缓慢左右摇头',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '正在进行人脸识别，请保持面部在框内',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─── 请求刷脸认证浮层内容 ────────────────────────────────────────────────────

class _FaceAuthRequestContent extends StatelessWidget {
  final VoidCallback onAgree;
  final VoidCallback onExit;

  const _FaceAuthRequestContent({required this.onAgree, required this.onExit});

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
                onPressed: onExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: AppColors.elderPrimary,
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
                  backgroundColor: AppColors.elderPrimary,
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

// ─── 其他认证方式浮层内容 ────────────────────────────────────────────────────

class _OtherAuthContent extends StatelessWidget {
  final VoidCallback onSmsVerify;
  final VoidCallback onCancel;

  const _OtherAuthContent({required this.onSmsVerify, required this.onCancel});

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
