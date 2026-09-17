import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/session_history_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../progress_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ActivityHeatmap — GitHub-style calendar, one column per week.
//
// Responsive the way GitHub's is: cells hold a steady size and a wider card
// shows more weeks of history, rather than stretching twelve columns into
// oversized tiles.
//
// Built from Containers rather than a CustomPainter because every cell is a tap
// target; a painter would mean hand-rolling hit testing.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({super.key});

  /// Cell size the week count is chosen around; the final size is then nudged
  /// within [_minCell]..[_maxCell] so the columns fill the width exactly.
  static const double _targetCell = 18.0;
  static const double _minCell = 12.0;
  static const double _maxCell = 22.0;
  static const double _gap = AppSpacing.xs;

  /// Width reserved for the Mon/Wed/Fri row labels.
  static const double _labelGutter = 20.0;

  /// A new month label is dropped when it would sit this close to the previous
  /// one — three-letter labels need about three columns to breathe.
  static const int _minLabelSpacing = 3;

  static int weeksFor(double gridWidth) {
    final fit = ((gridWidth + _gap) / (_targetCell + _gap)).floor();
    return fit.clamp(kHeatmapMinWeeks, kHeatmapMaxWeeks);
  }

  static double cellFor(double gridWidth, int weeks) =>
      ((gridWidth - _gap * (weeks - 1)) / weeks).clamp(_minCell, _maxCell);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridWidth = constraints.maxWidth - _labelGutter;
          final weeks = weeksFor(gridWidth);
          final cell = cellFor(gridWidth, weeks);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Activity', style: tt.titleLarge),
                  const Spacer(),
                  Text(
                    'Last $weeks weeks',
                    style:
                        tt.labelMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // A Consumer rather than watching in the LayoutBuilder callback:
              // that callback runs during layout, where ref.watch is unsafe.
              Consumer(
                builder: (context, ref, _) {
                  final days = ref.watch(heatmapDaysProvider(weeks));
                  final selected = ref.watch(selectedHeatmapDayProvider);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MonthLabels(days: days, weeks: weeks, cell: cell),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DayLabels(cell: cell),
                          ...List.generate(weeks, (week) {
                            return Padding(
                              padding: EdgeInsets.only(
                                right: week == weeks - 1 ? 0 : _gap,
                              ),
                              child: Column(
                                children: List.generate(7, (weekday) {
                                  final day = days[week * 7 + weekday];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: weekday == 6 ? 0 : _gap,
                                    ),
                                    child: _HeatCell(
                                      day: day,
                                      size: cell,
                                      isSelected: selected == day.date,
                                      onTap: () => ref
                                          .read(selectedHeatmapDayProvider
                                              .notifier)
                                          .state = selected == day.date
                                          ? null
                                          : day.date,
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              const _SelectedDayLine(),
              const SizedBox(height: AppSpacing.sm),
              const _Legend(),
            ],
          );
        },
      ),
    );
  }
}

// ── Cell ─────────────────────────────────────────────────────────────────────

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.day,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  final DayActivity day;
  final double size;
  final bool isSelected;
  final VoidCallback onTap;

  /// Slight rounding only — AppRadius.sm would turn a ~19px cell into a dot.
  static const double _radius = 3.0;

  /// Quantised so neighbouring levels stay tellable apart — a continuous alpha
  /// ramp reads as one flat colour at this cell size.
  static Color fill(DayActivity day, {required bool isFuture}) {
    if (isFuture) return AppColors.surfaceElevated.withValues(alpha: 0.4);
    if (day.isRestDay) return AppColors.surfaceElevated;

    final intensity = day.intensity;
    final alpha = intensity <= 0.33
        ? 0.30
        : intensity <= 0.66
            ? 0.55
            : intensity <= 0.99
                ? 0.78
                : 1.0;
    return AppColors.accent.withValues(alpha: alpha);
  }

  @override
  Widget build(BuildContext context) {
    final isFuture = day.date.isAfter(dateOnly(DateTime.now()));

    final border = isSelected
        ? Border.all(color: AppColors.textPrimary, width: 1.5)
        : day.isToday
            ? Border.all(color: AppColors.accent.withValues(alpha: 0.5))
            : null;

    return GestureDetector(
      onTap: isFuture ? null : onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill(day, isFuture: isFuture),
          borderRadius: BorderRadius.circular(_radius),
          border: border,
        ),
      ),
    );
  }
}

