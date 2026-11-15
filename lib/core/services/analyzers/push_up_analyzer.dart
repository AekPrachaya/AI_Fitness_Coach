import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_analyzer.dart';
import '../form_fault.dart';

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
  @override double get hysteresis  => 6.0; // a full elbow lockout is hard to hold in a plank

  static const _analyzeThreshold = 110.0;
  static const _depthThreshold   = 90.0;
  static const _plankMinAngle    = 160.0; // shoulder-hip-knee must be straighter than this

  @override
  FormResult analyze(Pose pose, double angle) {
    if (angle > _analyzeThreshold) {
      return FormResult.notEvaluated;
    }

    final lms = pose.landmarks;
    final faults = <FormFault>[];

    // 1. Plank alignment — shoulder, hip and knee should be in a straight line
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
      if (_angleDeg(shoulder, hip, knee) < _plankMinAngle) {
        final broken = _hipBreak(shoulder, hip, knee);
        if (broken != null) faults.add(broken);
      }
    }

    // 2. Depth — elbow must reach below 90°
    if (angle > _depthThreshold) faults.add(FormFault.pushUpShallow);

    return ExerciseAnalyzer.verdict(faults);
  }

  /// Which way a broken plank is broken.
  ///
  /// The shoulder-hip-knee angle says the line is bent but not which way, and
  /// the two ways want opposite corrections: a dropped hip has to come up, a
  /// raised one has to come down. Telling the user the wrong one is worse than
  /// saying nothing, so the direction is read off the hip's side of the
  /// shoulder→knee line.
  ///
  /// Returns null when the body lies closer to vertical than horizontal in the
  /// frame — a push-up filmed end-on, where "above the line" carries no
  /// information about the hip and either cue would be a guess.
  FormFault? _hipBreak(
    PoseLandmark shoulder,
    PoseLandmark hip,
    PoseLandmark knee,
  ) {
    final run = knee.x - shoulder.x;
    final rise = knee.y - shoulder.y;
    if (run.abs() <= rise.abs()) return null;

    final lineY = shoulder.y + (hip.x - shoulder.x) / run * rise;
    // Image y grows downward, so the hip below the line is the sagging one.
    return hip.y > lineY ? FormFault.pushUpHipSag : FormFault.pushUpHipPike;
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
