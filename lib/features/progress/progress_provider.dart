import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/session_history_provider.dart';
import '../../shared/models/session_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Aggregates for the Progress Overview tab. Everything here derives from
// sessionsByDayProvider / sessionHistoryProvider, so the whole screen costs one
// Hive read and refreshes the moment a session is saved.
// ─────────────────────────────────────────────────────────────────────────────

/// The heatmap shows as many weeks as the card is wide, within these bounds:
/// a phone gets the minimum, a desktop window up to a year.
const int kHeatmapMinWeeks = 12;
const int kHeatmapMaxWeeks = 52;

/// Days covered by the form-score trend.
const int kFormTrendDays = 30;

/// Per-exercise score history kept for the sparklines.
const int kSparklinePoints = 12;

/// `weeks × 7` days ending on the Sunday of the current week, oldest first — a
/// whole number of Mon–Sun columns so the grid stays rectangular. Keyed by week
/// count because the widget picks that from its width.
final heatmapDaysProvider =
    Provider.family<List<DayActivity>, int>((ref, weeks) {
  final byDay = ref.watch(sessionsByDayProvider);
  final start = mondayOf(DateTime.now()).subtract(Duration(days: 7 * (weeks - 1)));
  return buildDayActivities(byDay, start, weeks * 7);
});

/// The heatmap cell the user tapped, or null for "no selection".
final selectedHeatmapDayProvider = StateProvider<DateTime?>((ref) => null);

// ── Form score trend ─────────────────────────────────────────────────────────

class FormScorePoint {
  final DateTime date;
  final double score;
  final int sessionCount;

  const FormScorePoint({
    required this.date,
    required this.score,
    required this.sessionCount,
  });

  /// Days back from today — the x axis runs 0 (today) to [kFormTrendDays] - 1.
  int daysAgo(DateTime today) => today.difference(date).inDays;
}

/// One point per *active* day in the last 30 days, oldest first. Rest days are
/// omitted rather than plotted as zero: the chart shows how form is trending,
/// and a drop to zero on every rest day would bury that.
final formScoreSeriesProvider = Provider<List<FormScorePoint>>((ref) {
  final byDay = ref.watch(sessionsByDayProvider);
  final today = dateOnly(DateTime.now());
  final oldest = today.subtract(const Duration(days: kFormTrendDays - 1));

  final points = <FormScorePoint>[];
  byDay.forEach((day, sessions) {
    if (day.isBefore(oldest) || day.isAfter(today)) return;
    if (sessions.isEmpty) return;

    final avg = sessions.fold<double>(0, (sum, s) => sum + s.avgFormScore) /
        sessions.length;
    points.add(FormScorePoint(
      date: day,
      score: avg.clamp(0.0, 100.0),
      sessionCount: sessions.length,
    ));
  });

  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
});

// ── Per-exercise stats ───────────────────────────────────────────────────────

class ExerciseStats {
  final String exerciseId;
  final String exerciseName;
  final int sessionCount;
  final int totalReps;
  final double avgRepsPerSession;
  final double avgFormScore;
  final String mostCommonError;

  /// Score per session, oldest first, capped at [kSparklinePoints].
  final List<double> formTrend;

  const ExerciseStats({
    required this.exerciseId,
    required this.exerciseName,
    required this.sessionCount,
    required this.totalReps,
    required this.avgRepsPerSession,
    required this.avgFormScore,
    required this.mostCommonError,
    required this.formTrend,
  });

  bool get hasTrend => formTrend.length >= 2;
}

/// Flattens every session's `exercises[]` into per-exercise totals, busiest
/// exercise first.
final exerciseStatsProvider = Provider<List<ExerciseStats>>((ref) {
  final sessions = ref.watch(sessionHistoryProvider);

  // Oldest first so the sparkline reads left-to-right in time.
  final ordered = [...sessions]
    ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

  final names = <String, String>{};
  final reps = <String, int>{};
  final scores = <String, List<double>>{};
  final errors = <String, Map<String, int>>{};

  for (final session in ordered) {
    for (final exercise in session.exercises) {
      final id = exercise.exerciseId.isEmpty
          ? session.workoutId
          : exercise.exerciseId;
      if (id.isEmpty) continue;

      final name = exercise.exerciseName.isNotEmpty
          ? exercise.exerciseName
          : session.workoutName;
      names[id] = name.isNotEmpty ? name : id;
      reps[id] = (reps[id] ?? 0) + exercise.totalReps;
      (scores[id] ??= []).add(exercise.avgFormScore);

      final error = exercise.mostCommonError;
      if (error.isNotEmpty) {
        final tally = errors[id] ??= {};
        tally[error] = (tally[error] ?? 0) + 1;
      }
    }
  }

  final stats = names.keys.map((id) {
    final history = scores[id] ?? const <double>[];
    final count = history.length;
    final totalReps = reps[id] ?? 0;

    final tally = errors[id];
    final topError = tally == null || tally.isEmpty
        ? 'No recurring issues'
        : (tally.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    return ExerciseStats(
      exerciseId: id,
      exerciseName: names[id]!,
      sessionCount: count,
      totalReps: totalReps,
      avgRepsPerSession: count == 0 ? 0 : totalReps / count,
      avgFormScore: count == 0
          ? 0
          : history.fold<double>(0, (sum, s) => sum + s) / count,
      mostCommonError: topError,
      formTrend: history.length > kSparklinePoints
          ? history.sublist(history.length - kSparklinePoints)
          : history,
    );
  }).toList()
    ..sort((a, b) => b.sessionCount.compareTo(a.sessionCount));

  return stats;
});

/// Sessions recorded on [day] — backs the heatmap's detail line.
List<SessionData> sessionsOn(
  Map<DateTime, List<SessionData>> byDay,
  DateTime day,
) =>
    byDay[dateOnly(day)] ?? const [];
