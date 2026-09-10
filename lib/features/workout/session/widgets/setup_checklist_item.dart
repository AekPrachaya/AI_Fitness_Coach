import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SetupChecklistItem — one row of the pre-workout setup checklist.
// Tappable until satisfied; shows a green check once done.
// ─────────────────────────────────────────────────────────────────────────────

class SetupChecklistItem extends StatelessWidget {
  const SetupChecklistItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.actionLabel,
    required this.onTap,
    required this.index,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDone;
  final String actionLabel;
  final VoidCallback? onTap;
  final int index;

  static const double _markerSize = AppSpacing.xl;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isTappable = !isDone && onTap != null;

    return InkWell(
      onTap: isTappable ? onTap : null,
      borderRadius: AppRadius.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _Marker(
                key: ValueKey<bool>(isDone),
                icon: isDone ? Icons.check_rounded : icon,
                isDone: isDone,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.bodyMedium?.copyWith(
                      color: isDone
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: tt.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (isDone)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 20,
              )
            else
              Text(
                actionLabel,
                style: tt.labelLarge?.copyWith(color: AppColors.accent),
              ),
          ],
        ),
      ),
    )
        .animate(delay: (300 + index * 70).ms)
        .fadeIn(duration: 250.ms)
        .slideX(
          begin: -0.06,
          end: 0.0,
          duration: 250.ms,
          curve: Curves.easeOut,
        );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({super.key, required this.icon, required this.isDone});

  final IconData icon;
  final bool isDone;

  @override
  Widget build(BuildContext context) => Container(
        width: SetupChecklistItem._markerSize,
        height: SetupChecklistItem._markerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surfaceElevated,
          border: Border.all(
            color: isDone ? AppColors.accent : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDone ? AppColors.accent : AppColors.textSecondary,
        ),
      );
}
