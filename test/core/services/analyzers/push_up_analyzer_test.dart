import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ai_fitness_coach/core/services/analyzers/push_up_analyzer.dart';
import 'package:ai_fitness_coach/core/services/exercise_analyzer.dart';

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
    expect(result.feedback, 'ท่าดีมาก!');
  });

  test('flags a sagging hip', () {
    // Hip dropped 50px below the shoulder-knee line — a 90 degree bend, far
    // under the 160 degree plank minimum.
    final result = analyzer.analyze(plankPose(hipY: 150), 85);
    expect(result.score, FormScore.fair);
    expect(result.feedback, contains('สะโพกหย่อน'));
  });

  test('flags a rep that never reaches depth', () {
    final result = analyzer.analyze(plankPose(), 100);
    expect(result.score, FormScore.fair);
    expect(result.feedback, 'ลงให้ถึงกว่านี้');
  });

  test('scores poor when the plank breaks and depth is short', () {
    final result = analyzer.analyze(plankPose(hipY: 150), 100);
    expect(result.score, FormScore.poor);
    expect(result.feedback, contains('สะโพกหย่อน'));
    expect(result.feedback, contains('ลงให้ถึงกว่านี้'));
  });

  test('ignores the plank check when the torso is not tracked', () {
    final pose = poseOf([
      lm(PoseLandmarkType.leftShoulder, 100, 100, likelihood: 0.3),
      lm(PoseLandmarkType.leftHip, 200, 150, likelihood: 0.3),
      lm(PoseLandmarkType.leftKnee, 300, 100, likelihood: 0.3),
    ]);
    final result = analyzer.analyze(pose, 85);
    expect(result.score, FormScore.good);
    expect(result.feedback, 'ท่าดีมาก!');
  });
}
