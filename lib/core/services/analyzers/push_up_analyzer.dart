import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_analyzer.dart';

class PushUpAnalyzer extends ExerciseAnalyzer {
  @override PoseLandmarkType get primaryA => PoseLandmarkType.leftShoulder;
  @override PoseLandmarkType get primaryB => PoseLandmarkType.leftElbow;
  @override PoseLandmarkType get primaryC => PoseLandmarkType.leftWrist;
  @override PoseLandmarkType get altA     => PoseLandmarkType.rightShoulder;
  @override PoseLandmarkType get altB     => PoseLandmarkType.rightElbow;
  @override PoseLandmarkType get altC     => PoseLandmarkType.rightWrist;

  @override double get downThreshold => 90.0;
  @override double get upThreshold   => 160.0;
  @override String get angleLabel    => 'ข้อศอก (องศา)';
  @override double get met         => 3.8; // calisthenics, moderate effort

  static const _analyzeThreshold = 110.0;
  static const _depthThreshold   = 90.0;
  static const _plankMinAngle    = 160.0; // shoulder-hip-knee must be straighter than this

  @override
  FormResult analyze(Pose pose, double angle) {
    if (angle > _analyzeThreshold) {
      return FormResult.notEvaluated;
    }

    final lms = pose.landmarks;
    final issues = <String>[];

    // 1. Plank alignment — shoulder, hip, knee should be in a straight line
    final chain = ExerciseAnalyzer.bestSide(
      lms,
      const [
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
      ],
      const [
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.rightKnee,
      ],
    );
    if (chain case [final shoulder, final hip, final knee]) {
      final plankAngle = _angleDeg(shoulder, hip, knee);
      if (plankAngle < _plankMinAngle) issues.add('หลังแอ่น หรือสะโพกหย่อน');
    }

    // 2. Depth — elbow must reach below 90°
    if (angle > _depthThreshold) issues.add('ลงให้ถึงกว่านี้');

    return ExerciseAnalyzer.verdict(issues);
  }

  // Angle at vertex [b] formed by points a-b-c, in degrees.
  double _angleDeg(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = math.atan2(c.y - b.y, c.x - b.x) -
                    math.atan2(a.y - b.y, a.x - b.x);
    double deg = radians.abs() * (180.0 / math.pi);
    if (deg > 180.0) deg = 360.0 - deg;
    return deg;
  }
}
