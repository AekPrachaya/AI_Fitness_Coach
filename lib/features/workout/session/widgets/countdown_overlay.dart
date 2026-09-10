import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CountdownOverlay — full-bleed 3-2-1 layer shown over the pre-workout screen.
// [count] counts down to 0, which renders as "GO".
// ─────────────────────────────────────────────────────────────────────────────

class CountdownOverlay extends StatelessWidget {
  const CountdownOverlay({
    super.key,
    required this.count,
    required this.onCancel,
  });

  final int count;
  final VoidCallback onCancel;

  static const double _ringSize = 220.0;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isGo = count <= 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: ColoredBox(
        color: AppColors.background.withValues(alpha: 0.94),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isGo ? "Let's go" : 'Get in position',
                style: tt.titleLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: _ringSize,
                height: _ringSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      key: ValueKey<String>('ring-$count'),
                      tween: Tween<double>(begin: 1.0, end: isGo ? 1.0 : 0.0),
                      duration: const Duration(seconds: 1),
                      builder: (_, value, _) => CustomPaint(
                        size: const Size.square(_ringSize),
                        painter: _RingPainter(progress: value),
                      ),
                    ),
                    Text(
                      isGo ? 'GO' : '$count',
                      style: AppTypography.countdownNumeral,
                    )
                        .animate(key: ValueKey<String>('numeral-$count'))
                        .fadeIn(duration: 180.ms)
                        .scale(
                          begin: const Offset(1.35, 1.35),
                          end: const Offset(1.0, 1.0),
                          duration: 420.ms,
                          curve: Curves.easeOutBack,
                        ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: AppSpacing.xxl,
                child: isGo
                    ? null
                    : AppGhostButton(label: 'Cancel', onTap: onCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ring ──────────────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  /// 1.0 = full ring, 0.0 = drained.
  final double progress;

  static const double _stroke = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - _stroke) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
