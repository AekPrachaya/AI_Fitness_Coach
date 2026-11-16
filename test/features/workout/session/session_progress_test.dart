import 'package:ai_fitness_coach/features/workout/session/session_progress.dart';
import 'package:ai_fitness_coach/features/workout/session/workout_session_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSessionState _state({
  SessionStatus status = SessionStatus.tracking,
  int targetSets = 3,
  int targetReps = 10,
  int repCount = 0,
  int totalReps = 0,
}) => WorkoutSessionState(
  status: status,
  targetSets: targetSets,
  targetReps: targetReps,
  repCount: repCount,
  totalReps: totalReps,
);

void main() {
  test('starts at zero', () {
    expect(sessionProgress(_state()), 0);
  });

  test('counts reps of the set in progress', () {
    expect(sessionProgress(_state(repCount: 5)), closeTo(5 / 30, 1e-9));
  });

  test('a finished set is not counted twice while its reps are on show', () {
    // The notifier has already folded the set into totalReps but leaves
    // repCount at 10 until the next set begins.
    for (final status in [SessionStatus.setComplete, SessionStatus.resting]) {
      expect(
        sessionProgress(_state(status: status, repCount: 10, totalReps: 10)),
        closeTo(10 / 30, 1e-9),
        reason: '$status',
      );
    }
  });

  test('adds the current set on top of the sets already done', () {
    expect(
      sessionProgress(_state(repCount: 3, totalReps: 10)),
      closeTo(13 / 30, 1e-9),
    );
  });

  test('pausing mid-set keeps the reps of that set', () {
    expect(
      sessionProgress(
        _state(status: SessionStatus.paused, repCount: 4, totalReps: 10),
      ),
      closeTo(14 / 30, 1e-9),
    );
  });

  test('a finished workout is complete', () {
    expect(
      sessionProgress(
        _state(status: SessionStatus.finished, repCount: 10, totalReps: 30),
      ),
      1.0,
    );
  });

  test('never runs past full', () {
    expect(sessionProgress(_state(repCount: 15, totalReps: 25)), 1.0);
  });

  test('a zero target reads as zero rather than dividing by it', () {
    expect(sessionProgress(_state(targetReps: 0, repCount: 3)), 0);
    expect(sessionProgress(_state(targetSets: 0, repCount: 3)), 0);
  });
}
