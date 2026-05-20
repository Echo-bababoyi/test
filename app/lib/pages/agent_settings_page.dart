import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/state/app_state.dart';
import '../router.dart';
import '../services/agent_settings_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/agent_fab.dart';
import '../widgets/system_dialog.dart';
import '../widgets/trust_level_cards.dart';

class AgentSettingsPage extends ConsumerStatefulWidget {
  const AgentSettingsPage({super.key});
  @override
  ConsumerState<AgentSettingsPage> createState() => _AgentSettingsPageState();
}

class _AgentSettingsPageState extends ConsumerState<AgentSettingsPage> {
  final _svc = AgentSettingsService.instance;

  static const _kOrder = {'guide': 1, 'semi': 2, 'full': 3};

  void _onTrustChanged(String newLevel) {
    final current = _svc.trustLevel;
    if (current == newLevel) return;
    final isUpgrade = (_kOrder[newLevel] ?? 0) > (_kOrder[current] ?? 0);
    final title = _trustTitleFor(newLevel);
    if (isUpgrade) {
      SystemDialog.show(
        context,
        title: '切换权限',
        message: '即将切换到「$title」，小浙将帮您做更多。是否确认？',
        confirmLabel: '确认切换',
        denyLabel: '取消',
        onConfirm: () => _applyTrust(newLevel, title),
      );
    } else {
      _applyTrust(newLevel, title);
    }
  }

  void _applyTrust(String level, String title) {
    setState(() => _svc.trustLevel = level);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已切换到「$title」'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _trustTitleFor(String level) {
    switch (level) {
      case 'guide': return '我自己做，小浙提醒我';
      case 'semi':  return '小浙帮我填，我自己点提交';
      case 'full':  return '小浙全程代办，关键步骤我确认';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(loginProvider).isLoggedIn;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('小浙助手', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.elderPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
        children: [
          if (!isLoggedIn) const _LoginBanner(),
          const _SectionHeader(title: '小浙能帮您做多少'),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(Spacing.lg),
            child: TrustLevelCards(
              selected: isLoggedIn ? _svc.trustLevel : '',
              onChanged: _onTrustChanged,
              readonly: !isLoggedIn,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          const _SectionHeader(title: '语音设置'),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.volume_up_outlined, color: AppColors.elderPrimary),
                  title: const Text('语音引导', style: TextStyle(fontSize: 16)),
                  subtitle: Text(
                    _svc.voiceEnabled ? '已开启' : '已关闭',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  trailing: Switch(
                    value: _svc.voiceEnabled,
                    onChanged: (v) => setState(() => _svc.voiceEnabled = v),
                    activeColor: AppColors.elderPrimary,
                  ),
                ),
                const Divider(height: 1, indent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.speed_outlined, color: AppColors.elderPrimary),
                      const SizedBox(width: 16),
                      const Expanded(child: Text('语速', style: TextStyle(fontSize: 16))),
                      _SpeedBtn(label: '慢速', mode: 'slow', current: _svc.speedMode,
                          onTap: () => setState(() => _svc.speedMode = 'slow')),
                      const SizedBox(width: 8),
                      _SpeedBtn(label: '标准', mode: 'normal', current: _svc.speedMode,
                          onTap: () => setState(() => _svc.speedMode = 'normal')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const _SectionHeader(title: '我的记录'),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.work_outline, color: AppColors.elderPrimary),
                  title: const Text('操作记录', style: TextStyle(fontSize: 16)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () => context.push(AppRoutes.operationLogs),
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  leading: const Icon(Icons.edit_note_outlined, color: AppColors.elderPrimary),
                  title: const Text('草稿箱', style: TextStyle(fontSize: 16)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () => context.push(AppRoutes.drafts),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const _SectionHeader(title: '使用说明'),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                _HelpCard(icon: Icons.login_outlined, title: '登录引导',
                    desc: '说"帮我登录"，小浙引导您完成刷脸或验证码登录'),
                Divider(height: 24),
                _HelpCard(icon: Icons.health_and_safety_outlined, title: '医保缴费',
                    desc: '说"帮我缴医保"，小浙帮您填好表单，您亲手点支付'),
                Divider(height: 24),
                _HelpCard(icon: Icons.manage_search, title: '查询服务',
                    desc: '说"查我的养老金"，小浙一键导航到结果页并语音播报'),
              ],
            ),
          ),
        ],
      ),
          const Positioned.fill(
            child: AgentFab(currentPath: AppRoutes.agentSettings),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(title, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
  );
}

class _SpeedBtn extends StatelessWidget {
  final String label, mode, current;
  final VoidCallback onTap;
  const _SpeedBtn({required this.label, required this.mode, required this.current, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final sel = mode == current;
    return Material(
      color: sel ? AppColors.elderPrimary : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: sel ? Colors.white24 : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? AppColors.elderPrimary : const Color(0xFFDDDDDD)),
          ),
          child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
              color: sel ? Colors.white : AppColors.textPrimary)),
        ),
      ),
    );
  }
}

class _LoginBanner extends StatelessWidget {
  const _LoginBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF4D6),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, size: 20, color: Color(0xFFCC8800)),
          const SizedBox(width: Spacing.sm),
          const Expanded(
            child: Text(
              '登录后可调整小浙的工作方式',
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
          ),
          Material(
            color: AppColors.elderPrimary,
            borderRadius: BorderRadius.circular(AppRadius.xlarge),
            child: InkWell(
              onTap: () => context.push(AppRoutes.login),
              borderRadius: BorderRadius.circular(AppRadius.xlarge),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 6),
                child: Text(
                  '去登录',
                  style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  const _HelpCard({required this.icon, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.elderPrimary.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.elderPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.4)),
          ],
        )),
      ],
    );
  }
}
