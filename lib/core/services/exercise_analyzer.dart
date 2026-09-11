import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'analyzers/squat_analyzer.dart';
import 'analyzers/push_up_analyzer.dart';
import 'analyzers/deadlift_analyzer.dart';
import 'analyzers/bicep_curl_analyzer.dart';

enum FormScore { good, fair, poor }

class FormResult {
  const FormResult({
    required this.score,
    required this.feedback,
    this.issues = const [],
  });

  final FormScore score;

  /// The line shown in the session HUD.
  final String feedback;

  /// The individual faults behind [feedback], kept apart so a finished session
  /// can tally them without re-splitting the display string. Empty for a clean
  /// rep and for [notEvaluated].
  final List<String> issues;

  /// Returned for a joint angle outside the range worth grading — standing
  /// between reps, say. Distinct from a graded-clean rep, which carries
  /// feedback, so session stats can ignore it.
  static const FormResult notEvaluated =
      FormResult(score: FormScore.good, feedback: '');
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

  /// Metabolic equivalent of task — kcal/kg/hour — used to estimate the
  /// energy a finished session burned.
  double get met;

  /// Dead-band around each rep threshold, in degrees.
  ///
  /// A wider band rejects more jitter but demands a fuller rep, so it cannot
  /// be one number for every exercise: a lockout that is easy at the top of a
  /// curl is near the limit of most people's elbow extension in a push-up.
  /// These are starting points and want tuning against real footage.
  double get hysteresis => 8.0;

  FormResult analyze(Pose pose, double angle);

  // ── Factory ───────────────────────────────────────────────────────────────

  static ExerciseAnalyzer forId(String id) => switch (id) {
        'squats'      => SquatAnalyzer(),
        'push_ups'    => PushUpAnalyzer(),
        'deadlifts'   => DeadliftAnalyzer(),
        'bicep_curls' => BicepCurlAnalyzer(),
        _             => SquatAnalyzer(),
      };

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Grades a rep from the faults found in it: none is good, one is fair,
  /// more than one is poor.
  static FormResult verdict(List<String> issues) {
    if (issues.isEmpty) {
      return const FormResult(score: FormScore.good, feedback: 'ท่าดีมาก!');
    }
    return FormResult(
      score: issues.length == 1 ? FormScore.fair : FormScore.poor,
      feedback: issues.join(' · '),
      issues: List.unmodifiable(issues),
    );
  }

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
