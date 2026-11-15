import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/core/services/exercise_analyzer.dart';
import 'package:ai_fitness_coach/core/services/form_coach.dart';
import 'package:ai_fitness_coach/core/services/form_fault.dart';
import 'package:ai_fitness_coach/features/workout/session/workout_session_notifier.dart';

void main() {
  const tracked = FormResult(score: FormScore.fair, feedback: 'ลงให้ลึกกว่านี้');
  const coaching = FormCue(
    message: 'ย่อลงอีก ให้ต้นขาขนานพื้น',
    score: FormScore.fair,
    fault: FormFault.squatShallow,
  );

  test('starts idle with nothing measured', () {
    const state = WorkoutSessionState();
    expect(state.status, SessionStatus.idle);
    expect(state.currentSet, 1);
    expect(state.repCount, 0);
    expect(state.jointAngle, isNull);
    expect(state.formResult, isNull);
    expect(state.cue, isNull);
    expect(state.poses, isEmpty);
    expect(state.absoluteImageSize, Size.zero);
  });

  test('copyWith leaves untouched fields alone', () {
    final state = const WorkoutSessionState()
        .copyWith(jointAngle: 92.5, formResult: tracked, repCount: 4);

    final next = state.copyWith(status: SessionStatus.repComplete);
    expect(next.status, SessionStatus.repComplete);
    expect(next.jointAngle, 92.5);
    expect(next.formResult, same(tracked));
    expect(next.repCount, 4);
  });

  test('the clear flags reset the frame-scoped fields to null', () {
    // The body leaving the frame must wipe the angle and the form banner —
    // `x ?? this.x` alone would leave the previous frame's values on screen.
    final state = const WorkoutSessionState()
        .copyWith(jointAngle: 92.5, formResult: tracked, repCount: 4);

    final cleared = state.copyWith(
      poses: const [],
      clearJointAngle: true,
      clearFormResult: true,
    );
    expect(cleared.jointAngle, isNull);
    expect(cleared.formResult, isNull);
    expect(cleared.repCount, 4, reason: 'the rep tally survives a lost body');
  });

  test('each clear flag acts on its own field only', () {
    final state = const WorkoutSessionState()
        .copyWith(jointAngle: 92.5, formResult: tracked, cue: coaching);

    expect(state.copyWith(clearJointAngle: true).formResult, same(tracked));
    expect(state.copyWith(clearFormResult: true).jointAngle, 92.5);
    expect(state.copyWith(clearCue: true).formResult, same(tracked));
    expect(state.copyWith(clearFormResult: true).cue, coaching);
  });

  test('the coaching line survives a rebuild that touches nothing else', () {
    // The cue outlives the frame it was raised on — that is the whole point
    // of holding it — so an unrelated copyWith must not drop it.
    final state = const WorkoutSessionState().copyWith(cue: coaching);
    expect(state.copyWith(repCount: 3).cue, coaching);
  });

  test('clearCue wipes the coaching line', () {
    final state = const WorkoutSessionState().copyWith(cue: coaching);
    expect(state.copyWith(clearCue: true).cue, isNull);
    expect(state.copyWith(cue: coaching, clearCue: true).cue, isNull,
        reason: 'the clear flag wins over a value in the same call');
  });

  test('a clear flag wins over a value passed in the same call', () {
    final state = const WorkoutSessionState().copyWith(jointAngle: 92.5);
    expect(state.copyWith(jointAngle: 80, clearJointAngle: true).jointAngle,
        isNull);
  });

  test('errorMessage clears unless it is passed again', () {
    final failed =
        const WorkoutSessionState().copyWith(errorMessage: 'หาตัวไม่เจอ');
    expect(failed.errorMessage, 'หาตัวไม่เจอ');
    expect(failed.copyWith(status: SessionStatus.tracking).errorMessage, isNull);
  });
}
