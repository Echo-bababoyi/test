import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../theme/design_tokens.dart';
import '../services/agent_element_registry.dart';
import '../services/agent_session.dart';
import '../services/agent_settings_service.dart';
import '../services/auth_state.dart';
import '../services/chat_history.dart';
import '../services/draft_service.dart';
import '../services/draft_store.dart';
import '../services/page_meta.dart';
import '../services/ws_client.dart';
import 'auth_card.dart';
import 'mic_button.dart';
import 'press_scale_wrapper.dart';

const _kDemoMode = bool.fromEnvironment('DEMO_MODE');

/// 本期 dock 仅挂长辈版，主色锁定长辈橙（不随 modeProvider，避免直接进 /elder 显蓝）。
const _kPrimary = AppColors.elderPrimary;

// 暖卡色板（dock 内私有，勿动全局主题）—— AGENT_DOCK_VISUAL §2
const _kPanelBg = Color(0xFFFFF8F2); // 暖米面板底（与白页面拉开层次）
const _kHeaderBg = Color(0xFFFFF1E6); // 浅橙头部栏底
const _kAgentBubble = Colors.white; // 小浙气泡白底
const _kUserBubble = _kPrimary; // 用户气泡橙底
const _kTextMain = Color(0xFF333333); // 正文深灰
const _kHairline = Color(0xFFF0E6DC); // 头部下极淡暖色分隔线（替代硬灰线）

// 层次化柔和阴影：近距紧致 + 远距环境光，向上投，营造真实"浮起"感（不靠彩色硬边）
const _kFloatShadows = [
  BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, -2)), // 10% 近距
  BoxShadow(color: Color(0x12000000), blurRadius: 28, offset: Offset(0, -10)), // 7% 远距环境光
];
const _kPanelRadius = 26.0; // 顶部圆角

/// 底部一体化 AgentDock 容器（替换右下角悬浮气泡 AgentFab）。
///
/// 挂在各页 `Scaffold.bottomNavigationBar` 槽位：上方导航栏行（首页/小浙/我的，
/// 或精简态仅居中控制），下方 4 态面板宿主（S0 收起 / S1 半屏 / S2 窄条 / S3 卡片）。
///
/// 保留讯飞 ASR/TTS 全链路 + ChatHistory + 授权卡/选择卡渲染，仅搬容器形态。
class AgentBottomShell extends StatefulWidget {
  /// 当前选中底部 Tab：0=首页、2=我的（1 为中间小浙按钮，永不高亮选中）。
  final int currentIndex;

  /// 当前路由路径，用于页面绑定与 page_changed 上报。
  final String? currentPath;

  /// 精简态：任务流页（login/verify/支付确认）砍掉「首页/我的」两 Tab。
  final bool slim;

  const AgentBottomShell({
    super.key,
    this.currentIndex = 0,
    this.currentPath,
    this.slim = false,
  });

  @override
  State<AgentBottomShell> createState() => _AgentBottomShellState();
}

class _AgentBottomShellState extends State<AgentBottomShell> {
  StreamSubscription<void>? _uiSub;

