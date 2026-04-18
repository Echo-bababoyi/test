import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';

class PensionQueryPage extends StatelessWidget {
  const PensionQueryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text(
          '社保查询',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: null),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 个人基本信息卡（蓝色渐变）
            Container(
              margin: const EdgeInsets.all(Spacing.lg),
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6EA8E8), Color(0xFF4A7FD4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '个人基本信息',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Row(
                        children: const [
                          Text(
                            '姓名',
                            style: TextStyle(
                                fontSize: 14, color: Colors.white70),
                          ),
                          Spacer(),
                          Text(
                            '*宇澄',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      Row(
                        children: const [
                          Text(
                            '证件号码',
                            style: TextStyle(
                                fontSize: 14, color: Colors.white70),
                          ),
                          Spacer(),
                          Text(
                            '3****************3',
                            style: TextStyle(
                                fontSize: 13, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // SI 水印字
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Text(
                      'SI',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 险种信息标题
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    color: AppColors.standardPrimary,
                  ),
                  const SizedBox(width: Spacing.sm),
                  const Text(
                    '险种信息',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            // 险种卡列表
            _InsuranceCard(
              title: '企业职工基本养老保险',
              icon: Icons.person_outline,
            ),
            _InsuranceCard(
              title: '失业保险',
              icon: Icons.shield_outlined,
            ),
            _InsuranceCard(
              title: '工伤保险',
              icon: Icons.personal_injury_outlined,
            ),
            const SizedBox(height: Spacing.xl),
          ],
        ),
      ),
    );
  }
}

// ─── 险种卡片 ─────────────────────────────────────────────────────────────────

class _InsuranceCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const _InsuranceCard({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 深蓝紫渐变头
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.md,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C4A9E), Color(0xFF3B2D8B)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.large - 1),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: Spacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // 省份地图占位
                Container(
                  width: 36,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                const Icon(Icons.location_on_outlined,
                    color: Colors.white70, size: 16),
                const Text('-',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          // 参保状态
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Text(
              '参保状态：未在浙江省内参保',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const Divider(height: 1),
          // 操作按钮行
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: null,
                    child: const Text('基本信息',
                        style: TextStyle(fontSize: 14)),
                  ),
                ),
                const VerticalDivider(
                    width: 1, indent: 8, endIndent: 8),
                Expanded(
                  child: TextButton(
                    onPressed: null,
                    child: const Text('缴费信息',
                        style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
