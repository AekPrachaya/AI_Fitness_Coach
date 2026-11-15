import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ai_fitness_coach/core/services/analyzers/deadlift_analyzer.dart';
import 'package:ai_fitness_coach/core/services/exercise_analyzer.dart';
import 'package:ai_fitness_coach/core/services/form_fault.dart';

import '../../../support/pose_fixtures.dart';

void main() {
  late DeadliftAnalyzer analyzer;
  setUp(() => analyzer = DeadliftAnalyzer());

  Pose hingePose({double shoulderX = 100}) => poseOf(withMirroredSide([
        lm(PoseLandmarkType.leftShoulder, shoulderX, 100),
        lm(PoseLandmarkType.leftHip, 100, 200),
      ]));

  test('stays silent while the user is still upright', () {
    final result = analyzer.analyze(hingePose(), 170);
    expect(result.score, FormScore.good);
    expect(result.feedback, isEmpty);
  });

  test('praises a hinge that keeps the torso neutral', () {
    final result = analyzer.analyze(hingePose(), 100);
    expect(result.score, FormScore.good);
    expect(result.feedback, FormResult.praise);
  });

  test('flags a torso folded nearly flat', () {
    // Shoulder 400px ahead of the hip over a 100px torso — 76 degrees of
    // tilt, past the 75 degree limit.
    final result = analyzer.analyze(hingePose(shoulderX: 500), 100);
    expect(result.score, FormScore.poor, reason: 'a loaded spine is risky');
    expect(result.topFault, FormFault.deadliftTorsoDrop);
    expect(result.feedback, FormFault.deadliftTorsoDrop.cue);
  });

  test('leaves an ordinary hinge alone', () {
    // 100px over 100px is 45 degrees — a normal deadlift passes through this
    // on every rep, and warning about it would make the alert worthless.
    final result = analyzer.analyze(hingePose(shoulderX: 200), 100);
    expect(result.score, FormScore.good);
    expect(result.faults, isEmpty);
  });

  test('skips the back check when the torso is not tracked', () {
    final pose = poseOf([
      lm(PoseLandmarkType.leftShoulder, 200, 100, likelihood: 0.4),
      lm(PoseLandmarkType.leftHip, 100, 200, likelihood: 0.4),
    ]);
    final result = analyzer.analyze(pose, 100);
    expect(result.score, FormScore.good);
    expect(result.feedback, FormResult.praise);
  });
}
