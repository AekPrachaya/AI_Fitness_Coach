import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/session_history_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StreakCard — current run on the left, personal best on the right.
// Reads the same streakProvider as the home header, so the two 🔥 numbers can
// never drift apart.
// ─────────────────────────────────────────────────────────────────────────────

class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final streak = ref.watch(streakProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  StreakBadge(streakCount: streak.current),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Current Streak', style: tt.labelMedium),
                ],
              ),
            ),
            Container(
              width: 1,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('🏆', style: tt.titleLarge),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${streak.best}',
                        style: tt.displaySmall?.copyWith(
                          color: AppColors.warning,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        streak.best == 1 ? 'day' : 'days',
                        style: tt.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Best Streak', style: tt.labelMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
