import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'analyzers/squat_analyzer.dart';
import 'analyzers/push_up_analyzer.dart';
import 'analyzers/deadlift_analyzer.dart';
import 'analyzers/bicep_curl_analyzer.dart';

enum FormScore { good, fair, poor }

class FormResult {
  const FormResult({required this.score, required this.feedback});
  final FormScore score;
  final String feedback;
}

abstract class ExerciseAnalyzer {
  PoseLandmarkType get primaryA;
  PoseLandmarkType get primaryB; // vertex — the joint being measured
  PoseLandmarkType get primaryC;

  PoseLandmarkType get altA; // opposite-side fallback
  PoseLandmarkType get altB;
  PoseLandmarkType get altC;

  double get downThreshold; // angle < this → exercise position reached
  double get upThreshold;   // angle > this → rep counted

  String get angleLabel;    // label shown in the session HUD

  FormResult analyze(Pose pose, double angle);

  // ── Factory ───────────────────────────────────────────────────────────────

  static ExerciseAnalyzer forId(String id) => switch (id) {
        'squats'      => SquatAnalyzer(),
        'push_ups'    => PushUpAnalyzer(),
        'deadlifts'   => DeadliftAnalyzer(),
        'bicep_curls' => BicepCurlAnalyzer(),
        _             => SquatAnalyzer(),
      };

  // ── Helper ────────────────────────────────────────────────────────────────

  /// Returns the landmark with higher confidence between [primary] and [alt].
  /// Returns null if neither exceeds the 0.5 likelihood threshold.
  static PoseLandmark? best(
    Map<PoseLandmarkType, PoseLandmark> lms,
    PoseLandmarkType primary,
    PoseLandmarkType alt,
  ) {
    final p = lms[primary];
    final a = lms[alt];
    if (p == null && a == null) return null;
    if (p == null) return a!.likelihood > 0.5 ? a : null;
    if (a == null) return p.likelihood > 0.5 ? p : null;
    final winner = p.likelihood >= a.likelihood ? p : a;
    return winner.likelihood > 0.5 ? winner : null;
  }
}
