import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ai_fitness_coach/core/services/analyzers/squat_analyzer.dart';
import 'package:ai_fitness_coach/core/services/exercise_analyzer.dart';

import '../../../support/pose_fixtures.dart';

void main() {
  late SquatAnalyzer analyzer;
  setUp(() => analyzer = SquatAnalyzer());

  // Vertical shin (knee directly above ankle) and vertical torso (shoulder
  // directly above hip) — the reference "clean squat" geometry.
  Pose stackedPose({
    double kneeX = 100,
    double ankleX = 100,
    double shoulderX = 100,
    double hipX = 100,
  }) =>
      poseOf(withMirroredSide([
        lm(PoseLandmarkType.leftShoulder, shoulderX, 50),
        lm(PoseLandmarkType.leftHip, hipX, 150),
        lm(PoseLandmarkType.leftKnee, kneeX, 200),
        lm(PoseLandmarkType.leftAnkle, ankleX, 300),
      ]));

  test('stays silent while the user is still standing', () {
    final result = analyzer.analyze(stackedPose(), 150);
    expect(result.score, FormScore.good);
    expect(result.feedback, isEmpty);
  });

  test('praises a deep squat with a vertical shin and torso', () {
    final result = analyzer.analyze(stackedPose(), 85);
    expect(result.score, FormScore.good);
    expect(result.feedback, 'ท่าดีมาก!');
  });

  test('flags insufficient depth on its own as fair', () {
    final result = analyzer.analyze(stackedPose(), 110);
    expect(result.score, FormScore.fair);
    expect(result.feedback, 'ลงให้ลึกกว่านี้');
  });

  test('flags the knee travelling past the toes', () {
    // Knee 100px in front of the ankle over a 100px shin — a 45 degree shin,
    // past the 40 degree limit.
    final result = analyzer.analyze(stackedPose(kneeX: 200), 85);
    expect(result.score, FormScore.fair);
    expect(result.feedback, contains('เข่าเกินนิ้วเท้า'));
  });

  test('flags an over-folded torso', () {
    // Shoulder 200px ahead of the hip over a 100px torso — about 63 degrees,
    // past the 55 degree limit.
    final result = analyzer.analyze(stackedPose(shoulderX: 300), 85);
    expect(result.score, FormScore.fair);
    expect(result.feedback, contains('หลังเอนไปข้างหน้า'));
  });

  test('scores poor and lists every issue when faults stack up', () {
    final result = analyzer.analyze(
      stackedPose(kneeX: 200, shoulderX: 300),
      110,
    );
    expect(result.score, FormScore.poor);
    expect(result.feedback, contains('ลงให้ลึกกว่านี้'));
    expect(result.feedback, contains('เข่าเกินนิ้วเท้า'));
    expect(result.feedback, contains('หลังเอนไปข้างหน้า'));
  });

  test('skips the geometry checks when the body is not confidently tracked', () {
    final pose = poseOf([
      lm(PoseLandmarkType.leftShoulder, 300, 50, likelihood: 0.2),
      lm(PoseLandmarkType.leftHip, 100, 150, likelihood: 0.2),
      lm(PoseLandmarkType.leftKnee, 200, 200, likelihood: 0.2),
      lm(PoseLandmarkType.leftAnkle, 100, 300, likelihood: 0.2),
    ]);
    // Depth is angle-only so it still applies; the landmark-based checks must
    // not fire on untrustworthy points.
    final result = analyzer.analyze(pose, 85);
    expect(result.score, FormScore.good);
    expect(result.feedback, 'ท่าดีมาก!');
  });

  test('exposes the rep thresholds the counter is built from', () {
    expect(analyzer.downThreshold, lessThan(analyzer.upThreshold));
    expect(analyzer.angleLabel, isNotEmpty);
  });
}
