import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/in_app_overlay.dart';

class ElderHomePage extends ConsumerStatefulWidget {
  const ElderHomePage({super.key});

  @override
  ConsumerState<ElderHomePage> createState() => _ElderHomePageState();
}

class _ElderHomePageState extends ConsumerState<ElderHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    // §5.1 Q3：首帧完成后一次性检查登录态，不用 ref.listen 避免重复触发
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ref.read(loginProvider).isLoggedIn) {
        InAppOverlay.show(
          context,
          child: _LoginPromptContent(
            onLogin: () {
              Navigator.of(context).pop();
              context.go(AppRoutes.login);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.elderPrimary,
        titleSpacing: Spacing.lg,
        title: Row(
          children: [
            // 地区选择占位（西湖区▼）
            Container(width: 64, height: 24, color: Colors.white24),
          ],
        ),
        actions: [
          // 个人频道占位
          Container(
            margin: const EdgeInsets.only(right: Spacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm, vertical: 4,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white54),
              borderRadius: BorderRadius.circular(AppRadius.xlarge),
            ),
            child: const Text(
              '个人频道',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => context.go(AppRoutes.search),
          ),
        ],
        // AppBar bottom：工具行 + TabBar 合并为 PreferredSize
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0 + kTextTabBarHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 扫一扫 | 消息 | 常规版 工具行
              SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _EldToolBarItem(label: '扫一扫'),
                    _EldToolBarItem(label: '消息'),
                    _EldToolBarItem(label: '常规版'),
                  ],
                ),
              ),
              TabBar(
                controller: _tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: '热门服务'),
                  Tab(text: '我的常用'),
                  Tab(text: '我的订阅'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _HotServiceTab(),
          _FavoritesTab(),
          _SubscriptionTab(),
        ],
      ),
      bottomNavigationBar: const _ElderBottomNavBar(),
    );
  }
}

// ─── AppBar 工具栏小项（扫一扫 / 消息 / 常规版）────────────────────────────

class _EldToolBarItem extends StatelessWidget {
  final String label;
  const _EldToolBarItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 24, height: 20, color: Colors.white24),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}

// ─── 政务服务热线条（3 个 Tab 共用）─────────────────────────────────────────

class _EldGovHotlineSection extends StatelessWidget {
  const _EldGovHotlineSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(Spacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md, vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
      ),
      child: Row(
        children: [
          Container(width: 32, height: 32, color: Colors.grey[300]),
          const SizedBox(width: Spacing.md),
          const Expanded(
            child: Text('政务服务热线', style: TextStyle(fontSize: 16)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(AppRadius.xlarge),
            ),
            child: const Text('去拨打', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── 热门服务 Tab ─────────────────────────────────────────────────────────────

class _HotServiceTab extends StatelessWidget {
  const _HotServiceTab();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EldGovHotlineSection(),
          _EldHotServiceCardSection(),    // 段一：热门服务快捷卡片
          _EldOnlineServiceSection(),     // 段二：线上一站办
          _EldOfflineAndFooterSection(),  // 段三：线下就近办 + 授权办 + 页脚
        ],
      ),
    );
  }
}

// ─── 段一：热门服务快捷卡片（住址变动落户 + 权益记录查询）─────────────────────

class _EldHotServiceCardSection extends StatelessWidget {
  const _EldHotServiceCardSection();

  static const _items = ['住址变动落户', '权益记录查询'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      padding: const EdgeInsets.all(Spacing.md),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final label in _items) ...[
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 56, height: 56, color: Colors.grey[300],
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(label, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Spacing.md),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.xl, vertical: Spacing.sm,
              ),
              color: Colors.grey[100],
              child: const Text(
                '查看全部 ›',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 段二：线上一站办（2 × 3 格栅）──────────────────────────────────────────

class _EldOnlineServiceSection extends StatelessWidget {
  const _EldOnlineServiceSection();

  static const _items = [
    '健康医保', '社会保障',
    '行驶驾驶', '身份户籍',
    '文旅体育', '查看全部',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '线上一站办',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Spacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Spacing.md,
            crossAxisSpacing: Spacing.md,
            childAspectRatio: 1.6,
            children: [
              for (final label in _items)
                _EldServiceGridItem(label: label),
            ],
          ),
        ],
      ),
    );
  }
}

class _EldServiceGridItem extends StatelessWidget {
  final String label;
  const _EldServiceGridItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 40, height: 40, color: Colors.grey[300]),
          const SizedBox(height: Spacing.xs),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── 段三：线下就近办 + 授权办 + 页脚 ────────────────────────────────────────

