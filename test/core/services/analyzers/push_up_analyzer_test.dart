import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ai_fitness_coach/core/services/analyzers/push_up_analyzer.dart';
import 'package:ai_fitness_coach/core/services/exercise_analyzer.dart';
import 'package:ai_fitness_coach/core/services/form_fault.dart';

import '../../../support/pose_fixtures.dart';

void main() {
  late PushUpAnalyzer analyzer;
  setUp(() => analyzer = PushUpAnalyzer());

  /// Shoulder, hip and knee laid out horizontally; [hipY] lifts or drops the
  /// hip out of the plank line.
  Pose plankPose({double hipY = 100}) => poseOf(withMirroredSide([
        lm(PoseLandmarkType.leftShoulder, 100, 100),
        lm(PoseLandmarkType.leftHip, 200, hipY),
        lm(PoseLandmarkType.leftKnee, 300, 100),
      ]));

  test('stays silent near the top of the push-up', () {
    final result = analyzer.analyze(plankPose(), 150);
    expect(result.score, FormScore.good);
    expect(result.feedback, isEmpty);
  });

  test('praises a deep rep held in a straight plank', () {
    final result = analyzer.analyze(plankPose(), 85);
    expect(result.score, FormScore.good);
    expect(result.feedback, FormResult.praise);
  });

  test('tells a sagging hip to come up', () {
    // Hip dropped 50px below the shoulder-knee line — a 90 degree bend, far
    // under the 160 degree plank minimum.
    final result = analyzer.analyze(plankPose(hipY: 150), 85);
    expect(result.topFault, FormFault.pushUpHipSag);
    expect(result.feedback, FormFault.pushUpHipSag.cue);
  });

  test('tells a piked hip to come down', () {
    // The same broken plank the other way: telling this user to lift their
    // hips would push them further out of position.
    final result = analyzer.analyze(plankPose(hipY: 50), 85);
    expect(result.topFault, FormFault.pushUpHipPike);
    expect(result.feedback, FormFault.pushUpHipPike.cue);
  });

  test('says nothing about the hips when the body is filmed end-on', () {
    // Shoulder, hip and knee stacked vertically: the camera is in front of
    // the user, not beside them, and cannot tell a sag from a pike. Guessing
    // would be worse than staying quiet.
    final pose = poseOf(withMirroredSide([
      lm(PoseLandmarkType.leftShoulder, 100, 100),
      lm(PoseLandmarkType.leftHip, 150, 200),
      lm(PoseLandmarkType.leftKnee, 100, 300),
    ]));
    final result = analyzer.analyze(pose, 85);
    expect(result.faults, isEmpty);
  });

  test('flags a rep that never reaches depth', () {
    final result = analyzer.analyze(plankPose(), 100);
    expect(result.score, FormScore.fair);
    expect(result.topFault, FormFault.pushUpShallow);
    expect(result.feedback, FormFault.pushUpShallow.cue);
  });

  test('coaches the broken plank first when depth is short too', () {
    final result = analyzer.analyze(plankPose(hipY: 150), 100);
    expect(result.score, FormScore.poor);
    expect(result.faults,
        containsAll([FormFault.pushUpHipSag, FormFault.pushUpShallow]));
    expect(result.feedback, FormFault.pushUpHipSag.cue);
  });

  test('ignores the plank check when the torso is not tracked', () {
    final pose = poseOf([
      lm(PoseLandmarkType.leftShoulder, 100, 100, likelihood: 0.3),
      lm(PoseLandmarkType.leftHip, 200, 150, likelihood: 0.3),
      lm(PoseLandmarkType.leftKnee, 300, 100, likelihood: 0.3),
    ]);
    final result = analyzer.analyze(pose, 85);
    expect(result.score, FormScore.good);
    expect(result.feedback, FormResult.praise);
  });
}