  @override
  void initState() {
    super.initState();
    _uiSub = AgentSession.instance.uiSignal.listen((_) {
      if (mounted) setState(() {});
    });
    // 页面绑定（从 AgentFab.initState 搬来）：注册执行器 + 上报 page_changed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final meta = metaForRoute(widget.currentPath ?? '');
      AgentSession.instance.bindPage(
        token: this,
        router: GoRouter.of(context),
        overlayContext: context,
        currentPath: widget.currentPath,
        pageId: meta?.pageId,
        pageTitle: meta?.pageTitle,
      );
    });
  }

  @override
  void dispose() {
    _uiSub?.cancel();
    AgentSession.instance.unbindPage(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // build 内幂等补绑（从 AgentFab.build 搬来，同 #53 修复）：跳页后若未绑定则补绑
    if ((ModalRoute.of(context)?.isCurrent ?? true) &&
        !identical(AgentSession.instance.boundToken, this)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
        if (identical(AgentSession.instance.boundToken, this)) return;
        final meta = metaForRoute(widget.currentPath ?? '');
        AgentSession.instance.bindPage(
          token: this,
          router: GoRouter.of(context),
          overlayContext: context,
          currentPath: widget.currentPath,
          pageId: meta?.pageId,
          pageTitle: meta?.pageTitle,
        );
      });
    }

    final session = AgentSession.instance;
    final mode = session.panelMode;
    final closing = session.closing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 导航栏行：仅 S0 收起态渲染（§9.2，根治 P2-C 死键 + P2-D 引导态多导航行）─
        // S1 收起入口=头部栏右侧⌄；S2=窄条⌃展开；S3=禁收起。closing 期也不显示。
        if (mode == AgentPanelMode.closed && !closing)
          _DockNavRow(
            mode: mode,
            currentIndex: widget.currentIndex,
            slim: widget.slim,
            // 导航行只属于 S0：中间小浙键唯一职责=打开对话
            onCenterTap: () => session.setPanelMode(AgentPanelMode.dialog),
          ),
        // ── 4 态面板宿主（导航栏下方）──────────────────────────
        // P2-5 收尾（S2→S0）：文字本身随高度同步渐隐缩小（Opacity×heightFactor），
        // 非瞬间消失、非弹出放大（§5.4 硬要求）。
        closing
            ? TweenAnimationBuilder<double>(
                key: const ValueKey('dock_closing'),
                tween: Tween(begin: 1.0, end: 0.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                builder: (_, f, child) => Opacity(
                  opacity: f,
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: f,
                      child: child,
                    ),
                  ),
                ),
                child: _buildPanel(AgentPanelMode.guide, context),
              )
            : AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: mode == AgentPanelMode.closed
                    ? const SizedBox(width: double.infinity, height: 0)
                    : _buildPanel(mode, context),
              ),
      ],
    );
  }

  Widget _buildPanel(AgentPanelMode mode, BuildContext context) {
    switch (mode) {
      case AgentPanelMode.closed:
        return const SizedBox(width: double.infinity, height: 0);
      case AgentPanelMode.dialog:
        // S1≈50% 截断 400；其余靠 body 压缩重排
        final h = (MediaQuery.of(context).size.height * 0.5).clamp(0.0, 400.0);
        return SizedBox(
          width: double.infinity,
          height: h,
          child: _DialogPanel(currentPath: widget.currentPath),
        );
      case AgentPanelMode.guide:
        // 窄条：高度随内容（最近一条引导消息完整不截断）
        return const _GuidePanel();
      case AgentPanelMode.card:
        // 卡片临时长高到刚好容纳
        return const _CardHost();
    }
  }
}

// ─── 导航栏行 ─────────────────────────────────────────────────────────────────

class _DockNavRow extends StatelessWidget {
  final AgentPanelMode mode;
  final int currentIndex;
  final bool slim;
  final VoidCallback onCenterTap;

