import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/utils/mock_data.dart';
import '../../shared/models/models.dart';

// ── TodaysPlan data class ─────────────────────────────────────────────────────

class TodaysPlan {
  final Workout workout;
  final int sets;
  final int reps;
  final bool isCompleted;
  final double progress; // 0.0 = not started, 1.0 = done

  const TodaysPlan({
    required this.workout,
    required this.sets,
    required this.reps,
    required this.isCompleted,
    required this.progress,
  });

  String get ctaLabel => isCompleted
      ? 'Done Today ✓'
      : progress > 0
          ? 'Resume'
          : 'Start Workout';

  bool get isActionable => !isCompleted;
}

// ── Helper: today's completed workout IDs from Hive ───────────────────────────

List<String> _getSessionsToday() {
  try {
    final box = Hive.box(MockData.boxSessionHistory);
    final sessions = box.get('sessions', defaultValue: []) as List;
    final now = DateTime.now();

    return sessions
        .where((s) {
          final date =
              DateTime.parse((s as Map)['completed_at'] as String);
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        })
        .map((s) => (s as Map)['workout_id'] as String)
        .toList();
  } catch (_) {
    return [];
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Picks today's workout by rotating through the list based on day-of-week.
/// Checks Hive session history to determine completion state.
final todaysPlanProvider = FutureProvider<TodaysPlan?>((ref) async {
  final workouts = await MockData.loadWorkouts();
  if (workouts.isEmpty) return null;

  final dayIndex = DateTime.now().weekday % workouts.length;
  final workout = workouts[dayIndex];
  final sessionsDone = _getSessionsToday();
  final isCompleted = sessionsDone.contains(workout.id);

  return TodaysPlan(
    workout: workout,
    sets: workout.defaultSets,
    reps: workout.defaultReps,
    isCompleted: isCompleted,
    progress: isCompleted ? 1.0 : 0.0,
  );
});

// ── DayActivity data class ────────────────────────────────────────────────────

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
  double get intensity => totalMinutes == 0
      ? 0.0
      : (totalMinutes / 45.0).clamp(0.0, 1.0);

  /// Bar height ratio for fl_chart (0.0–1.0). Active days have min height 0.15.
  double get barRatio => isRestDay
      ? 0.0
      : (0.15 + intensity * 0.85).clamp(0.0, 1.0);

  String get dayLabel {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }
}

// ── weeklyActivityProvider ────────────────────────────────────────────────────

/// Returns 7 [DayActivity] items for Mon–Sun of the current week.
/// Reads synchronously from the already-open Hive session_history box.
final weeklyActivityProvider = Provider<List<DayActivity>>((ref) {
  try {
    final box = Hive.box(MockData.boxSessionHistory);
    final sessions = box.get('sessions', defaultValue: []) as List;
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return List.generate(7, (i) {
      final date = DateTime(monday.year, monday.month, monday.day + i);

      final daySessions = sessions.where((s) {
        final d = DateTime.parse((s as Map)['completed_at'] as String);
        return d.year == date.year &&
            d.month == date.month &&
            d.day == date.day;
      }).toList();

      final totalMinutes = daySessions.fold<int>(
        0,
        (sum, s) =>
            sum + (((s as Map)['duration_seconds'] as int? ?? 0) ~/ 60),
      );

      final avgScore = daySessions.isEmpty
          ? 0.0
          : daySessions.fold<double>(
                0,
                (sum, s) =>
                    sum +
                    ((s as Map)['avg_form_score'] as num).toDouble(),
              ) /
              daySessions.length;

      return DayActivity(
        date: date,
        sessionCount: daySessions.length,
        totalMinutes: totalMinutes,
        avgFormScore: avgScore,
        isToday: date.year == today.year &&
            date.month == today.month &&
            date.day == today.day,
      );
    });
  } catch (_) {
    // Fallback: 7 empty days centred on today
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(
      7,
      (i) => DayActivity(
        date: monday.add(Duration(days: i)),
        sessionCount: 0,
        totalMinutes: 0,
        avgFormScore: 0.0,
        isToday: i == today.weekday - 1,
      ),
    );
  }
});
