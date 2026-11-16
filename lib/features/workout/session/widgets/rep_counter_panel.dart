import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// The bottom HUD panel: the rep count, big enough to read from across the
/// room, flanked by the joint angle and whether a body is in frame.
///
/// Each counted rep pops the numeral and flashes a glow behind it, so the
/// count registers even in the corner of the eye mid-movement.
class RepCounterPanel extends StatelessWidget {
  const RepCounterPanel({
    super.key,
    required this.repCount,
    required this.targetReps,
    required this.angleLabel,
    required this.angleText,
    required this.bodyFound,
  });

  final int repCount;
  final int targetReps;
  final String angleLabel;
  final String angleText;
  final bool bodyFound;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SideMetric(label: angleLabel, value: angleText),
          ),
          _RepCount(repCount: repCount, targetReps: targetReps),
          Expanded(
            child: _SideMetric(
              label: 'สถานะ',
              value: bodyFound ? 'พบแล้ว' : 'ไม่เจอ',
              valueColor: bodyFound ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepCount extends StatelessWidget {
  const _RepCount({required this.repCount, required this.targetReps});

  final int repCount;
  final int targetReps;

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
        Text('REPS', style: tt.labelMedium),
      ],
    );
  }
}

class _SideMetric extends StatelessWidget {
  const _SideMetric({
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
        Text(label, style: tt.bodySmall, textAlign: TextAlign.center),
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
