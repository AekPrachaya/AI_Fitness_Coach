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
  @override double get met         => 6.0; // free-weight hinge, vigorous effort

  static const _analyzeThreshold = 120.0;
  static const _backRoundMax = 35.0; // max torso tilt from vertical (degrees)

  @override
  FormResult analyze(Pose pose, double angle) {
    if (angle > _analyzeThreshold) {
      return FormResult.notEvaluated;
    }

    final lms = pose.landmarks;
    final issues = <String>[];

    // 1. Back rounding — torso should stay relatively neutral when hinged
    final torso = ExerciseAnalyzer.bestSide(
      lms,
      const [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      const [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    );
    if (torso case [final shoulder, final hip]) {
      final dx = (shoulder.x - hip.x).abs();
      final dy = (shoulder.y - hip.y).abs();
      if (dy > 0 && math.atan2(dx, dy) * 180 / math.pi > _backRoundMax) {
        issues.add('หลังค่อมเกินไป');
      }
    }

    return ExerciseAnalyzer.verdict(issues);
  }
}
