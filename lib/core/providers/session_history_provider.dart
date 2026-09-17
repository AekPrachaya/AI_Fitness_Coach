import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/workout/data/workout_repository.dart';
import '../../shared/models/session_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The single read path for workout history. Home and Progress both hang off
// these providers so the two screens can never disagree about how many
// sessions, minutes or streak days exist.
//
// Every provider here is synchronous and derived, so one
// `ref.invalidate(sessionHistoryProvider)` after a session is saved refreshes
// the whole app without a restart.
// ─────────────────────────────────────────────────────────────────────────────

/// Seeded demo history and recorded sessions merged, newest first.
final sessionHistoryProvider = Provider<List<SessionData>>(
  (ref) => ref.watch(workoutRepositoryProvider).getAllSessions(),
);

/// Sessions bucketed by local midnight — one pass, so the per-day lookups the
/// charts and heatmap need are map reads instead of repeated list scans.
final sessionsByDayProvider = Provider<Map<DateTime, List<SessionData>>>((ref) {
  final byDay = <DateTime, List<SessionData>>{};
  for (final session in ref.watch(sessionHistoryProvider)) {
    final day = dateOnly(session.completedAt);
    byDay.putIfAbsent(day, () => []).add(session);
  }
  return byDay;
});

/// Strips the time so two sessions on the same calendar day share a key.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

// ── DayActivity ──────────────────────────────────────────────────────────────

class DayActivity {
  final DateTime date;
  final int sessionCount;
  final int totalMinutes;
  final double avgFormScore;
  final bool isToday;

  const DayActivity({
    required this.date,
    required this.sessionCount,
    required this.totalMinutes,
    required this.avgFormScore,
    required this.isToday,
  });

  bool get isRestDay => sessionCount == 0;

  /// 0.0–1.0: 0 min = 0.0, 15 min = 0.33, 30 min = 0.67, 45+ min = 1.0
  double get intensity =>
      totalMinutes == 0 ? 0.0 : (totalMinutes / 45.0).clamp(0.0, 1.0);

  /// Bar height ratio for fl_chart (0.0–1.0). Active days have min height 0.15.
  double get barRatio =>
      isRestDay ? 0.0 : (0.15 + intensity * 0.85).clamp(0.0, 1.0);

  String get dayLabel {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }
}

/// Builds [days] consecutive [DayActivity] entries starting at [start].
List<DayActivity> buildDayActivities(
  Map<DateTime, List<SessionData>> byDay,
  DateTime start,
  int days,
) {
  final today = dateOnly(DateTime.now());
  final from = dateOnly(start);

  return List.generate(days, (i) {
    final date = DateTime(from.year, from.month, from.day + i);
    final sessions = byDay[date] ?? const <SessionData>[];

    final totalMinutes = sessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds ~/ 60,
    );
    final avgScore = sessions.isEmpty
        ? 0.0
        : sessions.fold<double>(0, (sum, s) => sum + s.avgFormScore) /
            sessions.length;

    return DayActivity(
      date: date,
      sessionCount: sessions.length,
      totalMinutes: totalMinutes,
      avgFormScore: avgScore,
      isToday: date == today,
    );
  });
}

/// Monday of the week containing [date].
DateTime mondayOf(DateTime date) {
  final day = dateOnly(date);
  return day.subtract(Duration(days: day.weekday - 1));
}

// ── Weekly aggregates (consumed by the Home dashboard) ───────────────────────

/// Mon–Sun of the current week.
final weeklyActivityProvider = Provider<List<DayActivity>>((ref) {
  final byDay = ref.watch(sessionsByDayProvider);
  return buildDayActivities(byDay, mondayOf(DateTime.now()), 7);
});

class WeekStats {
  final int totalWorkouts;
  final int totalMinutes;
  final int estimatedCalories;

  const WeekStats({
    required this.totalWorkouts,
    required this.totalMinutes,
    required this.estimatedCalories,
  });

  String get minutesDisplay {
    if (totalMinutes >= 60) {
      final h = totalMinutes ~/ 60;
      final m = totalMinutes % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${totalMinutes}m';
  }
}

/// Derives this week's summary from [weeklyActivityProvider] — no extra read.
final weekStatsProvider = Provider<WeekStats>((ref) {
  final days = ref.watch(weeklyActivityProvider);
  return WeekStats(
    totalWorkouts: days.where((d) => !d.isRestDay).length,
    totalMinutes: days.fold(0, (s, d) => s + d.totalMinutes),
    estimatedCalories: days.fold(0, (s, d) => s + d.totalMinutes * 4),
  );
});

/// Workout ids completed today, for the "Done Today ✓" state.
final completedTodayProvider = Provider<List<String>>((ref) {
  final today = dateOnly(DateTime.now());
  final sessions = ref.watch(sessionsByDayProvider)[today] ?? const [];
  return sessions.map((s) => s.workoutId).toList();
});

// ── Streaks ──────────────────────────────────────────────────────────────────

class StreakStats {
  final int current;
  final int best;
  final DateTime? lastActiveDay;

  const StreakStats({
    required this.current,
    required this.best,
    this.lastActiveDay,
  });

  static const empty = StreakStats(current: 0, best: 0);
}

/// A day counts once however many sessions it holds. The current streak may be
/// anchored on yesterday as well as today — the day is not over yet, so an
/// unworked today should not reset a run the user is still keeping.
final streakProvider = Provider<StreakStats>((ref) {
  final today = dateOnly(DateTime.now());
  final days = ref
      .watch(sessionsByDayProvider)
      .keys
      .where((d) => !d.isAfter(today))
      .toList()
    ..sort();

  if (days.isEmpty) return StreakStats.empty;

  var best = 1;
  var run = 1;
  for (var i = 1; i < days.length; i++) {
    final isConsecutive = days[i].difference(days[i - 1]).inDays == 1;
    run = isConsecutive ? run + 1 : 1;
    if (run > best) best = run;
  }

  final active = days.toSet();
  final yesterday = today.subtract(const Duration(days: 1));
  final anchor = active.contains(today)
      ? today
      : active.contains(yesterday)
          ? yesterday
          : null;

  var current = 0;
  if (anchor != null) {
    var cursor = anchor;
    while (active.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
  }

  return StreakStats(current: current, best: best, lastActiveDay: days.last);
});
