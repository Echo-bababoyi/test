import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/state/app_state.dart';
import '../router.dart';
import '../theme/design_tokens.dart';
import '../widgets/agent_fab.dart';
import '../widgets/in_app_overlay.dart';
import '../widgets/system_dialog.dart';
import '../widgets/camera_view.dart';
import '../services/agent_element_registry.dart';
import '../services/camera_service.dart';
import '../services/face_detector_service.dart';
import '../services/login_page_snackbar.dart';

enum _TopState { prepare, authenticating, permissionDenied }

class FaceAuthPage extends ConsumerStatefulWidget {
  const FaceAuthPage({super.key});

  @override
  ConsumerState<FaceAuthPage> createState() => _FaceAuthPageState();
}

class _FaceAuthPageState extends ConsumerState<FaceAuthPage> {
  static const _kDemoMode = bool.fromEnvironment('DEMO_MODE');
  _TopState _top = _kDemoMode ? _TopState.authenticating : _TopState.prepare;

  final _faceBtnKey = AgentElementRegistry.register('btn_face_login');
  final _otherBtnKey = AgentElementRegistry.register('btn_other_auth');

  void _exitToLogin() {
    if (mounted) context.pop();
  }

  void _onAllSuccess() {
    ref.read(loginProvider.notifier).login('用户');
    context.go(AppRoutes.elderHome);
  }

