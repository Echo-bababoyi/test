import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/in_app_overlay.dart';
import '../../core/widgets/system_dialog.dart';
import '../../services/voice_input_service.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
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

  // I3：应用内浮层 — 麦克风权限引导（非阻塞）
  void _showMicPermissionOverlay() {
    InAppOverlay.show<void>(
      context,
      child: _MicPermissionContent(
        onNotNow: () => Navigator.of(context).pop(),
        onEnable: () {
          Navigator.of(context).pop();
          _showMicSystemDialog();
        },
      ),
    );
  }

  // S3：系统弹窗 — 麦克风权限（阻塞式）
  void _showMicSystemDialog() {
    SystemDialog.show(
      context,
      title: '"浙里办"请求使用麦克风',
      message: '用于通过麦克风实现语音搜索等功能',
      confirmLabel: '使用应用时允许',
      denyLabel: '禁止',
      onConfirm: _showVoiceInputOverlay,
    );
  }

  // I4：应用内浮层 — 语音输入（非阻塞）
  void _showVoiceInputOverlay() {
    InAppOverlay.show<void>(
      context,
      child: _VoiceInputContent(
        onMicTap: () async {
          Navigator.of(context).pop();
          final result = await ref.read(voiceInputServiceProvider).listen();
          if (!mounted) return;
          _controller.text = result;
          _submitSearch(result);
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                  ? const _DefaultBody()
                  : _SuggestionList(query: _text, onSelect: _submitSearch),
            ),
          ],
        ),
      ),
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
          // 西湖区 ▼
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '西湖区',
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
              Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textPrimary),
            ],
          ),
          const SizedBox(width: Spacing.sm),
          // 搜索框
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
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  suffixIcon: text.isNotEmpty
                      ? GestureDetector(
                          onTap: onClear,
                          child: const Icon(
                            Icons.cancel,
                            size: 18,
                            color: Colors.grey,
                          ),
                        )
                      : GestureDetector(
                          onTap: onMicTap,
                          child: const Icon(
                            Icons.mic,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          // 取消
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '取消',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.standardPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 空输入时默认内容 ─────────────────────────────────────────────────────────

class _DefaultBody extends StatelessWidget {
  const _DefaultBody();

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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: const [
              Expanded(
                child: _QuickItem(
                  icon: Icons.health_and_safety_outlined,
                  iconColor: Color(0xFF2D74DC),
                  label: '浙里医保',
                ),
              ),
              SizedBox(width: Spacing.lg),
              Expanded(
                child: _QuickItem(
                  icon: Icons.manage_search,
                  iconColor: Color(0xFF2D74DC),
                  label: '社保查询',
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: const [
              Expanded(
                child: _QuickItem(
                  icon: Icons.home_work_outlined,
                  iconColor: Color(0xFF2D74DC),
                  label: '住房公积金',
                ),
              ),
              SizedBox(width: Spacing.lg),
              Expanded(
                child: _QuickItem(
                  icon: Icons.print_outlined,
                  iconColor: Color(0xFFFF6D00),
                  label: '社保证明...',
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最近搜索',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('清空', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: const [
              _RecentPill('医保'),
              SizedBox(width: Spacing.md),
              _RecentPill('养老金'),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          const Text(
            '为你推荐',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.md,
            children: const [
              _RecommendPill('办居住证'),
              _RecommendPill('浙里医保'),
              _RecommendPill('健康杭州'),
              _RecommendPill('流动人口居住登记'),
              _RecommendPill('小客车摇号'),
              _RecommendPill('不动产智治'),
              _RecommendPill('市场监管业务办理'),
              _RecommendPill('e房通'),
              _RecommendPill('校园建身'),
              _RecommendPill('公积金'),
              _RecommendPill('入学早知道'),
              _RecommendPill('医保查询'),
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

  const _QuickItem({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _RecentPill extends StatelessWidget {
  final String label;
  const _RecentPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}

class _RecommendPill extends StatelessWidget {
  final String label;
  const _RecommendPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

// ─── 有输入时联想词列表 ────────────────────────────────────────────────────────

class _SuggestionList extends StatelessWidget {
  final String query;
  final ValueChanged<String> onSelect;

  const _SuggestionList({required this.query, required this.onSelect});

  List<String> _suggestions() {
    if (query == '医保缴费') {
      return [
        '医保缴费',
        '少儿医保缴费',
        '医保缴费记录',
        '农村医保缴费',
        '医保缴费查询',
        '浙里医保缴费',
        '个人医保缴费',
        '儿童医保缴费',
        '子女医保缴费',
        '农医保缴费',
        '浙江医保缴费',
      ];
    }
    if (query == '养老金查询') return ['养老金查询'];
    return [query];
  }

  @override
  Widget build(BuildContext context) {
    final items = _suggestions();
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: Spacing.lg),
      itemBuilder: (context, i) => ListTile(
        title: Text(items[i], style: const TextStyle(fontSize: 16)),
        onTap: () => onSelect(items[i]),
      ),
    );
  }
}

// ─── I3：麦克风权限引导浮层内容（InAppOverlay，非阻塞）─────────────────────

class _MicPermissionContent extends StatelessWidget {
  final VoidCallback onNotNow;
  final VoidCallback onEnable;

  const _MicPermissionContent({
    required this.onNotNow,
    required this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '浙里办需要获取麦克风权限',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.md),
        const Text(
          '开启麦克风权限，浙里办可以为您提供通过麦克风实现语音搜索等功能',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.xl),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onNotNow,
                child: const Text('暂不开启'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: FilledButton(
                onPressed: onEnable,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.standardPrimary,
                ),
                child: const Text('去开启'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── I4：语音输入浮层内容（InAppOverlay，非阻塞）───────────────────────────

class _VoiceInputContent extends StatelessWidget {
  final VoidCallback onMicTap;
  final VoidCallback onClose;

  const _VoiceInputContent({
    required this.onMicTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: onClose,
          ),
        ),
        const Text(
          '您可以这样说：',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Spacing.md),
        const Text(
          '公积金查询、社保查询、预防接种',
          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),
        const SizedBox(height: Spacing.xl),
        const Text(
          '按住话筒说话',
          style: TextStyle(fontSize: 14, color: AppColors.elderPrimary),
        ),
        const SizedBox(height: Spacing.md),
        GestureDetector(
          onTap: onMicTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.elderPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: Spacing.xl),
      ],
    );
  }
}
