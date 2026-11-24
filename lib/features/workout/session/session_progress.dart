import 'workout_session_notifier.dart';

/// How far through the whole workout the user is, 0–1, for the HUD's
/// progress bar.
///
/// Counts reps with [WorkoutSessionState.repsDone] — the same tally the
/// session is saved with — so the bar and the stored total can never disagree
/// about a finished set or one cut short.
double sessionProgress(WorkoutSessionState s) {
  final target = s.targetSets * s.targetReps;
  if (target <= 0) return 0;
  return (s.repsDone / target).clamp(0.0, 1.0);
}
