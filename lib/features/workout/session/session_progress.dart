import 'workout_session_notifier.dart';

/// How far through the whole workout the user is, 0–1, for the HUD's
/// progress bar.
///
/// Once a set is done the notifier folds its reps into `totalReps` but keeps
/// `repCount` on show until the next set starts, so from `setComplete` until
/// then the set's reps are already counted and must not be added twice.
double sessionProgress(WorkoutSessionState s) {
  final target = s.targetSets * s.targetReps;
  if (target <= 0) return 0;

  final setFolded = switch (s.status) {
    SessionStatus.setComplete ||
    SessionStatus.resting ||
    SessionStatus.finished => true,
    _ => false,
  };
  final done = s.totalReps + (setFolded ? 0 : s.repCount);
  return (done / target).clamp(0.0, 1.0);
}
