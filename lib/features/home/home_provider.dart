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
