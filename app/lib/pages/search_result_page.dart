import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../theme/design_tokens.dart';
import '../widgets/agent_fab.dart';
import '../widgets/search_suggestion_list.dart';
import '../widgets/elder_bottom_nav.dart';

class SearchResultPage extends StatefulWidget {
  const SearchResultPage({super.key});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
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
    if (!_initialized) {
      _initialized = true;
      final q = GoRouterState.of(context).uri.queryParameters['q'] ?? '';
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
    context.replace('${AppRoutes.searchResult}?q=${Uri.encodeComponent(trimmed)}');
    setState(() => _isEditing = false);
    _focusNode.unfocus();
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.elderPrimary,
      elevation: 0,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      title: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: _onSubmit,
          onTap: _onFieldTap,
          style: const TextStyle(
              fontSize: AppFontSize.elderBody, color: AppColors.textPrimary),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            prefixIcon: const Icon(Icons.search,
                color: AppColors.textSecondary, size: 22),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel,
                        size: 22, color: AppColors.textSecondary),
                    onPressed: _onClearTap,
                  )
                : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: const Text('取消',
              style: TextStyle(
                  fontSize: AppFontSize.elderBody, color: Colors.white)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = GoRouterState.of(context).uri.queryParameters['q'] ?? '';
    final text = _controller.text;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              children: [
                if (_isEditing)
                  Expanded(
                    child:
                        SearchSuggestionList(query: text, onSelect: _onSubmit),
                  )
                else
                  Expanded(child: _ResultBody(query: q)),
              ],
            ),
          ),
          const Positioned.fill(
            child: AgentFab(currentPath: AppRoutes.searchResult),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }
}

// ─── 结果内容 ─────────────────────────────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  final String query;
  const _ResultBody({required this.query});

  bool get _isMedicalQuery {
    const aliases = [
      '医保查询', '医保余额', '医保账户', '医保余额查询',
    ];
    return aliases.contains(query);
  }

  bool get _isMedicalPay {
    const aliases = [
      '医保缴费', '少儿医保缴费', '医保缴费记录', '农村医保缴费',
      '城乡居民医保缴费', '社保费缴纳',
      '医保', '浙里医保', '健康医保', '居民医保', '城乡居民医保',
      '缴医保', '交医保',
    ];
    return aliases.contains(query);
  }

  bool get _isPensionQuery {
    const aliases = [
      '养老金',
      '养老金查询',
      '本月养老金',
      '养老金账单',
      '退休待遇测算',
      '养老金测算',
    ];
    return aliases.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.only(top: Spacing.md),
            padding: const EdgeInsets.all(Spacing.lg),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('服务',
                    style: TextStyle(
                      fontSize: AppFontSize.elderTitle,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: Spacing.md),
                if (_isMedicalQuery) ..._medicalQueryServices(context),
                if (!_isMedicalQuery && _isMedicalPay) ..._medicalPayServices(context),
                if (_isPensionQuery) ..._pensionServices(context),
                if (!_isMedicalQuery && !_isMedicalPay && !_isPensionQuery)
                  const _EmptyHint(),
              ],
            ),
          ),
          if (_isMedicalPay || _isPensionQuery || _isMedicalQuery)
            Container(
              margin: const EdgeInsets.only(top: Spacing.md),
              padding: const EdgeInsets.all(Spacing.lg),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('办事',
                      style: TextStyle(
                        fontSize: AppFontSize.elderTitle,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: Spacing.md),
                  if (_isMedicalPay) ..._medicalPayAffairs(),
                  if (_isPensionQuery) ..._pensionAffairs(),
                  if (_isMedicalQuery) ..._medicalQueryAffairs(),
                ],
              ),
            ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
    );
  }

  List<Widget> _medicalPayServices(BuildContext context) => [
        _ServiceItem(
          iconColor: AppColors.elderPrimary,
          icon: Icons.health_and_safety_outlined,
          title: '浙里医保',
          chips: const ['医保地图', '医保个人账户', '医保'],
          department: '省医保局',
          onTap: null,
        ),
        _ServiceItem(
          iconColor: const Color(0xFFFF6D00),
          icon: Icons.manage_search,
          title: '社保费缴纳',
          chips: const ['社保医保缴费', '城乡居民基本医'],
          department: '省税务局',
          onTap: () => context.push(AppRoutes.shebaoJiaona),
        ),
        _ServiceItem(
          iconColor: AppColors.elderPrimary,
          icon: Icons.search,
          title: '社保查询',
          chips: const [],
          department: '省人力社保厅',
          onTap: () => context.push(AppRoutes.shebaoQuery),
        ),
      ];

  List<Widget> _pensionServices(BuildContext context) => [
        _ServiceItem(
          iconColor: AppColors.elderPrimary,
          icon: Icons.manage_search,
          title: '社保查询',
          chips: const ['养老险查询', '养老金', '失业险查'],
          department: '省人力社保厅',
          onTap: () => context.push(AppRoutes.shebaoQuery),
        ),
        _ServiceItem(
          iconColor: AppColors.elderPrimary,
          icon: Icons.calculate_outlined,
          title: '退休待遇测算',
          chips: const ['养老金测算', '企业养老保险待遇'],
          department: '省人力社保厅',
          onTap: null,
        ),
        _ServiceItem(
          iconColor: const Color(0xFFFF6D00),
          icon: Icons.print_outlined,
          title: '社保证明打印',
          chips: const ['历年养老证明', '养老险缴费凭证'],
          department: '省人力社保厅',
          onTap: null,
        ),
      ];

  List<Widget> _medicalQueryServices(BuildContext context) => [
        _ServiceItem(
          iconColor: AppColors.elderPrimary,
          icon: Icons.health_and_safety_outlined,
          title: '浙里医保',
          chips: const ['医保余额', '医保账户'],
          department: '省医保局',
          onTap: () => context.push(AppRoutes.yibaoQuery),
        ),
        _ServiceItem(
          iconColor: const Color(0xFFFF6D00),
          icon: Icons.manage_search,
          title: '医保缴费',
          chips: const ['城乡居民医保'],
          department: '省医保局',
          onTap: () => context.push(AppRoutes.yibaoJiaofei),
        ),
      ];

  List<Widget> _medicalPayAffairs() => [
        const _AffairItem('职工参保登记（医保）'),
        const _AffairItem('职工医保补缴'),
      ];

  List<Widget> _pensionAffairs() => [
        const _AffairItem('退休高级职称人员增加养老金待遇'),
      ];

  List<Widget> _medicalQueryAffairs() => [
        const _AffairItem('医保参保信息查询'),
        const _AffairItem('医保就诊记录查询'),
      ];
}

// ─── 子组件 ───────────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.lg),
      child: Center(
        child: Text('暂无相关服务',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            )),
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
    final disabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: AppColors.divider),
              boxShadow: disabled
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (disabled ? Colors.grey : iconColor)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      color: disabled ? Colors.grey : iconColor, size: 26),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color:
                                disabled ? Colors.grey : AppColors.textPrimary,
                          )),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: chips
                              .map((c) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(c,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary)),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(department,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 24,
                    color: disabled
                        ? Colors.grey.shade300
                        : AppColors.textSecondary),
              ],
            ),
          ),
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
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade500,
                  )),
            ),
            Icon(Icons.chevron_right, size: 24, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
