import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/session_history_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/utils/mock_data.dart';
import '../../shared/models/models.dart';

// Activity aggregates moved to core so Progress reads the same history as Home.
// Re-exported here because the home widgets already import them from this file.
export '../../core/providers/session_history_provider.dart'
    show DayActivity, WeekStats, weeklyActivityProvider, weekStatsProvider;

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

// ── Provider ──────────────────────────────────────────────────────────────────

/// Picks today's workout by rotating through the list based on day-of-week.
/// Checks session history to determine completion state.
final todaysPlanProvider = FutureProvider<TodaysPlan?>((ref) async {
  final workouts = await MockData.loadWorkouts();
  if (workouts.isEmpty) return null;

  final dayIndex = DateTime.now().weekday % workouts.length;
  final workout = workouts[dayIndex];
  final isCompleted = ref.watch(completedTodayProvider).contains(workout.id);

  return TodaysPlan(
    workout: workout,
    sets: workout.defaultSets,
    reps: workout.defaultReps,
    isCompleted: isCompleted,
    progress: isCompleted ? 1.0 : 0.0,
  );
});

// ── recommendedWorkoutsProvider ───────────────────────────────────────────────

/// Returns all workouts sorted by relevance to the user's fitness level.
final recommendedWorkoutsProvider = FutureProvider<List<Workout>>((ref) async {
  final allWorkouts = await MockData.loadWorkouts();
  final profile = ref.watch(userProfileProvider);

  final sorted = [...allWorkouts]..sort((a, b) {
      final aMatch = a.difficulty == profile.fitnessLevel ? 0 : 1;
      final bMatch = b.difficulty == profile.fitnessLevel ? 0 : 1;
      return aMatch.compareTo(bMatch);
    });

  return sorted;
});

