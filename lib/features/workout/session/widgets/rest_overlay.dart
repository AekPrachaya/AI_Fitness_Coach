import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../shared/widgets/app_button.dart';

/// The rest between sets: a countdown ring over a slowly breathing glow, with
/// buttons to stretch or cut the rest and to skip it.
class RestOverlay extends StatelessWidget {
  const RestOverlay({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.nextSet,
    required this.targetSets,
    required this.onAdd30,
    required this.onSubtract15,
    required this.onSkip,
  });

  final int secondsLeft;

  /// Full length of this rest, for the ring's proportion.
  final int totalSeconds;

  /// The set that starts when the rest ends.
  final int nextSet;
  final int targetSets;

  final VoidCallback onAdd30;
  final VoidCallback onSubtract15;
  final VoidCallback onSkip;

  /// Below this many seconds the ring turns amber: time to get in position.
  static const int _warnAtSeconds = 5;

  static const double _ringRadius = 110;
  static const double _ringWidth = 10;
  static const double _glowSize = _ringRadius * 2.4;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final percent = totalSeconds > 0
        ? (secondsLeft / totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final ringColor = secondsLeft <= _warnAtSeconds
        ? AppColors.warning
        : AppColors.accent;
    final calm = MediaQuery.disableAnimationsOf(context);

    Widget glow = Container(
      width: _glowSize,
      height: _glowSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [AppColors.accentGlow, AppColors.accent.withValues(alpha: 0)],
        ),
      ),
    );
    if (!calm) {
      glow = glow
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 0.9,
            end: 1.1,
            duration: 2.seconds,
            curve: Curves.easeInOut,
          )
          .fade(begin: 0.5, end: 1, duration: 2.seconds);
    }

    return Container(
      color: AppColors.background.withValues(alpha: 0.92),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('REST', style: tt.displaySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'NEXT: SET $nextSet/$targetSets',
                  style: tt.labelLarge?.copyWith(color: AppColors.accent),
                ),
                const SizedBox(height: AppSpacing.xl),
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    IgnorePointer(child: glow),
                    CircularPercentIndicator(
                      radius: _ringRadius,
                      lineWidth: _ringWidth,
                      percent: percent,
                      animation: !calm,
                      animateFromLastPercent: true,
                      animationDuration: 900,
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: ringColor,
                      backgroundColor: AppColors.borderSubtle,
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatClock(secondsLeft),
                            style: tt.displayLarge?.copyWith(
                              color: ringColor,
                              height: 1,
                            ),
                          ),
                          Text('SECONDS LEFT', style: tt.labelMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: '−15s',
                        leadingIcon: Icons.remove_rounded,
                        onTap: onSubtract15,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppSecondaryButton(
                        label: '+30s',
                        leadingIcon: Icons.add_rounded,
                        onTap: onAdd30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppPrimaryButton(
                  label: 'Skip Rest',
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
