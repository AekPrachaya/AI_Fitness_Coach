import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_analyzer.dart';

class BicepCurlAnalyzer extends ExerciseAnalyzer {
  @override PoseLandmarkType get primaryA => PoseLandmarkType.leftShoulder;
  @override PoseLandmarkType get primaryB => PoseLandmarkType.leftElbow;
  @override PoseLandmarkType get primaryC => PoseLandmarkType.leftWrist;
  @override PoseLandmarkType get altA     => PoseLandmarkType.rightShoulder;
  @override PoseLandmarkType get altB     => PoseLandmarkType.rightElbow;
  @override PoseLandmarkType get altC     => PoseLandmarkType.rightWrist;

  // Rep starts extended (> upThreshold), curls to < downThreshold, then
  // returns to extended — same state-machine direction as all other exercises.
  @override double get downThreshold => 50.0;
  @override double get upThreshold   => 150.0;
  @override String get angleLabel    => 'ข้อศอก (องศา)';

  static const _analyzeThreshold  = 120.0;
  static const _elbowDriftMax     = 30.0; // max horizontal elbow drift from shoulder (px)
  static const _bodySwayMax       = 20.0; // max shoulder horizontal movement (px)

  // Tracks shoulder x at the start of each curl to detect body sway.
  double? _shoulderXAtCurlStart;

  @override
  FormResult analyze(Pose pose, double angle) {
    if (angle > _analyzeThreshold) {
      _shoulderXAtCurlStart = null; // reset when arm is extended
      return const FormResult(score: FormScore.good, feedback: '');
    }

    final lms = pose.landmarks;
    final issues = <String>[];

    final shoulder = ExerciseAnalyzer.best(lms, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    final elbow    = ExerciseAnalyzer.best(lms, PoseLandmarkType.leftElbow,    PoseLandmarkType.rightElbow);

    // 1. Elbow drift — elbow should stay close to the torso
    if (shoulder != null && elbow != null) {
      final drift = (elbow.x - shoulder.x).abs();
      if (drift > _elbowDriftMax) issues.add('ล็อกข้อศอกไว้ข้างลำตัว');
    }

    // 2. Body sway — shoulder should not swing during the curl
    if (shoulder != null) {
      _shoulderXAtCurlStart ??= shoulder.x;
      final sway = (shoulder.x - _shoulderXAtCurlStart!).abs();
      if (sway > _bodySwayMax) issues.add('อย่าแกว่งตัว');
    }

    if (issues.isEmpty) return const FormResult(score: FormScore.good,  feedback: 'ท่าดีมาก!');
    if (issues.length == 1) return FormResult(score: FormScore.fair, feedback: issues.first);
    return FormResult(score: FormScore.poor, feedback: issues.join(' · '));
  }
}
