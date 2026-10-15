import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_analyzer.dart';
import '../form_fault.dart';

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

  /// Max torso tilt from vertical, in degrees, before the hinge counts as
  /// folded too far.
  ///
  /// Not a rounded-back detector, despite what the old name claimed: a
  /// shoulder, a hip and a knee describe one bend, so a rounded spine and a
  /// deep-but-neutral hinge produce the same three points. What is left to
  /// measure is how far the torso has dropped, and that only reads as a fault
  /// once it is near flat — a hinge legitimately passes 45° on the way down.
  /// Catching true rounding needs landmarks along the spine that ML Kit's
  /// pose model does not provide.
  static const _torsoDropMax = 75.0;

  @override
  FormResult analyze(Pose pose, double angle) {
    if (angle > _analyzeThreshold) {
      return FormResult.notEvaluated;
    }

    final lms = pose.landmarks;
    final faults = <FormFault>[];

    // 1. Torso drop — the hinge should not fold the chest down to the floor
    final torso = ExerciseAnalyzer.bestSide(
      lms,
      const [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      const [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    );
    if (torso case [final shoulder, final hip]) {
      final dx = (shoulder.x - hip.x).abs();
      final dy = (shoulder.y - hip.y).abs();
      if (dy > 0 && math.atan2(dx, dy) * 180 / math.pi > _torsoDropMax) {
        faults.add(FormFault.deadliftTorsoDrop);
      }
    }

    return ExerciseAnalyzer.verdict(faults);
  }
}
