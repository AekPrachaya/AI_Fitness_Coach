import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';

class RestOverlay extends StatelessWidget {
  const RestOverlay({
    super.key,
    required this.secondsLeft,
    required this.currentSet,
    required this.targetSets,
    required this.onSkip,
  });

  final int secondsLeft;
  final int currentSet;
  final int targetSets;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.92),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'พักระหว่าง Set',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Countdown
                Text(
                  '$secondsLeft',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 96,
                      ),
                ),
                Text(
                  'วินาที',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Set ถัดไป: $currentSet / $targetSets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppSecondaryButton(
                  label: 'ข้ามการพัก',
                  leadingIcon: Icons.skip_next_rounded,
                  onTap: onSkip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
