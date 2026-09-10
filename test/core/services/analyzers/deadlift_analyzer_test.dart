import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ai_fitness_coach/core/services/analyzers/deadlift_analyzer.dart';
import 'package:ai_fitness_coach/core/services/exercise_analyzer.dart';

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
    expect(result.feedback, 'ท่าดีมาก!');
  });

  test('flags a rounded back', () {
    // Shoulder 100px ahead of the hip over a 100px torso — 45 degrees of tilt,
    // past the 35 degree limit.
    final result = analyzer.analyze(hingePose(shoulderX: 200), 100);
    expect(result.score, FormScore.fair);
    expect(result.feedback, contains('หลังค่อม'));
  });

  test('tolerates a tilt just inside the limit', () {
    // 30px over 100px is roughly 17 degrees.
    final result = analyzer.analyze(hingePose(shoulderX: 130), 100);
    expect(result.score, FormScore.good);
  });

  test('skips the back check when the torso is not tracked', () {
    final pose = poseOf([
      lm(PoseLandmarkType.leftShoulder, 200, 100, likelihood: 0.4),
      lm(PoseLandmarkType.leftHip, 100, 200, likelihood: 0.4),
    ]);
    final result = analyzer.analyze(pose, 100);
    expect(result.score, FormScore.good);
    expect(result.feedback, 'ท่าดีมาก!');
  });
}
