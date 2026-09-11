import '../../../core/services/exercise_analyzer.dart';

/// Accumulates form grades across a workout so the finished session can be
/// persisted with real numbers instead of zeros.
///
/// Grades are collected per rep, not per frame: [observe] folds every graded
/// frame into the rep in progress, and [commitRep] closes it out when the rep
/// counter fires. Sampling per frame would let a slow rep outweigh a fast one.
class SessionStats {
  /// Score on the 0–100 scale the stored session history already uses.
  static const _scoreValue = {
    FormScore.good: 100.0,
    FormScore.fair: 70.0,
    FormScore.poor: 40.0,
  };

  final List<double> _repScores = [];
  final Map<String, int> _errorCounts = {};

  FormScore? _repWorst;
  final Set<String> _repIssues = {};

  /// Folds one analysed frame into the rep in progress. Frames the analyzer
  /// did not grade — [FormResult.notEvaluated] — are ignored.
  void observe(FormResult? form) {
    if (form == null || form.feedback.isEmpty) return;
    if (_repWorst == null || form.score.index > _repWorst!.index) {
      _repWorst = form.score;
    }
    _repIssues.addAll(form.issues);
  }

  /// Closes out the rep in progress, banking its worst grade and its faults.
  /// A rep with no graded frames (every frame dropped while the detector was
  /// busy) is skipped rather than scored as perfect.
  void commitRep() {
    final worst = _repWorst;
    if (worst != null) {
      _repScores.add(_scoreValue[worst]!);
      for (final issue in _repIssues) {
        _errorCounts[issue] = (_errorCounts[issue] ?? 0) + 1;
      }
    }
    _repWorst = null;
    _repIssues.clear();
  }

  /// Number of reps that carried a grade.
  int get gradedReps => _repScores.length;

  /// Mean form score over the graded reps, 0–100, rounded to one decimal.
  /// Zero when nothing was graded.
  double get avgFormScore {
    if (_repScores.isEmpty) return 0;
    final mean = _repScores.reduce((a, b) => a + b) / _repScores.length;
    return double.parse(mean.toStringAsFixed(1));
  }

  /// The fault seen in the most reps, or an empty string when the workout was
  /// clean. Ties break on the fault that reached its count first.
  String get mostCommonError {
    if (_errorCounts.isEmpty) return '';
    return _errorCounts.entries
        .reduce((a, b) => b.value > a.value ? b : a)
        .key;
  }

  /// Every fault seen, most frequent first — the raw tally behind
  /// [mostCommonError].
  Map<String, int> get errorCounts {
    final sorted = _errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.unmodifiable({for (final e in sorted) e.key: e.value});
  }

  /// Estimated energy burned, in kcal, from the standard MET formula
  /// (kcal/min = MET × 3.5 × kg / 200).
  static int estimateCalories({
    required double met,
    required double weightKg,
    required int durationSeconds,
  }) {
    if (durationSeconds <= 0 || weightKg <= 0) return 0;
    final minutes = durationSeconds / 60;
    return (met * 3.5 * weightKg / 200 * minutes).round();
  }
}
