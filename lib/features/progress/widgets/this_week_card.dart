import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/session_history_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ThisWeekCard — Mon–Sun totals. Deliberately numbers only: the heatmap above
// already carries the day-by-day shape, so a second bar chart would repeat it.
// ─────────────────────────────────────────────────────────────────────────────

class ThisWeekCard extends ConsumerWidget {
  const ThisWeekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final stats = ref.watch(weekStatsProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week', style: tt.titleLarge),
          const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              children: [
                _Stat(value: '${stats.totalWorkouts}', label: 'WORKOUTS'),
                const _CellDivider(),
                _Stat(value: stats.minutesDisplay, label: 'TIME'),
                const _CellDivider(),
                _Stat(value: '${stats.estimatedCalories}', label: 'KCAL'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: tt.displaySmall?.copyWith(color: AppColors.accent),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: tt.labelMedium),
        ],
      ),
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        color: AppColors.divider,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      );
}
