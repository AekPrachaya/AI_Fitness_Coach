import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_analyzer.dart';

class BicepCurlAnalyzer extends ExerciseAnalyzer {
  @override PoseLandmarkType get primaryA => PoseLandmarkType.leftShoulder;
  @override PoseLandmarkType get primaryB => PoseLandmarkType.leftElbow;
  @override PoseLandmarkType get primaryC => PoseLandmarkType.leftWrist;
  @override PoseLandmarkType get altA     => PoseLandmarkType.rightShoulder;
  @override PoseLandmarkType get altB     => PoseLandmarkType.rightElbow;
  @override PoseLandmarkType get altC     => PoseLandmarkType.rightWrist;

  @override double get downThreshold => 50.0;
  @override double get upThreshold   => 150.0;
  @override String get angleLabel    => 'ข้อศอก (องศา)';

  static const _analyzeThreshold = 120.0;
  // Ratios relative to upper-arm length (shoulder→elbow), so checks scale
  // correctly regardless of how far the user stands from the camera.
  static const _elbowDriftMaxRatio = 0.35; // 35 % of upper-arm length
  static const _bodySwayMaxRatio   = 0.15; // 15 % of upper-arm length

  double? _shoulderXAtCurlStart;

  @override
  FormResult analyze(Pose pose, double angle) {
    if (angle > _analyzeThreshold) {
      _shoulderXAtCurlStart = null;
      return const FormResult(score: FormScore.good, feedback: '');
    }

    final lms = pose.landmarks;
    final issues = <String>[];

    final arm = ExerciseAnalyzer.bestSide(
      lms,
      const [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      const [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    );

    if (arm case [final shoulder, final elbow]) {
      final upperArmLen = math.sqrt(
        math.pow(elbow.x - shoulder.x, 2) + math.pow(elbow.y - shoulder.y, 2),
      );

      if (upperArmLen > 0) {
        // 1. Elbow drift
        final driftRatio = (elbow.x - shoulder.x).abs() / upperArmLen;
        if (driftRatio > _elbowDriftMaxRatio) issues.add('ล็อกข้อศอกไว้ข้างลำตัว');

        // 2. Body sway
        _shoulderXAtCurlStart ??= shoulder.x;
        final swayRatio = (shoulder.x - _shoulderXAtCurlStart!).abs() / upperArmLen;
        if (swayRatio > _bodySwayMaxRatio) issues.add('อย่าแกว่งตัว');
      }
    }

    if (issues.isEmpty) return const FormResult(score: FormScore.good,  feedback: 'ท่าดีมาก!');
    if (issues.length == 1) return FormResult(score: FormScore.fair, feedback: issues.first);
    return FormResult(score: FormScore.poor, feedback: issues.join(' · '));
  }
}
