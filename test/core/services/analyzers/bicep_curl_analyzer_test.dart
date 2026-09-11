import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ai_fitness_coach/core/services/analyzers/bicep_curl_analyzer.dart';
import 'package:ai_fitness_coach/core/services/exercise_analyzer.dart';

import '../../../support/pose_fixtures.dart';

void main() {
  late BicepCurlAnalyzer analyzer;
  setUp(() => analyzer = BicepCurlAnalyzer());

  /// Upper arm hanging straight down: shoulder above elbow, 80px apart.
  Pose armPose({double shoulderX = 100, double elbowX = 100}) =>
      poseOf(withMirroredSide([
        lm(PoseLandmarkType.leftShoulder, shoulderX, 100),
        lm(PoseLandmarkType.leftElbow, elbowX, 180),
      ]));

  test('stays silent while the arm is still extended', () {
    final result = analyzer.analyze(armPose(), 160);
    expect(result.score, FormScore.good);
    expect(result.feedback, isEmpty);
  });

  test('praises a curl with the elbow pinned to the body', () {
    final result = analyzer.analyze(armPose(), 60);
    expect(result.score, FormScore.good);
    expect(result.feedback, 'ท่าดีมาก!');
  });

  test('flags the elbow drifting away from the torso', () {
    // Elbow 40px forward of a ~89px upper arm — a 0.45 ratio, past the 0.35
    // limit.
    final result = analyzer.analyze(armPose(elbowX: 140), 60);
    expect(result.score, FormScore.fair);
    expect(result.feedback, contains('ล็อกข้อศอก'));
  });

  test('flags body sway relative to where the curl started', () {
    // First frame anchors the shoulder; the second has swung 20px across an
    // 80px upper arm — a 0.25 ratio, past the 0.15 limit.
    analyzer.analyze(armPose(), 60);
    final result = analyzer.analyze(armPose(shoulderX: 120, elbowX: 120), 60);
    expect(result.score, FormScore.fair);
    expect(result.feedback, contains('อย่าแกว่งตัว'));
  });

  test('does not report sway on the very first frame of a curl', () {
    final result = analyzer.analyze(armPose(shoulderX: 250, elbowX: 250), 60);
    expect(result.feedback, isNot(contains('อย่าแกว่งตัว')));
  });

  test('re-anchors the sway reference once the arm extends again', () {
    analyzer.analyze(armPose(), 60); // anchor at x=100
    analyzer.analyze(armPose(), 160); // arm extended — anchor is dropped
    // A new curl starting from x=120 is not "sway" relative to the old rep.
    final result = analyzer.analyze(armPose(shoulderX: 120, elbowX: 120), 60);
    expect(result.feedback, isNot(contains('อย่าแกว่งตัว')));
  });

  test('scores poor when the elbow drifts and the body swings', () {
    analyzer.analyze(armPose(), 60);
    final result = analyzer.analyze(armPose(shoulderX: 120, elbowX: 165), 60);
    expect(result.score, FormScore.poor);
    expect(result.feedback, contains('ล็อกข้อศอก'));
    expect(result.feedback, contains('อย่าแกว่งตัว'));
  });

  test('skips the checks when the arm is not confidently tracked', () {
    final pose = poseOf([
      lm(PoseLandmarkType.leftShoulder, 100, 100, likelihood: 0.3),
      lm(PoseLandmarkType.leftElbow, 200, 180, likelihood: 0.3),
    ]);
    final result = analyzer.analyze(pose, 60);
    expect(result.score, FormScore.good);
    expect(result.feedback, 'ท่าดีมาก!');
  });
}
