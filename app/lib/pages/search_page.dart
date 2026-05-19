import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../services/wake_word_listener.dart';
import '../theme/design_tokens.dart';
import '../widgets/agent_fab.dart';
import '../widgets/in_app_overlay.dart';
import '../widgets/permission_flow_helper.dart';
import '../widgets/login_guard.dart';
import '../widgets/search_suggestion_list.dart';
import '../widgets/elder_bottom_nav.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  String _text = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() => _text = _controller.text);

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _submitSearch(String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    context.push('${AppRoutes.searchResult}?q=${Uri.encodeComponent(trimmed)}');
  }

  void _showMicPermissionOverlay() {
    PermissionFlowHelper.request(
      context: context,
      guideContentBuilder: (onProceed) => _MicPermissionContent(
        onNotNow: () => Navigator.of(context).pop(),
        onEnable: onProceed,
      ),
      systemTitle: '"浙里办"请求使用麦克风',
      systemMessage: '用于通过麦克风实现语音搜索等功能',
      systemConfirmLabel: '使用应用时允许',
      systemDenyLabel: '禁止',
      onGranted: _showVoiceInputOverlay,
    );
  }

  void _showVoiceInputOverlay() {
    WakeWordListener.instance.pause();
    InAppOverlay.show<void>(
      context,
      child: _VoiceInputContent(
        onResult: (result) async {
          if (!mounted) return;
          Navigator.of(context).pop();
          WakeWordListener.instance.resume();
          _controller.text = result;
          _submitSearch(result);
        },
        onClose: () {
          Navigator.of(context).pop();
          WakeWordListener.instance.resume();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _controller,
              text: _text,
              onMicTap: _showMicPermissionOverlay,
              onSubmit: _submitSearch,
              onClear: () {
                _controller.clear();
                setState(() => _text = '');
              },
              onCancel: () => context.pop(),
            ),
            const Divider(height: 1),
            Expanded(
              child: _text.isEmpty
                  ? _DefaultBody(onSearch: _submitSearch)
                  : SearchSuggestionList(query: _text, onSelect: _submitSearch),
            ),
          ],
        ),
      ),
          const Positioned.fill(
            child: AgentFab(currentPath: AppRoutes.search),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }
}

// ─── 顶部搜索栏 ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String text;
  final VoidCallback onMicTap;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;
  final VoidCallback onCancel;

  const _SearchBar({
    required this.controller,
    required this.text,
    required this.onMicTap,
    required this.onSubmit,
    required this.onClear,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: onSubmit,
                style: const TextStyle(fontSize: AppFontSize.elderBody),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  suffixIcon: text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel, size: 18, color: Colors.grey),
                          onPressed: onClear,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        )
                      : IconButton(
                          icon: const Icon(Icons.mic, size: 18, color: Colors.grey),
                          onPressed: onMicTap,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              minimumSize: const Size(48, 44),
            ),
            child: const Text(
              '取消',
              style: TextStyle(fontSize: AppFontSize.elderBody, color: AppColors.elderPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 空输入时默认内容 ─────────────────────────────────────────────────────────

class _DefaultBody extends StatelessWidget {
  final ValueChanged<String> onSearch;
  const _DefaultBody({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '我的常用',
            style: TextStyle(fontSize: AppFontSize.subtitle, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickItem(
                  icon: Icons.manage_search,
                  iconColor: AppColors.elderPrimary,
                  label: '社保查询',
                  onTap: () => LoginGuard.tryNavigate(context, AppRoutes.shebaoQuery),
                ),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: _QuickItem(
                  icon: Icons.health_and_safety_outlined,
                  iconColor: AppColors.elderPrimary,
                  label: '医保查询',
                  onTap: () => LoginGuard.tryNavigate(context, AppRoutes.shebaoJiaona),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          const Text(
            '为你推荐',
            style: TextStyle(fontSize: AppFontSize.subtitle, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.md,
            children: [
              _RecommendPill('办居住证', onTap: () => onSearch('办居住证')),
              _RecommendPill('浙里医保', onTap: () => onSearch('浙里医保')),
              _RecommendPill('健康杭州', onTap: () => onSearch('健康杭州')),
              _RecommendPill('流动人口居住登记', onTap: () => onSearch('流动人口居住登记')),
              _RecommendPill('小客车摇号', onTap: () => onSearch('小客车摇号')),
              _RecommendPill('不动产智治', onTap: () => onSearch('不动产智治')),
              _RecommendPill('市场监管业务办理', onTap: () => onSearch('市场监管业务办理')),
              _RecommendPill('e房通', onTap: () => onSearch('e房通')),
              _RecommendPill('校园建身', onTap: () => onSearch('校园建身')),
              _RecommendPill('公积金', onTap: () => onSearch('公积金')),
              _RecommendPill('入学早知道', onTap: () => onSearch('入学早知道')),
              _RecommendPill('医保查询', onTap: () => onSearch('医保查询')),
            ],
          ),
          const SizedBox(height: Spacing.lg),
        ],
      ),
    );
  }
}

class _QuickItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  const _QuickItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xs),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              label,
              style: const TextStyle(fontSize: AppFontSize.elderBody, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _RecommendPill(this.label, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
          child: Text(label, style: const TextStyle(fontSize: AppFontSize.bodyLarge)),
        ),
      ),
    );
  }
}

