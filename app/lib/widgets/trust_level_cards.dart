import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class TrustLevelCards extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final bool readonly;

  const TrustLevelCards({
    super.key,
    required this.selected,
    required this.onChanged,
    this.readonly = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final card in _kCards)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: _TrustCard(
              data: card,
              isSelected: card.level == selected,
              onTap: readonly ? null : () => onChanged(card.level),
            ),
          ),
        const SizedBox(height: Spacing.xs),
        const _TrustFooter(),
      ],
    );
    return readonly ? Opacity(opacity: 0.4, child: body) : body;
  }
}

class _CardData {
  final String level;
  final String emoji;
  final String title;
  final String subtitle;
  const _CardData(this.level, this.emoji, this.title, this.subtitle);
}

const _kCards = <_CardData>[
  _CardData('guide', '🗣', '我自己做，小浙提醒我',     '小浙用语音教您每一步，您亲手操作'),
  _CardData('semi',  '✋', '小浙帮我填，我自己点提交',  '小浙帮您填表单，敏感信息会问您'),
  _CardData('full',  '🤖', '小浙全程代办，关键步骤我确认', '小浙能填身份证等，登录支付要您动手'),
];

class _TrustCard extends StatelessWidget {
  final _CardData data;
  final bool isSelected;
  final VoidCallback? onTap;
  const _TrustCard({required this.data, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: isSelected ? AppColors.elderPrimary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      data.subtitle,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              _Radio(selected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;
  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.elderPrimary : AppColors.textSecondary,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.elderPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class _TrustFooter extends StatelessWidget {
  const _TrustFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('🔒', style: TextStyle(fontSize: 16)),
          SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              '登录、提交、支付始终由您亲手完成\n小浙不会代替您操作',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
