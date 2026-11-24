import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/session_history_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Small "SAMPLE DATA" pill shown while Demo mode mixes the seeded demo year
/// into the workout history. Renders nothing when Demo mode is off, so it can
/// sit in a header permanently.
class DemoDataBadge extends ConsumerWidget {
  const DemoDataBadge({super.key});

  static const double _iconSize = 12;
  static const String _message =
      'Showing sample workouts. Turn off Demo mode in Profile.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(showDemoHistoryProvider)) return const SizedBox.shrink();

    final tt = Theme.of(context).textTheme;

    return Tooltip(
      message: _message,
      excludeFromSemantics: true,
      child: Semantics(
        label: _message,
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.circleAll,
            border: Border.all(color: AppColors.warning),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.science_outlined,
                size: _iconSize,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'SAMPLE DATA',
                style: tt.labelSmall?.copyWith(color: AppColors.warning),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
