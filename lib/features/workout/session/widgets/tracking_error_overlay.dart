import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Tells the user why rep counting has stopped and what to do about it.
///
/// Deliberately not a full scrim: they need to see themselves in the preview
/// to fix their position.
class TrackingErrorOverlay extends StatelessWidget {
  const TrackingErrorOverlay({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.88),
              borderRadius: AppRadius.lgAll,
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_search_rounded,
                  color: AppColors.error,
                  size: 40,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'หยุดนับชั่วคราว',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
