import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_card.dart';
import '../progress_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExerciseStatsSection — one expandable row per exercise, busiest first.
// Rows roll their own expander: Material's ExpansionTile brings dividers,
// padding and splash colours that fight the design system.
// ─────────────────────────────────────────────────────────────────────────────

class ExerciseStatsSection extends ConsumerWidget {
  const ExerciseStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final stats = ref.watch(exerciseStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text('By Exercise', style: tt.titleLarge),
        ),
        if (stats.isEmpty)
          const _NoExerciseData()
        else
          ...stats.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ExerciseRow(stats: s),
              )),
      ],
    );
  }
}

class _NoExerciseData extends StatelessWidget {
  const _NoExerciseData();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AppCard(
      child: Row(
        children: [
          const Icon(
            Icons.fitness_center_rounded,
            size: 20,
            color: AppColors.textDisabled,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'No exercise data yet',
              style: tt.bodySmall?.copyWith(color: AppColors.textDisabled),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Row ──────────────────────────────────────────────────────────────────────

class _ExerciseRow extends StatefulWidget {
  const _ExerciseRow({required this.stats});

  final ExerciseStats stats;

  @override
  State<_ExerciseRow> createState() => _ExerciseRowState();
}

class _ExerciseRowState extends State<_ExerciseRow> {
  bool _expanded = false;

  static const double _sparkWidth = 56.0;
  static const double _sparkHeight = 20.0;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final stats = widget.stats;

    return AppCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stats.exerciseName, style: tt.bodyMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${stats.sessionCount} '
                        '${stats.sessionCount == 1 ? 'session' : 'sessions'}',
                        style: tt.bodySmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: _sparkWidth,
                  height: _sparkHeight,
                  child: CustomPaint(
                    painter: _SparklinePainter(
                      values: stats.formTrend,
                      color: stats.hasTrend
                          ? AppColors.formScoreColor(stats.avgFormScore)
                          : AppColors.textDisabled,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: AppSpacing.md),
              _DetailRow(
                label: 'Avg reps / session',
                child: Text(
                  stats.avgRepsPerSession.toStringAsFixed(1),
                  style: tt.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailRow(
                label: 'Avg form',
                child: FormScoreBadge(score: stats.avgFormScore),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailRow(
                label: 'Most common issue',
                child: Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppColors.scoreOk,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          stats.mostCommonError,
                          style: tt.bodySmall,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: tt.labelLarge),
        const SizedBox(width: AppSpacing.md),
        child,
      ],
    );
  }
}

// ── Sparkline ────────────────────────────────────────────────────────────────

/// A painter rather than a tiny LineChart: one chart per row would drag in a
/// touch layer and an animation controller for a 56×20 decoration.
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  static const double _stroke = 1.5;
  static const double _dotRadius = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Too little history to plot a shape — draw the baseline instead.
    if (values.length < 2) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = max - min;
    final stepX = size.width / (values.length - 1);
    final usableHeight = size.height - _dotRadius * 2;

    Offset pointAt(int i) {
      // A flat series would divide by zero — centre it instead.
      final normalised = span == 0 ? 0.5 : (values[i] - min) / span;
      return Offset(
        stepX * i,
        _dotRadius + usableHeight * (1 - normalised),
      );
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final point = pointAt(i);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);

    canvas.drawCircle(
      pointAt(values.length - 1),
      _dotRadius,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      !listEquals(oldDelegate.values, values) || oldDelegate.color != color;
}
