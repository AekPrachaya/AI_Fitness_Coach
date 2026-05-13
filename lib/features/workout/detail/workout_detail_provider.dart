import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/mock_data.dart';
import '../../../shared/models/models.dart';

// ── Workout lookup ────────────────────────────────────────────────────────────

/// Looks up a single workout by ID from mock data.
/// Returns null if the ID is not found.
final workoutDetailProvider =
    FutureProvider.family<Workout?, String>((ref, workoutId) async {
  final workouts = await MockData.loadWorkouts();
  try {
    return workouts.firstWhere((w) => w.id == workoutId);
  } catch (_) {
    return null;
  }
});

// ── Plan state ────────────────────────────────────────────────────────────────

/// Immutable value object representing the user's configured workout plan.
class WorkoutPlan {
  final int sets;    // 1–10
  final int reps;    // 1–50
  final String mode; // 'beginner' | 'pro'

  const WorkoutPlan({
    this.sets = 3,
    this.reps = 12,
    this.mode = 'beginner',
  });

  WorkoutPlan copyWith({int? sets, int? reps, String? mode}) => WorkoutPlan(
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        mode: mode ?? this.mode,
      );
}

// ── Plan notifier ─────────────────────────────────────────────────────────────

class WorkoutPlanNotifier extends StateNotifier<WorkoutPlan> {
  WorkoutPlanNotifier() : super(const WorkoutPlan());

  void incrementSets() {
    if (state.sets < 10) state = state.copyWith(sets: state.sets + 1);
  }

  void decrementSets() {
    if (state.sets > 1) state = state.copyWith(sets: state.sets - 1);
  }

  void incrementReps() {
    if (state.reps < 50) state = state.copyWith(reps: state.reps + 1);
  }

  void decrementReps() {
    if (state.reps > 1) state = state.copyWith(reps: state.reps - 1);
  }

  void setMode(String mode) {
    state = state.copyWith(mode: mode);
  }
}

/// Family provider so each workout has its own isolated plan state.
final workoutPlanProvider = StateNotifierProvider.family<WorkoutPlanNotifier,
    WorkoutPlan, String>(
  (ref, workoutId) => WorkoutPlanNotifier(),
);
