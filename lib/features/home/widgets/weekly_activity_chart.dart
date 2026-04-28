import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../home_provider.dart';

// ── WeeklyActivityChart ───────────────────────────────────────────────────────

class WeeklyActivityChart extends ConsumerWidget {
  const WeeklyActivityChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(weeklyActivityProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartHeader(days: days),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 120,
            child: days.every((d) => d.isRestDay)
                ? _EmptyState()
                : _ActivityBars(days: days),
          ),
        ],
      ),
    )
        .animate(delay: 150.ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.05, end: 0.0, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ── _ChartHeader ──────────────────────────────────────────────────────────────

class _ChartHeader extends StatelessWidget {
  final List<DayActivity> days;

  const _ChartHeader({required this.days});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final activeDays = days.where((d) => !d.isRestDay).length;
    final totalMinutes = days.fold(0, (sum, d) => sum + d.totalMinutes);
    final totalTimeStr = totalMinutes == 0
        ? '0m'
        : totalMinutes >= 60
            ? '${totalMinutes ~/ 60}h ${totalMinutes % 60}m'
            : '${totalMinutes}m';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: title + active count
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Week', style: tt.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$activeDays of 7 days active',
              style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),

        const Spacer(),

        // Right: total time (Bebas Neue display font) + label
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              totalTimeStr,
              style: tt.headlineMedium?.copyWith(
                color: AppColors.accent,
                fontFamily: 'BebasNeue',
                height: 1.0,
              ),
            ),
            Text(
              'trained',
              style: tt.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

// ── _EmptyState ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 32, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No workouts this week yet',
            style: tt.bodySmall?.copyWith(color: AppColors.textDisabled),
          ),
          Text(
            'Start your first session!',
            style: tt.labelMedium?.copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

// ── _ActivityBars ─────────────────────────────────────────────────────────────

class _ActivityBars extends StatelessWidget {
  final List<DayActivity> days;

  const _ActivityBars({required this.days});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1.0,
        minY: 0.0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: AppRadius.sm,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            tooltipBgColor: AppColors.surfaceElevated,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = days[groupIndex];
              if (day.isRestDay) return null;
              return BarTooltipItem(
                '${day.totalMinutes}m\n',
                tt.labelMedium!.copyWith(color: AppColors.accent),
                children: [
                  TextSpan(
                    text: 'Form ${day.avgFormScore.toInt()}%',
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= days.length) {
                  return const SizedBox.shrink();
                }
                final day = days[index];

                final label = Text(
                  day.dayLabel,
                  style: tt.labelMedium?.copyWith(
                    color: day.isToday
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontWeight:
                        day.isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
                );

                if (day.isToday) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: AppSpacing.xs),
                      label,
                      const SizedBox(height: 3),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: label,
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: days.asMap().entries.map((entry) {
          return _buildBarGroup(entry.key, entry.value);
        }).toList(),
      ),
      swapAnimationDuration: const Duration(milliseconds: 400),
      swapAnimationCurve: Curves.easeOut,
    );
  }

  BarChartGroupData _buildBarGroup(int index, DayActivity day) {
    if (!day.isRestDay) {
      // Active day: gradient bar, height driven by barRatio
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: day.barRatio,
            width: 20,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sm),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.accent,
                AppColors.accent.withValues(
                  alpha: 0.4 + day.intensity * 0.4,
                ),
              ],
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 1.0,
              color: AppColors.surfaceElevated,
            ),
          ),
        ],
      );
    }

    // Rest day: tiny stub so the track is always visible
    final stubColor = day.isToday
        ? AppColors.accent.withValues(alpha: 0.15)
        : AppColors.surfaceElevated;

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: 0.03,
          width: 20,
          color: stubColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sm),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 1.0,
            color: AppColors.surfaceElevated,
          ),
        ),
      ],
    );
  }
}
