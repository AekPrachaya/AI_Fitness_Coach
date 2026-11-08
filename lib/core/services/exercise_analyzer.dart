import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'form_fault.dart';
import 'analyzers/squat_analyzer.dart';
import 'analyzers/push_up_analyzer.dart';
import 'analyzers/deadlift_analyzer.dart';
import 'analyzers/bicep_curl_analyzer.dart';

enum FormScore { good, fair, poor }

class FormResult {
  const FormResult({
    required this.score,
    required this.feedback,
    this.faults = const [],
  });

  final FormScore score;

  /// The single line shown in the session HUD: the cue for the most important
  /// fault in [faults], or praise for a clean rep.
  ///
  /// One cue, never a list. A user mid-rep has about half a second of glance
  /// to spend on the screen, and three stacked corrections in that time read
  /// as noise — so the rest of [faults] waits its turn instead.
  final String feedback;

  /// Every fault found in this frame, most important first. Empty for a clean
  /// rep and for [notEvaluated].
  final List<FormFault> faults;

  /// The fault [feedback] is correcting, or null when there is nothing to fix.
  FormFault? get topFault => faults.isEmpty ? null : faults.first;

  /// True for a rep the analyzer graded and found nothing wrong with — as
  /// opposed to [notEvaluated], which it never looked at.
  bool get isClean => faults.isEmpty && feedback.isNotEmpty;

  /// This frame's verdict with the faults it has no business judging removed.
  ///
  /// [FaultTiming.rangeOfMotion] faults survive only on the frame the movement
  /// bottomed out. Every other frame of the rep they are dropped and what is
  /// left is re-graded — so a user still on the way down, who the depth check
  /// reads as shallow for as long as the descent lasts, simply comes back
  /// clean.
  ///
  /// This also keeps the session tally honest: scored per frame, "ลงไม่ลึกพอ"
  /// would be banked against every rep, deep ones included, purely because
  /// every descent passes through the shallow range on its way down.
  FormResult judgeableNow({required bool bottomedOut}) {
    if (bottomedOut || faults.isEmpty) return this;
    final keep = [
      for (final f in faults)
        if (f.timing == FaultTiming.posture) f,
    ];
    if (keep.length == faults.length) return this;
    return ExerciseAnalyzer.verdict(keep);
  }

  /// Fault names for the session tally, most frequent-first ordering aside.
  /// Labels rather than cues: a summary reads better naming the fault than
  /// repeating an instruction the workout is already over for.
  List<String> get issues => [for (final f in faults) f.label];

  /// Returned for a joint angle outside the range worth grading — standing
  /// between reps, say. Distinct from a graded-clean rep, which carries
  /// feedback, so session stats can ignore it.
  static const FormResult notEvaluated =
      FormResult(score: FormScore.good, feedback: '');

  /// Shown for a rep with nothing to correct.
  static const String praise = 'ท่าดีมาก!';
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

  /// Whether this exercise's checks are only meaningful from a side view.
  ///
  /// True for anything whose measurements are horizontal distances in the
  /// image standing in for forward travel — a torso leaning, a knee passing
  /// the toes, a hip off the plank line, and the joint angles themselves,
  /// which all bend in the sagittal plane. Face-on, those collapse toward
  /// zero and the exercise reads as flawless however it is performed.
  bool get needsSideView => true;

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

  /// Grades a frame from the faults found in it and picks the one cue to show.
  ///
  /// Grading is by severity, not by count: one risky fault — a spine taking
  /// load in a bad position — is worse than two sloppy-but-safe ones, so it
  /// scores [FormScore.poor] on its own rather than waiting for company.
  static FormResult verdict(List<FormFault> faults) {
    if (faults.isEmpty) {
      return const FormResult(
        score: FormScore.good,
        feedback: FormResult.praise,
      );
    }
    final ranked = [...faults]..sort(FormFault.byPriority);
    final risky = ranked.any((f) => f.severity == FormSeverity.risky);
    return FormResult(
      score: risky || ranked.length > 1 ? FormScore.poor : FormScore.fair,
      feedback: ranked.first.cue,
      faults: List.unmodifiable(ranked),
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