// ── Labels ───────────────────────────────────────────────────────────────────

class _DayLabels extends StatelessWidget {
  const _DayLabels({required this.cell});

  final double cell;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    // Only alternate rows are labelled; seven stacked labels do not fit.
    const labels = ['M', '', 'W', '', 'F', '', ''];

    return SizedBox(
      width: ActivityHeatmap._labelGutter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(7, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i == 6 ? 0 : ActivityHeatmap._gap),
            child: SizedBox(
              height: cell,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  labels[i],
                  style: tt.labelSmall?.copyWith(color: AppColors.textDisabled),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MonthLabels extends StatelessWidget {
  const _MonthLabels({
    required this.days,
    required this.weeks,
    required this.cell,
  });

  final List<DayActivity> days;
  final int weeks;
  final double cell;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// One label per month change, dropping any that would crowd the next one —
  /// the later label wins, since it names a month the grid shows more of.
  List<String> _labels() {
    final labels = List.filled(weeks, '');
    int? lastIndex;
    var lastMonth = -1;

    for (var week = 0; week < weeks; week++) {
      final month = days[week * 7].date.month;
      if (month == lastMonth) continue;
      lastMonth = month;

      if (lastIndex != null &&
          week - lastIndex < ActivityHeatmap._minLabelSpacing) {
        labels[lastIndex] = '';
      }
      labels[week] = _months[month - 1];
      lastIndex = week;
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final labels = _labels();

    return Padding(
      padding: const EdgeInsets.only(left: ActivityHeatmap._labelGutter),
      child: Row(
        children: List.generate(weeks, (week) {
          return Padding(
            padding: EdgeInsets.only(
              right: week == weeks - 1 ? 0 : ActivityHeatmap._gap,
            ),
            child: SizedBox(
              width: cell,
              child: Text(
                labels[week],
                style: tt.labelSmall?.copyWith(color: AppColors.textDisabled),
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Detail line ──────────────────────────────────────────────────────────────

/// Replaces a hover tooltip, which never fires on the phone this app is
/// actually tested on. Reads the day straight from history rather than from
/// the visible grid, so a selection survives the grid narrowing past it.
class _SelectedDayLine extends ConsumerWidget {
  const _SelectedDayLine();

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final selected = ref.watch(selectedHeatmapDayProvider);

    var text = 'Tap a day for details';
    if (selected != null) {
      final day = buildDayActivities(
        ref.watch(sessionsByDayProvider),
        selected,
        1,
      ).single;

      final date =
          '${_weekdays[day.date.weekday - 1]}, ${_months[day.date.month - 1]} ${day.date.day}';
      if (day.isRestDay) {
        text = '$date · Rest day';
      } else {
        final sessions =
            '${day.sessionCount} ${day.sessionCount == 1 ? 'session' : 'sessions'}';
        text = '$date · $sessions · ${day.totalMinutes} min · '
            'Form ${day.avgFormScore.round()}%';
      }
    }

    return SizedBox(
      height: 18,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          text,
          key: ValueKey<String>(text),
          style: tt.labelMedium?.copyWith(
            color: selected == null
                ? AppColors.textDisabled
                : AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ── Legend ───────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  static const double _swatch = 10.0;
  static const double _swatchGap = 2.0;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final style = tt.labelSmall?.copyWith(color: AppColors.textDisabled);

    Widget swatch(Color color) => Container(
          width: _swatch,
          height: _swatch,
          margin: const EdgeInsets.symmetric(horizontal: _swatchGap),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(_HeatCell._radius),
          ),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: style),
        swatch(AppColors.surfaceElevated),
        swatch(AppColors.accent.withValues(alpha: 0.30)),
        swatch(AppColors.accent.withValues(alpha: 0.55)),
        swatch(AppColors.accent.withValues(alpha: 0.78)),
        swatch(AppColors.accent),
        Text('More', style: style),
      ],
    );
  }
}
