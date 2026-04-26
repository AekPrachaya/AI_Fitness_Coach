import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_analyzer.dart';

class DeadliftAnalyzer extends ExerciseAnalyzer {
  @override PoseLandmarkType get primaryA => PoseLandmarkType.leftShoulder;
  @override PoseLandmarkType get primaryB => PoseLandmarkType.leftHip;
  @override PoseLandmarkType get primaryC => PoseLandmarkType.leftKnee;
  @override PoseLandmarkType get altA     => PoseLandmarkType.rightShoulder;
  @override PoseLandmarkType get altB     => PoseLandmarkType.rightHip;
  @override PoseLandmarkType get altC     => PoseLandmarkType.rightKnee;

  @override double get downThreshold => 80.0;
  @override double get upThreshold   => 160.0;
  @override String get angleLabel    => 'สะโพก (องศา)';

  static const _analyzeThreshold = 120.0;
  static const _backRoundMax = 35.0; // max torso tilt from vertical (degrees)

  @override
  FormResult analyze(Pose pose, double angle) {
    if (angle > _analyzeThreshold) {
      return const FormResult(score: FormScore.good, feedback: '');
    }

    final lms = pose.landmarks;
    final issues = <String>[];

    // 1. Back rounding — torso should stay relatively neutral when hinged
    final shoulder = ExerciseAnalyzer.best(lms, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    final hip      = ExerciseAnalyzer.best(lms, PoseLandmarkType.leftHip,      PoseLandmarkType.rightHip);
    if (shoulder != null && hip != null) {
      final dx = (shoulder.x - hip.x).abs();
      final dy = (shoulder.y - hip.y).abs();
      if (dy > 0 && math.atan2(dx, dy) * 180 / math.pi > _backRoundMax) {
        issues.add('หลังค่อมเกินไป');
      }
    }

    if (issues.isEmpty) return const FormResult(score: FormScore.good,  feedback: 'ท่าดีมาก!');
    if (issues.length == 1) return FormResult(score: FormScore.fair, feedback: issues.first);
    return FormResult(score: FormScore.poor, feedback: issues.join(' · '));
  }
}
