import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// The bottom HUD panel: the rep count, big enough to read from across the
/// room, over a row of secondary metrics — joint angle, how long the last rep
/// took, and the running form score.
///
/// Each counted rep pops the numeral and flashes a glow behind it, so the
/// count registers even in the corner of the eye mid-movement.
class RepCounterPanel extends StatelessWidget {
  const RepCounterPanel({
    super.key,
    required this.repCount,
    required this.targetReps,
    required this.bodyFound,
    required this.angleLabel,
    required this.angleText,
    required this.repTimeText,
    required this.formScore,
  });

  final int repCount;
  final int targetReps;

  /// Shown as a small dot by the REPS label; a lost body also raises the
  /// full-screen tracking overlay, so this only needs to be a glance.
  final bool bodyFound;

  final String angleLabel;
  final String angleText;

  /// Duration of the last rep, already formatted (`2.4s`, or `--`).
  final String repTimeText;

  /// Running mean form score, 0–100. Zero means nothing graded yet.
  final double formScore;

  @override
  Widget build(BuildContext context) {
    final graded = formScore > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RepCount(
            repCount: repCount,
            targetReps: targetReps,
            bodyFound: bodyFound,
          ),
          const Divider(
            color: AppColors.divider,
            height: AppSpacing.lg,
            thickness: 1,
          ),
          Row(
            children: [
              Expanded(
                child: _Metric(label: angleLabel, value: angleText),
              ),
              Expanded(
                child: _Metric(label: 'REP TIME', value: repTimeText),
              ),
              Expanded(
                child: _Metric(
                  label: 'FORM',
                  // Truncated, like FormScoreBadge and the summary screen.
                  value: graded ? '${formScore.toInt()}%' : '--',
                  valueColor: graded
                      ? AppColors.formScoreColor(formScore)
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RepCount extends StatelessWidget {
  const _RepCount({
    required this.repCount,
    required this.targetReps,
    required this.bodyFound,
  });

  final int repCount;
  final int targetReps;
  final bool bodyFound;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    // A fresh screen or a fresh set resets to zero: nothing was counted, so
    // nothing should celebrate.
    final pulse = repCount > 0 && !MediaQuery.disableAnimationsOf(context);

    Widget numeral = Text(
      '$repCount',
      style: tt.displayLarge?.copyWith(color: AppColors.accent, height: 1),
    );
    Widget glow = const DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accentGlow,
      ),
    );

    if (pulse) {
      // Keyed on the count so every new rep restarts the effect.
      numeral = numeral
          .animate(key: ValueKey(repCount))
          .scaleXY(
            begin: 1.25,
            end: 1,
            duration: 280.ms,
            curve: Curves.easeOutBack,
          );
      glow = glow
          .animate(key: ValueKey(repCount))
          .scaleXY(
            begin: 0.6,
            end: 1.4,
            duration: 450.ms,
            curve: Curves.easeOut,
          )
          .fadeOut(duration: 450.ms, curve: Curves.easeIn);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (pulse) Positioned.fill(child: IgnorePointer(child: glow)),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                numeral,
                Text(
                  ' / $targetReps',
                  style: tt.displaySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Semantics(
          label: bodyFound ? 'พบตัวแล้ว' : 'ไม่พบตัว',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSpacing.sm,
                height: AppSpacing.sm,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bodyFound ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('REPS', style: tt.labelMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: tt.labelMedium,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: tt.titleLarge?.copyWith(color: valueColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
