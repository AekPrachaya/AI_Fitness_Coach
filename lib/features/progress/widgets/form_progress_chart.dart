import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../progress_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FormProgressChart — average form score per active day over 30 days.
//
// Follows the house chart style set by WeeklyActivityChart (no border, tooltip
// on surfaceElevated, textTheme.copyWith for the TextStyles fl_chart demands)
// with two deliberate departures: horizontal grid lines and left axis labels
// stay ON, because a score curve with no reference line cannot be read.
// ─────────────────────────────────────────────────────────────────────────────

class FormProgressChart extends ConsumerWidget {
  const FormProgressChart({super.key});

  static const double _chartHeight = 150.0;
  static const double _minScore = 50.0;
  static const double _maxScore = 100.0;

  /// Past this many points the dots crowd the line, so only the curve is drawn.
  static const int _maxDots = 14;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final points = ref.watch(formScoreSeriesProvider);

    final latest = points.isEmpty ? null : points.last.score;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Form Progress', style: tt.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Last $kFormTrendDays days',
                    style:
                        tt.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              if (latest != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${latest.round()}%',
                      style: tt.headlineMedium?.copyWith(
                        color: AppColors.formScoreColor(latest),
                        fontFamily: 'BebasNeue',
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'latest',
                      style: tt.labelMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: _chartHeight,
            child: points.length < 2
                ? const _EmptyState()
                : _ScoreLine(points: points),
          ),
        ],
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({required this.points});

  final List<FormScorePoint> points;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // x = days ago inverted, so today sits at the right edge.
    final spots = points
        .map((p) => FlSpot(
              (kFormTrendDays - 1 - p.daysAgo(today)).toDouble(),
              p.score.clamp(
                FormProgressChart._minScore,
                FormProgressChart._maxScore,
              ),
            ))
        .toList();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (kFormTrendDays - 1).toDouble(),
        minY: FormProgressChart._minScore,
        maxY: FormProgressChart._maxScore,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 30,
              getTitlesWidget: (value, _) => Text(
                '${value.round()}',
                style: tt.labelSmall?.copyWith(color: AppColors.textDisabled),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              // Every 10 days, not 7: weekly ticks collide near the right edge.
              interval: 10,
              reservedSize: 24,
              getTitlesWidget: (value, _) {
                final daysAgo = (kFormTrendDays - 1 - value).round();
                if (daysAgo < 0 || daysAgo > kFormTrendDays - 1) {
                  return const SizedBox.shrink();
                }
                final date = today.subtract(Duration(days: daysAgo));
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${FormProgressChart._months[date.month - 1]} ${date.day}',
                    style: tt.labelSmall
                        ?.copyWith(color: AppColors.textDisabled),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: AppRadius.sm,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            tooltipBgColor: AppColors.surfaceElevated,
            getTooltipItems: (touched) => touched.map((spot) {
              final daysAgo = (kFormTrendDays - 1 - spot.x).round();
              final date = today.subtract(Duration(days: daysAgo));
              return LineTooltipItem(
                '${spot.y.round()}%\n',
                tt.labelMedium!.copyWith(color: AppColors.accent),
                children: [
                  TextSpan(
                    text:
                        '${FormProgressChart._months[date.month - 1]} ${date.day}',
                    style: tt.labelSmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            barWidth: 2.5,
            color: AppColors.accent,
            isStrokeCapRound: true,
            // Rest days carry no spot at all; the curve bridges them because a
            // 30-day window is a trend, not a daily reading.
            dotData: FlDotData(
              show: spots.length <= FormProgressChart._maxDots,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.accent,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.accent.withValues(alpha: 0.25),
                  AppColors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.show_chart_rounded,
            size: 32,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Not enough data yet',
            style: tt.bodySmall?.copyWith(color: AppColors.textDisabled),
          ),
          Text(
            'Finish two sessions to see your trend',
            style: tt.labelMedium?.copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}
