import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
import 'suggestion_list.dart';

class SearchResultPage extends ConsumerStatefulWidget {
  const SearchResultPage({super.key});

  @override
  ConsumerState<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends ConsumerState<SearchResultPage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late String _query;
  bool _isEditing = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 只在第一次挂载时从 URL 读 query
    if (!_initialized) {
      _initialized = true;
      final q = GoRouterState.of(context).uri.queryParameters['q'] ?? '';
      _query = q;
      _controller.text = q;
      _controller.addListener(_onTextChanged);
    }
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onClearTap() {
    _controller.clear();
    setState(() => _isEditing = true);
    _focusNode.requestFocus();
  }

  void _onFieldTap() {
    if (!_isEditing) setState(() => _isEditing = true);
  }

  void _onSubmit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _controller.text = trimmed;
    setState(() {
      _query = trimmed;
      _isEditing = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部搜索栏（可编辑）
            _ResultTopBar(
              controller: _controller,
              focusNode: _focusNode,
              hasText: text.isNotEmpty,
              onClearTap: _onClearTap,
              onFieldTap: _onFieldTap,
              onSubmit: _onSubmit,
              onCancel: () => context.pop(),
            ),
            const Divider(height: 1),
            // body 分支
            if (_isEditing)
              Expanded(
                child: SearchSuggestionList(
                  query: text,
                  onSelect: _onSubmit,
                ),
              )
            else ...[
              _ResultTabRow(),
              const Divider(height: 1),
              Expanded(child: _ResultBody(query: _query)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── 顶部搜索栏（可编辑 TextField）────────────────────────────────────────────

class _ResultTopBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final VoidCallback onClearTap;
  final VoidCallback onFieldTap;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  const _ResultTopBar({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.onClearTap,
    required this.onFieldTap,
    required this.onSubmit,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '西湖区',
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
              Icon(Icons.arrow_drop_down,
                  size: 18, color: AppColors.textPrimary),
            ],
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: onFieldTap,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmit,
                  onTap: onFieldTap,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    suffixIcon: hasText
                        ? GestureDetector(
                            onTap: onClearTap,
                            child: const Icon(
                              Icons.cancel,
                              size: 18,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
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
                  fontSize: 15, color: AppColors.standardPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 综合 / 服务 / 办事 / 政策 tab 行（静态）────────────────────────────────

class _ResultTabRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Row(
        children: const [
          _TabLabel('综合', selected: true),
          SizedBox(width: Spacing.xl),
          _TabLabel('服务'),
          SizedBox(width: Spacing.xl),
          _TabLabel('办事'),
          SizedBox(width: Spacing.xl),
          _TabLabel('政策'),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String text;
  final bool selected;
  const _TabLabel(this.text, {this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected
                  ? AppColors.standardPrimary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 24,
            color: selected
                ? AppColors.standardPrimary
                : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

// ─── 结果内容（按 query 分支）────────────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  final String query;
  const _ResultBody({required this.query});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader('服务'),
          if (query == '医保缴费') ..._medicalPayServices(context),
          if (query == '养老金查询') ..._pensionServices(context),
          if (query != '医保缴费' && query != '养老金查询')
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.md,
              ),
              child: Text(
                query.isEmpty ? '' : '暂无相关服务',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: Spacing.md),
              child: Text(
                '查看更多搜索结果',
                style: TextStyle(
                    fontSize: 14, color: AppColors.standardPrimary),
              ),
            ),
          ),
          const Divider(height: 1),
          const _SectionHeader('办事'),
          if (query == '医保缴费') ..._medicalPayAffairs(),
          if (query == '养老金查询') ..._pensionAffairs(),
        ],
      ),
    );
  }

  List<Widget> _medicalPayServices(BuildContext context) => [
        _ServiceItem(
          iconColor: const Color(0xFF2D74DC),
          icon: Icons.health_and_safety_outlined,
          title: '浙里医保',
          chips: const ['医保地图', '医保个人账户', '医保'],
          department: '省医保局',
          onTap: null,
        ),
        const Divider(height: 1, indent: Spacing.lg),
        _ServiceItem(
          iconColor: const Color(0xFFFF6D00),
          icon: Icons.manage_search,
          title: '社保费缴纳',
          chips: const ['社保医保缴费', '城乡居民基本医'],
          department: '省税务局',
          onTap: () => context.push(AppRoutes.socialInsurance),
        ),
        const Divider(height: 1, indent: Spacing.lg),
        _ServiceItem(
          iconColor: const Color(0xFF2D74DC),
          icon: Icons.search,
          title: '社保查询',
          chips: const [],
          department: '省人力社保厅',
          onTap: null,
        ),
        const Divider(height: 1, indent: Spacing.lg),
      ];

  List<Widget> _pensionServices(BuildContext context) => [
        _ServiceItem(
          iconColor: const Color(0xFF2D74DC),
          icon: Icons.manage_search,
          title: '社保查询',
          chips: const ['养老险查询', '养老金', '失业险查'],
          department: '省人力社保厅',
          onTap: () => context.push(AppRoutes.pensionQuery),
        ),
        const Divider(height: 1, indent: Spacing.lg),
        _ServiceItem(
          iconColor: const Color(0xFF2D74DC),
          icon: Icons.calculate_outlined,
          title: '退休待遇测算',
          chips: const ['养老金测算', '企业养老保险待遇'],
          department: '省人力社保厅',
          onTap: null,
        ),
        const Divider(height: 1, indent: Spacing.lg),
        _ServiceItem(
          iconColor: const Color(0xFFFF6D00),
          icon: Icons.print_outlined,
          title: '社保证明打印',
          chips: const ['历年养老证明', '养老险缴费凭证'],
          department: '省人力社保厅',
          onTap: null,
        ),
        const Divider(height: 1, indent: Spacing.lg),
      ];

  List<Widget> _medicalPayAffairs() => [
        const _AffairItem('职工参保登记（医保）'),
        const Divider(height: 1, indent: Spacing.lg),
        const _AffairItem('职工医保补缴'),
        const Divider(height: 1, indent: Spacing.lg),
      ];

  List<Widget> _pensionAffairs() => [
        const _AffairItem('退休高级职称人员增加养老金待遇'),
        const Divider(height: 1, indent: Spacing.lg),
      ];
}

// ─── 子组件 ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.sm,
      ),
      child: Text(
        title,
        style:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final Color iconColor;
  final IconData icon;
  final String title;
  final List<String> chips;
  final String department;
  final VoidCallback? onTap;

  const _ServiceItem({
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.chips,
    required this.department,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: chips
                          .map(
                            (c) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(c,
                                  style:
                                      const TextStyle(fontSize: 12)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    department,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AffairItem extends StatelessWidget {
  final String title;
  const _AffairItem(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg, vertical: Spacing.md),
      child: Text(title, style: const TextStyle(fontSize: 15)),
    );
  }
}
