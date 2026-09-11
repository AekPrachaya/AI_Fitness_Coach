import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_analyzer.dart';

class SquatAnalyzer extends ExerciseAnalyzer {
  @override PoseLandmarkType get primaryA => PoseLandmarkType.leftHip;
  @override PoseLandmarkType get primaryB => PoseLandmarkType.leftKnee;
  @override PoseLandmarkType get primaryC => PoseLandmarkType.leftAnkle;
  @override PoseLandmarkType get altA     => PoseLandmarkType.rightHip;
  @override PoseLandmarkType get altB     => PoseLandmarkType.rightKnee;
  @override PoseLandmarkType get altC     => PoseLandmarkType.rightAnkle;

  @override double get downThreshold => 100.0;
  @override double get upThreshold   => 160.0;
  @override String get angleLabel    => 'เข่า (องศา)';
  @override double get met         => 5.0; // bodyweight squats, vigorous effort

  static const _analyzeThreshold = 130.0;
  static const _depthThreshold   = 90.0;
  static const _shinForwardMax   = 40.0;
  static const _torsoLeanMax     = 55.0;

  @override
  FormResult analyze(Pose pose, double angle) {
    if (angle > _analyzeThreshold) {
      return FormResult.notEvaluated;
    }

    final lms = pose.landmarks;
    final issues = <String>[];

    // 1. Depth
    if (angle > _depthThreshold) issues.add('ลงให้ลึกกว่านี้');

    // 2. Knee over toe
    final leg = ExerciseAnalyzer.bestSide(
      lms,
      const [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      const [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    );
    if (leg case [final knee, final ankle]) {
      final dx = (knee.x - ankle.x).abs();
      final dy = (knee.y - ankle.y).abs();
      if (dy > 0 && math.atan2(dx, dy) * 180 / math.pi > _shinForwardMax) {
        issues.add('เข่าเกินนิ้วเท้ามากเกินไป');
      }
    }

    // 3. Torso lean
    final torso = ExerciseAnalyzer.bestSide(
      lms,
      const [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      const [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    );
    if (torso case [final shoulder, final hip]) {
      final dx = (shoulder.x - hip.x).abs();
      final dy = (shoulder.y - hip.y).abs();
      if (dy > 0 && math.atan2(dx, dy) * 180 / math.pi > _torsoLeanMax) {
        issues.add('หลังเอนไปข้างหน้ามากเกินไป');
      }
    }

    return ExerciseAnalyzer.verdict(issues);
  }
}
