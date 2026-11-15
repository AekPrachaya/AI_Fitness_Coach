import 'package:flutter/material.dart';
import '../../../../core/services/exercise_analyzer.dart';
import '../../../../core/services/form_coach.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// The live coaching line over the camera preview.
///
/// Read at a glance, from across a room, by someone mid-rep — so the
/// correction is the biggest text on the preview, on an opaque plate rather
/// than a tint, because a translucent banner over a moving camera feed is
/// legible only against whatever happens to be behind it.
class FormCueBanner extends StatelessWidget {
  const FormCueBanner({super.key, required this.cue});

  final FormCue cue;

  @override
  Widget build(BuildContext context) {
    final isPraise = cue.fault == null;
    final color = switch (cue.score) {
      FormScore.good => AppColors.scoreGood,
      FormScore.fair => AppColors.scoreOk,
      FormScore.poor => AppColors.scorePoor,
    };
    final icon = switch (cue.score) {
      FormScore.good => Icons.check_circle_rounded,
      FormScore.fair => Icons.info_rounded,
      FormScore.poor => Icons.warning_amber_rounded,
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      // Each cue slides up into place, so a correction replacing another one
      // is visibly a new instruction and not a re-render of the old.
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.35),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Container(
        // Keyed by the message so the switcher animates on new wording and
        // sits still while the same cue is being held.
        key: ValueKey(cue.message),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: isPraise
              ? AppColors.surface.withValues(alpha: 0.82)
              : color.withValues(alpha: 0.95),
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: color, width: isPraise ? 1 : 0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isPraise ? 18 : 22,
              color: isPraise ? color : AppColors.surface,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                cue.message,
                textAlign: TextAlign.center,
                style: isPraise
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        )
                    : Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