  @override
  Widget build(BuildContext context) {
    final isPrepare = _top == _TopState.prepare;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: isPrepare
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: AppColors.textPrimary,
              title: const Text('身份验证'),
            )
          : null,
      extendBodyBehindAppBar: isPrepare,
      body: Container(
        decoration: isPrepare
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF3E0), Color(0xFFFFF8F2), Color(0xFFFFFBF8)],
                ),
              )
            : const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Stack(
            children: [
              if (isPrepare) ...[
                Positioned(top: -40, right: -30, child: _bgCircle(180, 0x15FF6D00)),
                Positioned(bottom: 100, left: -40, child: _bgCircle(120, 0x10FF6D00)),
              ],
              _buildBody(),
              if (isPrepare)
                Positioned.fill(child: AgentFab(currentPath: AppRoutes.faceAuth)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bgCircle(double size, int colorVal) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(colorVal), const Color(0x00FFFFFF)],
          ),
        ),
      );

  Widget _buildBody() {
    switch (_top) {
      case _TopState.prepare:
        return _DefaultView(
          startAuthKey: _faceBtnKey,
          otherMethodKey: _otherBtnKey,
          onStartAuth: () => _showFaceAuthOverlay(context),
          onOtherMethod: () => _showOtherAuthOverlay(context),
        );
      case _TopState.permissionDenied:
        return _PermissionDeniedView(onExit: _exitToLogin);
      case _TopState.authenticating:
        return _AuthFlow(
          onComplete: _onAllSuccess,
          onExit: _exitToLogin,
          onPermissionFailed: () =>
              setState(() => _top = _TopState.permissionDenied),
        );
    }
  }

  void _showFaceAuthOverlay(BuildContext context) {
    InAppOverlay.show<void>(
      context,
      child: _FaceAuthRequestContent(
        onAgree: () {
          Navigator.of(context).pop();
          SystemDialog.show(
            context,
            title: '"浙里办"请求使用摄像头',
            message: '用于进行刷脸身份验证',
            confirmLabel: '使用应用时允许',
            denyLabel: '禁止',
            onConfirm: () =>
                setState(() => _top = _TopState.authenticating),
            onDeny: () =>
                setState(() => _top = _TopState.permissionDenied),
          );
        },
        onExit: () => Navigator.of(context).pop(),
      ),
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                        style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '您的人脸只在本机比对，不会上传保存',
                        style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
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
                      Text('开始认证', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)),
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
            child: const Text('其他方式认证', style: TextStyle(fontSize: 18)),
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
                  fontSize: 16,
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

class _CornerBracket extends StatefulWidget {
  const _CornerBracket();

  @override
  State<_CornerBracket> createState() => _CornerBracketState();
}

class _CornerBracketState extends State<_CornerBracket>
    with SingleTickerProviderStateMixin {
  static const double _len = 24.0;
  static const double _thick = 3.0;

  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _len,
      height: _len,
      child: FadeTransition(
        opacity: _opacity,
        child: const Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: ColoredBox(
                color: Color(0xFFFF6D00),
                child: SizedBox(width: _len, height: _thick),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: ColoredBox(
                color: Color(0xFFFF6D00),
                child: SizedBox(width: _thick, height: _len),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 认证流程状态机 S3-S9 ─────────────────────────────────────────────────────

enum _SubState {
  cameraInit,         // S3
  faceAlign,          // S4
  blinkDetecting,     // S5
  blinkSuccess,       // S6 (1s pause)
  headTurnDetecting,  // S7
  headTurnSuccess,    // S8 (1s pause)
  allSuccess,         // S9 (1.5s pause)
}

class _AuthFlow extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onExit;
  final VoidCallback onPermissionFailed;

  const _AuthFlow({
    required this.onComplete,
    required this.onExit,
    required this.onPermissionFailed,
  });

  @override
  State<_AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<_AuthFlow>
    with TickerProviderStateMixin {
  static const _kPreviewSize = 280.0;
  static const _kGreen = Color(0xFF4CAF50);
  static const _kOrange = Color(0xFFFF6D00);

  final CameraService _cam = CameraService();
  final FaceDetectorService _det = FaceDetectorService();

  Timer? _detectTimer;
  Timer? _timeoutTimer;
  Timer? _pauseTimer;
  final Stopwatch _stateClock = Stopwatch();

  _SubState _sub = _SubState.cameraInit;
  double _progress = 0;

  // S4
  DateTime? _alignedSince;
  String _alignSubHint = '对准了我会自动开始';
  Color _alignSubColor = const Color(0xFF666666);
  bool _alignedNow = false;

  // S5
  bool _eyesClosed = false;
  int _blinkLevel = 0;

  // S7
  bool _yawLeft = false;
  bool _yawRight = false;
  int _turnLevel = 0;

  late final AnimationController _checkCtrl;
  late final AnimationController _bigCheckCtrl;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _bigCheckCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await Future.wait(<Future<void>>[_cam.start(), _det.init()])
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      _enterAlign();
    } on TimeoutException catch (_) {
      if (!mounted) return;
      _failToLogin('摄像头打不开，请稍后再试');
    } catch (e) {
      if (!mounted) return;
      final s = e.toString();
      if (s.contains('NotAllowed') || s.contains('Permission')) {
        widget.onPermissionFailed();
      } else {
        _failToLogin('摄像头打不开，请稍后再试');
      }
    }
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      _failToLogin('认证时间过长，请重新尝试');
    });
  }

  void _failToLogin(String msg) {
    LoginPageSnackbar.enqueue(msg);
    _teardown();
    if (mounted) context.go(AppRoutes.login);
  }

  void _onClose() {
    _teardown();
    widget.onExit();
  }

  void _teardown() {
    _detectTimer?.cancel();
    _timeoutTimer?.cancel();
    _pauseTimer?.cancel();
    _det.dispose();
    _cam.dispose();
  }

  // ─── S4 面部对位 ─────────────────────────────────────────────────────────
  void _enterAlign() {
    setState(() {
      _sub = _SubState.faceAlign;
      _alignedSince = null;
      _alignedNow = false;
    });
    _stateClock
      ..reset()
      ..start();
    _detectTimer?.cancel();
    _detectTimer = Timer.periodic(
        const Duration(milliseconds: 100), (_) => _alignTick());
    _resetTimeout();
  }

  void _alignTick() {
    final v = _cam.videoElement;
    if (v == null) return;
    final f = _det.detect(v);
    if (f == null || !f.hasFace) {
      _alignedSince = null;
      setState(() {
        _alignedNow = false;
        _alignSubHint = '找不到您的脸，请正对屏幕';
        _alignSubColor = const Color(0xFF666666);
      });
      return;
    }
    final dx = f.cx - 0.5;
    final dy = f.cy - 0.5;
    final w = f.w;
    final b = f.brightness;

    String sub;
    Color color = const Color(0xFF666666);
    bool aligned = false;

    if (b < 60) {
      sub = '光线太暗，请到亮一点的地方';
      color = _kOrange;
    } else if (w > 0.6) {
      sub = '请离远一点';
    } else if (w < 0.18) {
      sub = '请离近一点';
    } else if (dx.abs() > 0.15) {
      // 视频预览已 scaleX(-1) 镜像；图像 x 与用户视角左右相反
      sub = dx > 0 ? '请把脸往左移一点' : '请把脸往右移一点';
    } else if (dy.abs() > 0.15) {
      sub = dy > 0 ? '请把脸往上移一点' : '请把脸往下移一点';
    } else {
      sub = '很好，保持不动';
      color = _kGreen;
      aligned = true;
    }

    if (aligned) {
      _alignedSince ??= DateTime.now();
      if (DateTime.now()
              .difference(_alignedSince!)
              .inMilliseconds >=
          1000) {
        _detectTimer?.cancel();
        _enterBlink();
        return;
      }
    } else {
      _alignedSince = null;
    }

    setState(() {
      _alignedNow = aligned;
      _alignSubHint = sub;
      _alignSubColor = color;
    });
  }

  // ─── S5 眨眼 ─────────────────────────────────────────────────────────────
  void _enterBlink() {
    setState(() {
      _sub = _SubState.blinkDetecting;
      _blinkLevel = 0;
    });
    _stateClock
      ..reset()
      ..start();
    _eyesClosed = false;
    _detectTimer?.cancel();
    _detectTimer = Timer.periodic(
        const Duration(milliseconds: 100), (_) => _blinkTick());
    _resetTimeout();
  }

  void _blinkTick() {
    final secs = _stateClock.elapsed.inSeconds;
    final newLevel = secs < 5
        ? 0
        : secs < 10
            ? 1
            : 2;
    if (newLevel != _blinkLevel) {
      setState(() => _blinkLevel = newLevel);
    }
    final v = _cam.videoElement;
    if (v == null) return;
    final f = _det.detect(v);
    if (f == null || !f.hasFace) return;
    if (!_eyesClosed && f.ear < 0.20) {
      _eyesClosed = true;
    } else if (_eyesClosed && f.ear > 0.25) {
      _detectTimer?.cancel();
      _enterBlinkSuccess();
    }
  }

  void _enterBlinkSuccess() {
    setState(() {
      _sub = _SubState.blinkSuccess;
      _progress = 0.5;
    });
    _timeoutTimer?.cancel();
    _checkCtrl.forward(from: 0);
    _pauseTimer =
        Timer(const Duration(milliseconds: 1000), _enterHeadTurn);
  }

  // ─── S7 摇头 ─────────────────────────────────────────────────────────────
  void _enterHeadTurn() {
    if (!mounted) return;
    setState(() {
      _sub = _SubState.headTurnDetecting;
      _turnLevel = 0;
    });
    _stateClock
      ..reset()
      ..start();
    _yawLeft = false;
    _yawRight = false;
    _detectTimer?.cancel();
    _detectTimer = Timer.periodic(
        const Duration(milliseconds: 100), (_) => _turnTick());
    _resetTimeout();
  }

  void _turnTick() {
    final secs = _stateClock.elapsed.inSeconds;
    final newLevel = secs < 5
        ? 0
        : secs < 10
            ? 1
            : 2;
    if (newLevel != _turnLevel) {
      setState(() => _turnLevel = newLevel);
    }
    final v = _cam.videoElement;
    if (v == null) return;
    final f = _det.detect(v);
    if (f == null || !f.hasFace) return;
    if (f.yaw <= -15) _yawLeft = true;
    if (f.yaw >= 15) _yawRight = true;
    if (_yawLeft && _yawRight) {
      _detectTimer?.cancel();
      _enterHeadTurnSuccess();
    }
  }

  void _enterHeadTurnSuccess() {
    setState(() {
      _sub = _SubState.headTurnSuccess;
      _progress = 1.0;
    });
    _timeoutTimer?.cancel();
    _checkCtrl.forward(from: 0);
    _pauseTimer =
        Timer(const Duration(milliseconds: 1000), _enterAllSuccess);
  }

  // ─── S9 全部成功 ─────────────────────────────────────────────────────────
  void _enterAllSuccess() {
    if (!mounted) return;
    setState(() => _sub = _SubState.allSuccess);
    _bigCheckCtrl.forward(from: 0);
    _pauseTimer = Timer(const Duration(milliseconds: 1500), () {
      _teardown();
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _teardown();
    _checkCtrl.dispose();
    _bigCheckCtrl.dispose();
    super.dispose();
  }

  // ─── 文案 ────────────────────────────────────────────────────────────────
  String _blinkMain() {
    switch (_blinkLevel) {
      case 1:
        return '请眨一下眼睛，自然就行';
      case 2:
        return '请用力眨一下眼，像睡着一样';
      default:
        return '请眨一下眼睛';
    }
  }

  Color _blinkColor() =>
      _blinkLevel == 0 ? _kGreen : _kOrange;

  String _turnMain() {
    switch (_turnLevel) {
      case 1:
        return '请慢慢往左转头一下，再往右转一下';
      case 2:
        return '幅度可以小一点，左右转一下头就行';
      default:
        return '请左右转头';
    }
  }

  Color _turnColor() =>
      _turnLevel == 0 ? _kGreen : _kOrange;

  // ─── 构建 ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final showClose = _sub != _SubState.allSuccess;
    return Stack(
      children: [
        Positioned.fill(child: _buildBody()),
        if (showClose)
          Positioned(
            top: 4,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.close,
                  color: Color(0xFF333333), size: 28),
              onPressed: _onClose,
              iconSize: 28,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_sub) {
      case _SubState.cameraInit:
        return _buildCameraInit();
      case _SubState.faceAlign:
        return _buildFaceAlign();
      case _SubState.blinkDetecting:
        return _buildPreviewState(
          main: _blinkMain(),
          mainColor: _blinkColor(),
          sub: '自然地眨一下就行',
          progress: _progress,
          showCheck: false,
        );
      case _SubState.blinkSuccess:
        return _buildPreviewState(
          main: '识别成功',
          mainColor: _kGreen,
          mainSize: 28,
          sub: '准备进行下一步…',
          progress: 0.5,
          showCheck: true,
        );
      case _SubState.headTurnDetecting:
        return _buildPreviewState(
          main: _turnMain(),
          mainColor: _turnColor(),
          sub: '不用幅度太大',
          progress: _progress,
          showCheck: false,
        );
      case _SubState.headTurnSuccess:
        return _buildPreviewState(
          main: '识别成功',
          mainColor: _kGreen,
          mainSize: 28,
          sub: '正在为您验证身份…',
          progress: 1.0,
          showCheck: true,
        );
      case _SubState.allSuccess:
        return _buildAllSuccess();
    }
  }

  Widget _buildCameraInit() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: _kPreviewSize,
            height: _kPreviewSize,
            child: const Center(
              child: SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: _kOrange,
                  strokeWidth: 4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '正在打开摄像头…',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '请稍候',
            style: TextStyle(fontSize: 18, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceAlign() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _previewRing(
            color: _alignedNow ? _kGreen : _kOrange,
            solid: _alignedNow,
            progress: 0,
            showCheck: false,
          ),
          const SizedBox(height: 32),
          const Text(
            '请把脸放到圆圈里',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _alignSubHint,
            style: TextStyle(fontSize: 18, color: _alignSubColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewState({
    required String main,
    required Color mainColor,
    double mainSize = 24,
    required String sub,
    required double progress,
    required bool showCheck,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _previewRing(
            color: _kGreen,
            solid: true,
            progress: progress,
            showCheck: showCheck,
          ),
          const SizedBox(height: 32),
          Text(
            main,
            style: TextStyle(
              fontSize: mainSize,
              fontWeight: FontWeight.w700,
              color: mainColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            sub,
            style: const TextStyle(fontSize: 18, color: Color(0xFF999999)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _previewRing({
    required Color color,
    required bool solid,
    required double progress,
    required bool showCheck,
  }) {
    final vt = _cam.viewType;
    return SizedBox(
      width: _kPreviewSize,
      height: _kPreviewSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 摄像头预览（圆形裁剪）
          if (vt != null)
            ClipOval(
              child: SizedBox(
                width: _kPreviewSize - 16,
                height: _kPreviewSize - 16,
                child: CameraView(viewType: vt),
              ),
            ),
          // 外圈环
          SizedBox(
            width: _kPreviewSize,
            height: _kPreviewSize,
            child: CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              color: color,
              backgroundColor:
                  progress > 0 ? color.withValues(alpha: 0.18) : null,
              strokeWidth: 4,
            ),
          ),
          // 静态外圈（progress=0 时盖一层实/虚线圆）
          if (progress == 0)
            Container(
              width: _kPreviewSize,
              height: _kPreviewSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: solid ? 4 : 3,
                ),
              ),
            ),
          // 中央 ✓ 反馈
          if (showCheck)
            FadeTransition(
              opacity: _checkCtrl,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(
                      parent: _checkCtrl, curve: Curves.easeOutBack),
                ),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      size: 56, color: _kGreen),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 1.0).animate(
              CurvedAnimation(
                  parent: _bigCheckCtrl, curve: Curves.easeOutBack),
            ),
            child: FadeTransition(
              opacity: _bigCheckCtrl,
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  color: _kGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    size: 112, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '认证成功',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _kGreen,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '正在为您登录…',
            style: TextStyle(fontSize: 18, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}

// ─── E1 摄像头权限拒绝页 ───────────────────────────────────────────────────────

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onExit;
  const _PermissionDeniedView({required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 4,
          left: 4,
          child: IconButton(
            icon: const Icon(Icons.close,
                color: Color(0xFF333333), size: 28),
            onPressed: onExit,
            iconSize: 28,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF6D00).withValues(alpha: 0.12),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      size: 64, color: Color(0xFFFF6D00)),
                ),
                const SizedBox(height: 24),
                const Text(
                  '无法打开摄像头',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '您没有给浙里办使用摄像头的权限',
                  style: TextStyle(
                      fontSize: 18, color: Color(0xFF666666)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            '请到手机系统设置 → 浙里办 → 权限 → 允许使用摄像头',
                            style: TextStyle(
                                fontSize: 18, color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFFFF6D00),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      Future<void>.delayed(
                          const Duration(seconds: 2), onExit);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D00),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.xlarge),
                      ),
                    ),
                    child: const Text(
                      '去系统设置开启',
                      style: TextStyle(
                          fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onExit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6D00),
                      side: const BorderSide(color: Color(0xFFFF6D00)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.xlarge),
                      ),
                    ),
                    child: const Text(
                      '返回登录',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        const SizedBox(height: Spacing.sm),
        const Text(
          '我们不会保存您的人脸图像',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
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
