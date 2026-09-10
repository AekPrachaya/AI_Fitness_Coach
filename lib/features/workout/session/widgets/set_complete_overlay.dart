import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// The short beat between the last rep of a set and the rest timer, so the set
/// does not simply vanish into a countdown.
class SetCompleteOverlay extends StatelessWidget {
  const SetCompleteOverlay({
    super.key,
    required this.currentSet,
    required this.targetSets,
    required this.reps,
  });

  final int currentSet;
  final int targetSets;
  final int reps;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return IgnorePointer(
      child: Container(
        color: AppColors.background.withValues(alpha: 0.72),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 72,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Set $currentSet/$targetSets เสร็จ!',
                style: tt.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$reps reps',
                style: tt.titleMedium?.copyWith(color: AppColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
