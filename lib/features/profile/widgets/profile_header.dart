import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/app_card.dart';
import '../profile_logic.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top of the Profile screen: avatar + identity, then the lifetime stats row.
// ─────────────────────────────────────────────────────────────────────────────

const _months = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', //
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final joined = profile.joinedAt;
    final since = '${_months[joined.month - 1]} ${joined.year}';

    return Row(
      children: [
        _Avatar(name: profile.name),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.headlineSmall,
              ),
              if (profile.email.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                'MEMBER SINCE $since',
                style: tt.labelMedium?.copyWith(color: AppColors.accent),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return ExcludeSemantics(
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.accent, AppColors.accentBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Text(
          initial,
          style: tt.displaySmall?.copyWith(color: AppColors.background),
        ),
      ),
    );
  }
}

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key, required this.stats});
  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final avg = stats.avgFormScore;
    return Row(
      children: [
        Expanded(
          child: _StatTile(value: '${stats.workouts}', label: 'WORKOUTS'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(value: stats.totalTimeLabel, label: 'TOTAL TIME'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            value: stats.avgFormLabel,
            label: 'AVG FORM',
            color: avg == null
                ? AppColors.textSecondary
                : AppColors.formScoreColor(avg),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, this.color});
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return MergeSemantics(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: tt.displaySmall?.copyWith(
                  color: color ?? AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              label,
              style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
