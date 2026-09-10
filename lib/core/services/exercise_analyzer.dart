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

  /// Minimum ML Kit likelihood for a landmark to be trusted.
  static const double minLikelihood = 0.65;

  /// Returns the landmarks of whichever body side is tracked more confidently.
  ///
  /// [left] and [right] must list the same joints on opposite sides, in the
  /// same order. Landmarks are always taken from a single side — picking each
  /// joint independently could mix e.g. a left hip with a right knee, which
  /// yields a meaningless angle. Returns null unless every joint on at least
  /// one side clears [minLikelihood]; the returned list matches the input
  /// order and length.
  static List<PoseLandmark>? bestSide(
    Map<PoseLandmarkType, PoseLandmark> lms,
    List<PoseLandmarkType> left,
    List<PoseLandmarkType> right,
  ) {
    final l = _side(lms, left);
    final r = _side(lms, right);
    if (l == null) return r?.landmarks;
    if (r == null) return l.landmarks;
    return (l.score >= r.score ? l : r).landmarks;
  }

  /// Scores one side by its least-visible joint — a side is only as reliable
  /// as its weakest landmark. Returns null if any joint is missing or below
  /// [minLikelihood].
  static ({double score, List<PoseLandmark> landmarks})? _side(
    Map<PoseLandmarkType, PoseLandmark> lms,
    List<PoseLandmarkType> types,
  ) {
    final landmarks = <PoseLandmark>[];
    var worst = double.infinity;
    for (final type in types) {
      final lm = lms[type];
      if (lm == null || lm.likelihood <= minLikelihood) return null;
      if (lm.likelihood < worst) worst = lm.likelihood;
      landmarks.add(lm);
    }
    return (score: worst, landmarks: landmarks);
  }
}