// ─── 麦克风权限引导浮层内容 ────────────────────────────────────────────────────

class _MicPermissionContent extends StatelessWidget {
  final VoidCallback onNotNow;
  final VoidCallback onEnable;

  const _MicPermissionContent({required this.onNotNow, required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '浙里办需要获取麦克风权限',
          style: TextStyle(fontSize: AppFontSize.title, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.md),
        const Text(
          '开启麦克风权限，浙里办可以为您提供通过麦克风实现语音搜索等功能',
          style: TextStyle(fontSize: AppFontSize.body, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.xl),
        Row(
          children: [
            TextButton(
              onPressed: onNotNow,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
              ),
              child: const Text('暂不开启'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: onEnable,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.elderPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.xl,
                  vertical: Spacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xlarge),
                ),
              ),
              child: const Text('去开启'),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── 语音输入浮层内容 ─────────────────────────────────────────────────────────

class _VoiceInputContent extends StatefulWidget {
  final Future<void> Function(String) onResult;
  final VoidCallback onClose;

  const _VoiceInputContent({required this.onResult, required this.onClose});

  @override
  State<_VoiceInputContent> createState() => _VoiceInputContentState();
}

class _VoiceInputContentState extends State<_VoiceInputContent> {
  bool _listening = false;

  Future<void> _onMicTap() async {
    setState(() => _listening = true);
    final result = await Future.delayed(
      const Duration(seconds: 2),
      () => '医保缴费',
    );
    if (!mounted) return;
    widget.onResult(result);
  }

  @override
  Widget build(BuildContext context) {
    const micColor = Color(0xFFFF6D00);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: widget.onClose,
          ),
        ),
        Text(
          _listening ? '正在听...' : '您可以这样说：',
          style: const TextStyle(
            fontSize: AppFontSize.subtitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Spacing.md),
        if (!_listening)
          const Text(
            '公积金查询、社保查询、预防接种',
            style: TextStyle(
              fontSize: AppFontSize.bodyLarge,
              color: AppColors.textPrimary,
            ),
          ),
        const SizedBox(height: Spacing.xl),
        const Text(
          '按住话筒说话',
          style: TextStyle(fontSize: AppFontSize.body, color: micColor),
        ),
        const SizedBox(height: Spacing.md),
        Material(
          color: _listening ? micColor.withValues(alpha: 0.6) : micColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _listening ? null : _onMicTap,
            customBorder: const CircleBorder(),
            splashColor: Colors.white24,
            highlightColor: Colors.white12,
            child: const SizedBox(
              width: 64,
              height: 64,
              child: Icon(Icons.mic, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: Spacing.xl),
      ],
    );
  }
}