  const _DockNavRow({
    required this.mode,
    required this.currentIndex,
    required this.slim,
    required this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    final route = GoRouterState.of(context).matchedLocation;
    final tabMyKey = AgentElementRegistry.register(route, 'tab_my');

    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 64,
        child: slim
            ? Center(child: _ZheCenterButton(mode: mode, onTap: onCenterTap))
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: currentIndex == 0 ? Icons.home : Icons.home_outlined,
                    label: '首页',
                    selected: currentIndex == 0,
                    onTap: () => context.go(AppRoutes.elderHome),
                  ),
                  _ZheCenterButton(mode: mode, onTap: onCenterTap),
                  KeyedSubtree(
                    key: tabMyKey,
                    child: _NavItem(
                      icon: currentIndex == 2 ? Icons.person : Icons.person_outline,
                      label: '我的',
                      selected: currentIndex == 2,
                      onTap: () => context.go(AppRoutes.my),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _kPrimary : const Color(0xFF999999);
    return PressScaleWrapper(
      pressedScale: 0.88,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      builder: (_) => SizedBox(
        width: 90,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}

// ─── 中间小浙圆形凸起按钮（§8 决策1）────────────────────────────────────────────

class _ZheCenterButton extends StatelessWidget {
  final AgentPanelMode mode;
  final VoidCallback onTap;

  const _ZheCenterButton({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isClosed = mode == AgentPanelMode.closed;
    final isCard = mode == AgentPanelMode.card;
    final semantic = isClosed ? '打开小浙助手' : '收起小浙对话';
    const diameter = 56.0;

    // P1-3：S3 卡片态收起键禁用，置灰提示
    return Opacity(
      opacity: isCard ? 0.4 : 1.0,
      child: Semantics(
      button: true,
      label: semantic,
      child: PressScaleWrapper(
        pressedScale: 0.9,
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        builder: (_) => SizedBox(
          width: 88,
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: isClosed
                    ? const CustomPaint(
                        size: Size(diameter, diameter),
                        painter: _ZhePainter(primary: _kPrimary),
                      )
                    : const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white, size: 32),
              ),
              const SizedBox(height: 2),
              Text(
                isClosed ? '小浙' : '收起',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.0,
                  color: _kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// 绘制渐变背景圆 + 光泽高光 + 白色"浙"字（搬自 agent_fab.dart 的 _ZhePainter）。
class _ZhePainter extends CustomPainter {
  final Color primary;
  const _ZhePainter({required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final fz = size.width * 0.43; // "浙"字随直径缩放（56→24，复用于 28/40dp 头像）

    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 1.1,
        colors: [
          Color.lerp(primary, Colors.white, 0.3)!,
          primary,
          Color.lerp(primary, Colors.black, 0.1)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(cx * 0.3, cy * 0.08, cx * 1.4, cy * 0.85));
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy * 0.38), width: r * 1.25, height: r * 0.72),
      glossPaint,
    );

    final shadowPainter = TextPainter(
      text: TextSpan(
        text: '浙',
        style: TextStyle(
          color: const Color(0x40882200),
          fontSize: fz,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    shadowPainter.paint(
      canvas,
      Offset(cx - shadowPainter.width / 2 + 0.8,
          cy - shadowPainter.height / 2 + 1.2),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '浙',
        style: TextStyle(
          color: Colors.white,
          fontSize: fz,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ZhePainter oldDelegate) =>
      oldDelegate.primary != primary;
}

// ─── 顶部抓手 grabber（暗示可操作面板，居中暖灰胶囊）────────────────────────────
class _Grabber extends StatelessWidget {
  const _Grabber();
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE8DDD3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

// ─── 小浙圆头像（橙圆 + 白"浙"字，复用 _ZhePainter；头部 40dp / 气泡·窄条 28dp）───
class _ZheAvatar extends StatelessWidget {
  final double size;
  const _ZheAvatar({required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
        child: CustomPaint(
          size: Size(size, size),
          painter: const _ZhePainter(primary: _kPrimary),
        ),
      );
}

// ─── 消息气泡（dock 私有，替代共享 AgentBubble；勿动 agent_bubble.dart）───────────
class _DockBubble extends StatelessWidget {
  final String text;
  final bool isAgent;
  const _DockBubble({required this.text, required this.isAgent});

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width * 0.72; // 最大宽 72%
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isAgent ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAgent) ...[const _ZheAvatar(size: 28), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxW),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: isAgent ? _kAgentBubble : _kUserBubble,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isAgent
                    ? const [
                        BoxShadow(
                          color: Color(0x0F000000), // 6% 更柔
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.45,
                  color: isAgent ? _kTextMain : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── S1 半屏对话面板（迁自 agent_fab.dart 的 _BubbleWindow 内核）─────────────────

class _DialogPanel extends StatefulWidget {
  final String? currentPath;
  const _DialogPanel({required this.currentPath});

  @override
  State<_DialogPanel> createState() => _DialogPanelState();
}

class _DialogPanelState extends State<_DialogPanel> {
  final _scrollCtrl = ScrollController();
  final _textCtrl = TextEditingController();
  StreamSubscription<void>? _uiSub;
  final List<Map<String, dynamic>> _items = ChatHistory.instance.items;

  @override
  void initState() {
    super.initState();
    _uiSub = AgentSession.instance.uiSignal.listen((_) {
      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    });
    if (_kDemoMode) {
      _initDemoData();
    } else {
      final isLoggedIn = AuthState.instance.isLoggedIn;
      final effectiveTrust = isLoggedIn
          ? AgentSettingsService.instance.trustLevel
          : 'guide';
      AgentSession.instance.ensureSession(trustLevel: effectiveTrust);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkPageDraft();
      });
    }
    _scrollToBottom();
  }

  void _initDemoData() {
    if (_items.isEmpty) {
      _items.addAll(_demoDialogFor(widget.currentPath ?? ''));
    }
  }

  List<Map<String, dynamic>> _demoDialogFor(String path) {
    if (path == '/login/face') {
      return [
        {'role': 'agent', 'text': '您好，我是小浙，我陪您完成刷脸登录。'},
        {'role': 'agent', 'text': '请把手机举到眼前，看着摄像头。'},
        {'role': 'agent', 'text': '马上会弹出一个用摄像头的提示，是正常的，请您点"同意"。'},
        {'role': 'user', 'text': '好的'},
        {'role': 'agent', 'text': '请缓慢左右摇头，再眨一眨眼,认证一会儿就好~'},
      ];
    }
    if (path == '/service/pension-query') {
      return [
        {'role': 'agent', 'text': '您好，我是小浙,有什么可以帮您?'},
        {'role': 'user', 'text': '帮我查一下这个月的养老金'},
        {'role': 'agent', 'text': '好的，帮您查 5 月份的养老金，对吗？'},
        {'role': 'user', 'text': '对的'},
        {'role': 'agent', 'text': '已经帮您选好月份了，我帮您点查询~'},
        {'role': 'agent', 'text': '查到啦！您 5 月的养老金 3280 元，已经到账了。'},
      ];
    }
    if (path == '/elder/drafts') {
      return [
        {'role': 'agent', 'text': '您好，我是小浙~'},
        {'role': 'agent', 'text': '我看到您还有 2 份没办完的草稿，要接着办吗?'},
        {'role': 'user', 'text': '先看看医保缴费那个'},
        {'role': 'agent', 'text': '好的,您点"继续"就能接着上次填到一半的地方,不用重新填~'},
      ];
    }
    if (path == '/service/yibao-jiaofei') {
      return [
        {'role': 'agent', 'text': '您好，我是小浙，有什么可以帮您?'},
        {'role': 'user', 'text': '帮我交今年的医保'},
        {'role': 'agent', 'text': '好的，帮您缴 2026 年度的医保，对吗?'},
        {'role': 'user', 'text': '对'},
        {'role': 'agent', 'text': '正在帮您填写,身份证号需要您单独同意一下。'},
      ];
    }
    if (path == '/service/yibao-query') {
      return [
        {'role': 'agent', 'text': '您好，我是小浙，有什么可以帮您?'},
        {'role': 'user', 'text': '查一下我的医保缴费记录'},
        {'role': 'agent', 'text': '好的，帮您查近一年的医保缴费记录~'},
      ];
    }
    return [
      {'role': 'agent', 'text': '您好，我是小浙，有什么可以帮您？'},
      {'role': 'user', 'text': '帮我查一下养老金'},
      {'role': 'agent', 'text': '帮您查养老金，对吗？'},
      {'role': 'user', 'text': '对的'},
      {'role': 'agent', 'text': '好的，正在为您查询本月养老金发放情况…'},
    ];
  }

  Future<void> _checkPageDraft() async {
    if (!mounted) return;
    final meta = metaForRoute(widget.currentPath ?? '');
    if (meta == null) return;
    final draft = await DraftService.checkDraft(meta.pageId);
    if (!mounted || draft == null) return;
    if (_items.any((e) => e['type'] == 'draft_prompt' && e['pageId'] == meta.pageId)) {
      return;
    }
    setState(() => _items.add({
          'type': 'draft_prompt',
          'draft': draft,
          'pageId': meta.pageId,
          'pageTitle': meta.pageTitle,
        }));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _items.add({'role': 'user', 'text': text}));
    AgentSession.instance.sendText(text);
    _textCtrl.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _uiSub?.cancel();
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 定稿质感「无边框·层次阴影」：去边框 + 暖米底 + 双层柔和阴影 _kFloatShadows
    //  + 顶部 grabber + 26dp 圆角 + 极淡暖分隔线；S1/S2/S3 三态统一。
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias, // 让 header 方角裁进顶圆角
      decoration: const ShapeDecoration(
        color: _kPanelBg,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(_kPanelRadius)),
        ),
        shadows: _kFloatShadows,
      ),
      child: Column(
        children: [
          const _Grabber(),
          // ① 头部栏（§4）
          Container(
            height: 60,
            decoration: const BoxDecoration(
              color: _kHeaderBg,
              border: Border(bottom: BorderSide(color: _kHairline)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Row(
              children: [
                const _ZheAvatar(size: 40),
                const SizedBox(width: 12),
                const Text('小浙助手',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kTextMain)),
                const Spacer(),
                Semantics(
                  button: true,
                  label: '收起小浙对话',
                  child: PressScaleWrapper(
                    pressedScale: 0.9,
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      final s = AgentSession.instance;
                      s.setPanelMode(s.isGuiding
                          ? AgentPanelMode.guide
                          : AgentPanelMode.closed);
                    },
                    builder: (_) => const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.keyboard_arrow_down,
                          size: 30, color: _kPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ② 连接提示条
          if (!WsClient.instance.isConnected)
            Container(
              width: double.infinity,
              color: Colors.red.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              child: const Text('小浙未连接，正在重试…',
                  style: TextStyle(fontSize: 13, color: Colors.red)),
            ),
          // ③ 对话区
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items.length,
              itemBuilder: (_, i) => _buildItem(i),
            ),
          ),
          // ④ 输入区（§6）
          Container(
            decoration: BoxDecoration(
              color: _kPanelBg,
              border: Border(
                top: BorderSide(color: _kPrimary.withValues(alpha: 0.12)),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    style: const TextStyle(fontSize: 18),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendText(),
                    decoration: InputDecoration(
                      hintText: '跟小浙说说…',
                      hintStyle:
                          TextStyle(fontSize: 18, color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(color: _kPrimary, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                MicButton(
                  size: 50,
                  onAudioReady: (pcm) {
                    setState(() => _items
                        .add({'type': 'asr_placeholder', 'text': '🎙️ 识别中…'}));
                    AgentSession.instance.sendAudio(pcm);
                  },
                  onError: (msg) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendText,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                        color: _kPrimary, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.send, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int i) {
    final item = _items[i];

    if (item['type'] == 'auth') {
      final permId = item['permission_id'] as String? ?? '';
      return AuthCard(
        description: item['description'] as String,
        onApprove: () {
          setState(() => _items.removeAt(i));
          AgentSession.instance.sendPermissionResponse(permId, true, '可以');
        },
        onReject: () {
          setState(() => _items.removeAt(i));
          AgentSession.instance.sendPermissionResponse(permId, false, '不行');
        },
      );
    }

    if (item['type'] == 'choice') {
      final text = item['text'] as String? ?? '';
      final opts = (item['options'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DockBubble(text: text, isAgent: true),
          if (opts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  for (int k = 0; k < opts.length; k++) ...[
                    Expanded(
                      child: _ChoiceBtn(
                        label: opts[k]['label'] as String,
                        onTap: () {
                          final value = opts[k]['value'] as String;
                          setState(() {
                            item.remove('options');
                            _items.add({'role': 'user', 'text': value});
                          });
                          AgentSession.instance.sendChoiceText(value);
                          _scrollToBottom();
                        },
                      ),
                    ),
                    if (k < opts.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
        ],
      );
    }

    if (item['type'] == 'thinking') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('小浙正在想…',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
          ),
        ]),
      );
    }

    if (item['type'] == 'draft_prompt') {
      final pageTitle = item['pageTitle'] as String;
      final draft = item['draft'] as Map<String, dynamic>;
      return _DraftCard(
        pageTitle: pageTitle,
        onContinue: () {
          setState(() => _items.removeAt(i));
          final route = metaForPageId(item['pageId'] as String)?.route;
          if (route != null) {
            AgentSession.instance.setPanelMode(AgentPanelMode.closed);
            GoRouter.of(context).go('$route?restore=1');
          }
        },
        onDismiss: () {
          setState(() => _items.removeAt(i));
          DraftStore.deleteDraft(draft['draft_id'] as String);
        },
      );
    }

    final showConfirm = item['showConfirm'] as bool? ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DockBubble(text: item['text'] as String, isAgent: item['role'] == 'agent'),
        if (showConfirm)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
            child: Row(children: [
              _ConfirmBtn(label: '对的', isPrimary: true, onTap: () {
                setState(() { item.remove('showConfirm'); _items.add({'role': 'user', 'text': '对的'}); });
                AgentSession.instance.sendUserConfirm('yes', '对的');
                _scrollToBottom();
              }),
              const SizedBox(width: 8),
              _ConfirmBtn(label: '不是', isPrimary: false, onTap: () {
                setState(() { item.remove('showConfirm'); _items.add({'role': 'user', 'text': '不是'}); });
                AgentSession.instance.sendUserConfirm('no', '不是');
                _scrollToBottom();
              }),
            ]),
          ),
      ],
    );
  }
}

// ─── S2 引导态窄条（最近一条引导消息 + 展开控制）────────────────────────────────

class _GuidePanel extends StatefulWidget {
  const _GuidePanel();

  @override
  State<_GuidePanel> createState() => _GuidePanelState();
}

class _GuidePanelState extends State<_GuidePanel> {
  StreamSubscription<void>? _uiSub;

  @override
  void initState() {
    super.initState();
    _uiSub = AgentSession.instance.uiSignal.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiSub?.cancel();
    super.dispose();
  }

  String _latestAgentText() {
    final items = ChatHistory.instance.items;
    for (int i = items.length - 1; i >= 0; i--) {
      final e = items[i];
      if (e['role'] == 'agent' && (e['text'] as String?)?.isNotEmpty == true) {
        return e['text'] as String;
      }
    }
    return '小浙正在陪您操作…';
  }

  @override
  Widget build(BuildContext context) {
    // 变体① 定稿：无边框 + 暖米底 + 双层柔和阴影 + 顶部 grabber，与 S1/S3 统一
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const ShapeDecoration(
        color: _kPanelBg,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(_kPanelRadius)),
        ),
        shadows: _kFloatShadows,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Grabber(),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _ZheAvatar(size: 28),
          const SizedBox(width: 8),
          // 完整显示最近一条引导消息（不截断，≥18sp）
          Expanded(
            child: Text(
              _latestAgentText(),
              style: const TextStyle(fontSize: 18, height: 1.3, color: _kTextMain),
            ),
          ),
          // 展开控制（⌃）→ 回 S1 看历史 / 临时插话
          Semantics(
            button: true,
            label: '展开小浙对话',
            child: PressScaleWrapper(
              pressedScale: 0.9,
              onTap: () =>
                  AgentSession.instance.setPanelMode(AgentPanelMode.dialog),
              borderRadius: BorderRadius.circular(24),
              builder: (_) => Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const Icon(Icons.keyboard_arrow_up, color: _kPrimary, size: 30),
              ),
            ),
          ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── S3 卡片临时长高（授权卡 / 选择卡）──────────────────────────────────────────

class _CardHost extends StatefulWidget {
  const _CardHost();

  @override
  State<_CardHost> createState() => _CardHostState();
}

class _CardHostState extends State<_CardHost> {
  StreamSubscription<void>? _uiSub;

  @override
  void initState() {
    super.initState();
    _uiSub = AgentSession.instance.uiSignal.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiSub?.cancel();
    super.dispose();
  }

  Map<String, dynamic>? _trailingCard() {
    final items = ChatHistory.instance.items;
    for (int i = items.length - 1; i >= 0; i--) {
      final t = items[i]['type'];
      if (t == 'auth' || t == 'choice') return items[i];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final item = _trailingCard();
    // 变体① 定稿：无边框 + 暖米底 + 双层柔和阴影 + 顶部 grabber，与 S1/S2 统一
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const ShapeDecoration(
        color: _kPanelBg,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(_kPanelRadius)),
        ),
        shadows: _kFloatShadows,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Grabber(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 12), // 卡片"浮"出呼吸感
            child: item == null ? const SizedBox(height: 0) : _buildCard(item),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final items = ChatHistory.instance.items;

    if (item['type'] == 'auth') {
      final permId = item['permission_id'] as String? ?? '';
      return AuthCard(
        description: item['description'] as String? ?? '需要您的授权',
        onApprove: () {
          items.remove(item);
          AgentSession.instance.sendPermissionResponse(permId, true, '可以');
        },
        onReject: () {
          items.remove(item);
          AgentSession.instance.sendPermissionResponse(permId, false, '不行');
        },
      );
    }

    // choice
    final text = item['text'] as String? ?? '';
    final opts = (item['options'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DockBubble(text: text, isAgent: true),
        if (opts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                for (int k = 0; k < opts.length; k++) ...[
                  Expanded(
                    child: _ChoiceBtn(
                      label: opts[k]['label'] as String,
                      onTap: () {
                        final value = opts[k]['value'] as String;
                        item.remove('options');
                        items.add({'role': 'user', 'text': value});
                        AgentSession.instance.sendChoiceText(value);
                      },
                    ),
                  ),
                  if (k < opts.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ─── 确认 / 选择 / 草稿卡按钮（搬自 agent_fab.dart）──────────────────────────────

class _ConfirmBtn extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  const _ConfirmBtn({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // ≥48dp
        decoration: BoxDecoration(
          color: isPrimary ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isPrimary ? _kPrimary : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isPrimary ? Colors.white : Colors.grey.shade700,
            )),
      ),
    );
  }
}

class _ChoiceBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ChoiceBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  final String pageTitle;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;
  const _DraftCard({
    required this.pageTitle,
    required this.onContinue,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final tint = Color.lerp(_kPrimary, Colors.white, 0.88)!;
    final border = Color.lerp(_kPrimary, Colors.white, 0.55)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.edit_note, color: _kPrimary, size: 18),
            const SizedBox(width: 4),
            const Text('草稿提醒',
                style: TextStyle(fontSize: 14, color: _kPrimary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Text('上次有个未完成的$pageTitle，要继续吗？',
              style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text('不用了', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ),
            )),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(
              onTap: onContinue,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text('继续', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            )),
          ]),
        ]),
      ),
    );
  }
}