class _EldOfflineAndFooterSection extends StatelessWidget {
  const _EldOfflineAndFooterSection();

  static const _officeItems = [
    '杭州市西湖区三墩镇…',
    '杭州联合农村商业银…',
    '杭州市西湖区三墩镇…',
  ];

  static const _authItems = [
    '老年人优待证', '养老保险年限',
    '高龄津贴', '法律援助申请',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 线下就近办
        Container(
          margin: const EdgeInsets.only(top: Spacing.md),
          padding: const EdgeInsets.all(Spacing.lg),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '线下就近办',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: Spacing.md),
              // 地图占位
              Container(
                height: 80,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.xl, vertical: Spacing.sm,
                  ),
                  color: Colors.grey[400],
                  child: const Text('从地图上查找更多大厅 ›',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              const Text('附近有 37 家大厅',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: Spacing.sm),
              for (final name in _officeItems) ...[
                _EldOfficeItem(name: name),
                const Divider(height: 1),
              ],
            ],
          ),
        ),
        // 授权办
        Container(
          margin: const EdgeInsets.only(top: Spacing.md),
          padding: const EdgeInsets.all(Spacing.lg),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '授权办',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: Spacing.md),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: Spacing.md,
                crossAxisSpacing: Spacing.md,
                childAspectRatio: 1.6,
                children: [
                  for (final label in _authItems)
                    _EldServiceGridItem(label: label),
                ],
              ),
            ],
          ),
        ),
        // 页脚
        Container(
          padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
          color: AppColors.surface,
          alignment: Alignment.center,
          child: const Text(
            '浙里办伴你一生大小事',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class _EldOfficeItem extends StatelessWidget {
  final String name;
  const _EldOfficeItem({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm, vertical: 2,
                      ),
                      color: Colors.grey[200],
                      child: const Text('空闲',
                          style: TextStyle(fontSize: 11, color: Colors.green)),
                    ),
                    const SizedBox(width: Spacing.sm),
                    const Text('距您1.5km',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm,
            ),
            color: Colors.grey[300],
            child: const Text('去办事', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── 我的常用 Tab ─────────────────────────────────────────────────────────────

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  static const _items = ['浙里医保', '社保查询'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _EldGovHotlineSection(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
            padding: const EdgeInsets.all(Spacing.md),
            color: AppColors.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    for (final label in _items) ...[
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 56, height: 56, color: Colors.grey[300],
                            ),
                            const SizedBox(height: Spacing.sm),
                            Text(label, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Spacing.md),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.xl, vertical: Spacing.sm,
                    ),
                    color: Colors.grey[100],
                    child: const Text(
                      '查看全部 ›',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _EldOnlineServiceSection(),
        ],
      ),
    );
  }
}

// ─── 我的订阅 Tab ─────────────────────────────────────────────────────────────

class _SubscriptionTab extends StatelessWidget {
  const _SubscriptionTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _EldGovHotlineSection(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
            padding: const EdgeInsets.all(Spacing.xl),
            color: AppColors.surface,
            child: Column(
              children: [
                const SizedBox(height: Spacing.xl),
                const Text(
                  '您还没有订阅任何服务',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: Spacing.xl),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.xl, vertical: Spacing.sm,
                    ),
                    color: Colors.grey[100],
                    child: const Text(
                      '查看全部 ›',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _EldOnlineServiceSection(),
        ],
      ),
    );
  }
}

// ─── 底部导航（首页 / 我的）────────────────────────────────────────────────────

class _ElderBottomNavBar extends StatelessWidget {
  const _ElderBottomNavBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      selectedItemColor: AppColors.elderPrimary,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.star), label: '首页'),
        BottomNavigationBarItem(icon: Icon(Icons.mic), label: '搜索'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
      ],
      onTap: (i) {
        if (i == 1) context.go(AppRoutes.search);
        if (i == 2) context.go(AppRoutes.my);
      },
    );
  }
}

// ─── 立即登录 InAppOverlay 内容 ───────────────────────────────────────────────

class _LoginPromptContent extends StatelessWidget {
  final VoidCallback onLogin;
  const _LoginPromptContent({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '登录享受更多服务',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        FilledButton(
          onPressed: onLogin,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.elderPrimary,
          ),
          child: const Text('立即登录'),
        ),
      ],
    );
  }
}
