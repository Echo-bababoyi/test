import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/persistent_banner.dart';

class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final login = ref.watch(loginProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.elderPrimary,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              '个人账号',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(width: Spacing.sm),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.person_outline, size: 14),
              label: const Text('切换',
                  style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.white,
                side: BorderSide.none,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white),
            onPressed: null,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MyHeaderSection(login: login),
                const _MyActivitySection(),
                const SizedBox(height: Spacing.sm),
                const _MyCertSection(),
                _MyInfoSection(),
                const SizedBox(height: Spacing.sm),
                const _MyManagementSection(),
                const SizedBox(height: Spacing.sm),
                const _MyRecommendSection(),
                const _MySettingsSection(),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: PersistentBanner(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.grey[700],
        foregroundColor: Colors.white,
        onPressed: () => context.push(AppRoutes.search),
        child: const Icon(Icons.mic),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => context.go(AppRoutes.elderHome),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_border,
                        color: AppColors.textSecondary),
                    Text('首页',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 64),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.person,
                      color: AppColors.elderPrimary),
                  Text('我的',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.elderPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 头部用户卡 ───────────────────────────────────────────────────────────────

class _MyHeaderSection extends StatelessWidget {
  final LoginState login;
  const _MyHeaderSection({required this.login});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(Spacing.lg),
      child: Row(
        children: [
          // 头像
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF90CAF9), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 36),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  login.isLoggedIn ? (login.userName ?? '*宇澄') : '游客',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Row(
                  children: [
                    // 实名认证徽章
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFFB300)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified,
                              size: 12,
                              color: Color(0xFFFFB300)),
                          SizedBox(width: 2),
                          Text('高级实名',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFFFB300))),
                          Icon(Icons.chevron_right,
                              size: 12,
                              color: Color(0xFFFFB300)),
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 13,
                            color: AppColors.textSecondary),
                        SizedBox(width: 2),
                        Text('编辑资料',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 活动记录 2-col 图标区 ─────────────────────────────────────────────────────

class _MyActivitySection extends StatelessWidget {
  const _MyActivitySection();

  static const _items = [
    (Icons.work_outline, '办事记录'),
    (Icons.edit_note_outlined, '我的草稿'),
    (Icons.history, '我的足迹'),
    (Icons.bookmark_add_outlined, '我的订阅'),
    (Icons.chat_bubble_outline, '诉求记录'),
    (Icons.star_rate_outlined, '评价记录'),
    (Icons.feedback_outlined, '反馈记录'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.lg,
      ),
      child: Column(
        children: [
          for (int row = 0; row < (_items.length / 2).ceil(); row++)
            Padding(
              padding: row > 0
                  ? const EdgeInsets.only(top: Spacing.xl)
                  : EdgeInsets.zero,
              child: Row(
                children: [
                  for (int col = 0; col < 2; col++)
                    if (row * 2 + col < _items.length)
                      Expanded(
                        child: _ActivityIcon(
                          icon: _items[row * 2 + col].$1,
                          label: _items[row * 2 + col].$2,
                        ),
                      )
                    else
                      const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActivityIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.elderPrimary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.elderPrimary, size: 26),
        ),
        const SizedBox(height: Spacing.sm),
        Text(label,
            style: const TextStyle(fontSize: 13),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ─── 我的证照（横向滑动卡片）────────────────────────────────────────────────────

class _MyCertSection extends StatelessWidget {
  const _MyCertSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('我的证照',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    Text('全部',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                    Icon(Icons.chevron_right,
                        size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              children: const [
                _CertCard(
                  label: '老年人优待证',
                  color1: Color(0xFFA5D6A7),
                  color2: Color(0xFF66BB6A),
                  icon: Icons.elderly,
                ),
                SizedBox(width: Spacing.md),
                _CertCard(
                  label: '医保电子凭证',
                  color1: Color(0xFF64B5F6),
                  color2: Color(0xFF2196F3),
                  icon: Icons.health_and_safety_outlined,
                ),
                SizedBox(width: Spacing.md),
                _CertCard(
                  label: '住房公积金',
                  color1: Color(0xFF80CBC4),
                  color2: Color(0xFF26A69A),
                  icon: Icons.home_work_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CertCard extends StatelessWidget {
  final String label;
  final Color color1;
  final Color color2;
  final IconData icon;

  const _CertCard({
    required this.label,
    required this.color1,
    required this.color2,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.sm),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 我的信息（3-col 图标）─────────────────────────────────────────────────────

class _MyInfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg, vertical: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('我的信息',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  Text('全部',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                  Icon(Icons.chevron_right,
                      size: 16, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _InfoIcon(
                    icon: Icons.security_outlined,
                    color: Color(0xFFFF6D00),
                    label: '社保'),
                _InfoIcon(
                    icon: Icons.home_work_outlined,
                    color: Color(0xFFFFB300),
                    label: '公积金'),
                _InfoIcon(
                    icon: Icons.receipt_long_outlined,
                    color: Color(0xFF26C6DA),
                    label: '票据'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _InfoIcon(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: Spacing.sm),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

// ─── 我的管理（2+1 图标区）────────────────────────────────────────────────────

class _MyManagementSection extends StatelessWidget {
  const _MyManagementSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg, vertical: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('我的管理',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: _ManageIcon(
                    icon: Icons.people_outline, label: '亲友联系人'),
              ),
              Expanded(
                child: _ManageIcon(
                    icon: Icons.verified_user_outlined, label: '我的授权'),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          Row(
            children: [
              Expanded(
                child: _ManageIcon(
                    icon: Icons.approval_outlined, label: '我的印章'),
              ),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManageIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ManageIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.elderPrimary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.elderPrimary, size: 26),
        ),
        const SizedBox(height: Spacing.sm),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

// ─── 服务推荐（2×2 图标网格）─────────────────────────────────────────────────

class _MyRecommendSection extends StatelessWidget {
  const _MyRecommendSection();

  static const _items = [
    (Icons.shield_outlined, '社保医保税...'),
    (Icons.manage_search, '社保查询'),
    (Icons.person_search_outlined, '个人权益记...'),
    (Icons.home_work_outlined, '住房公积金'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg, vertical: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('服务推荐',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  Text('全部',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                  Icon(Icons.chevron_right,
                      size: 16, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              for (int i = 0; i < 2; i++)
                Expanded(
                  child: _RecommendIcon(
                      icon: _items[i].$1, label: _items[i].$2),
                ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          Row(
            children: [
              for (int i = 2; i < 4; i++)
                Expanded(
                  child: _RecommendIcon(
                      icon: _items[i].$1, label: _items[i].$2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RecommendIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.standardPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.standardPrimary, size: 26),
        ),
        const SizedBox(height: Spacing.sm),
        Text(label,
            style: const TextStyle(fontSize: 13),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ─── 设置区（ListTile 两项）───────────────────────────────────────────────────

class _MySettingsSection extends StatelessWidget {
  const _MySettingsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.elderPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings_outlined,
                  color: AppColors.elderPrimary, size: 18),
            ),
            title: const Text('设置',
                style: TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
            onTap: null,
          ),
          const Divider(height: 1, indent: 16),
          ListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.elderPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline,
                  color: AppColors.elderPrimary, size: 18),
            ),
            title: const Text('关于浙里办',
                style: TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
            onTap: null,
          ),
          const SizedBox(height: Spacing.lg),
        ],
      ),
    );
  }
}
