import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/core/services/exercise_analyzer.dart';
import 'package:ai_fitness_coach/features/workout/session/session_stats.dart';

void main() {
  late SessionStats stats;
  setUp(() => stats = SessionStats());

  FormResult clean() => ExerciseAnalyzer.verdict(const []);
  FormResult withIssues(List<String> issues) => ExerciseAnalyzer.verdict(issues);

  /// Feeds [frames] into one rep and closes it.
  void rep(List<FormResult> frames) {
    for (final f in frames) {
      stats.observe(f);
    }
    stats.commitRep();
  }

  test('an untouched session reports nothing rather than a perfect score', () {
    expect(stats.gradedReps, 0);
    expect(stats.avgFormScore, 0);
    expect(stats.mostCommonError, isEmpty);
    expect(stats.errorCounts, isEmpty);
  });

  test('a clean rep scores 100', () {
    rep([clean(), clean()]);
    expect(stats.gradedReps, 1);
    expect(stats.avgFormScore, 100);
    expect(stats.mostCommonError, isEmpty);
  });

  test('ungraded frames are ignored, not scored as perfect', () {
    // Standing between reps produces notEvaluated, which carries no feedback.
    rep([FormResult.notEvaluated, FormResult.notEvaluated]);
    expect(stats.gradedReps, 0);
    expect(stats.avgFormScore, 0);
  });

  test('null frames are ignored', () {
    stats.observe(null);
    stats.commitRep();
    expect(stats.gradedReps, 0);
  });

  test('a rep keeps its worst frame, not its last', () {
    // The user dips into a poor position mid-rep then recovers; the rep is
    // still a poor one.
    rep([clean(), withIssues(['a', 'b']), clean()]);
    expect(stats.gradedReps, 1);
    expect(stats.avgFormScore, 40);
  });

  test('one fault grades a rep fair, several grade it poor', () {
    rep([withIssues(['a'])]);
    expect(stats.avgFormScore, 70);

    rep([withIssues(['a', 'b'])]);
    expect(stats.avgFormScore, 55, reason: 'mean of 70 and 40');
  });

  test('averages across reps and rounds to one decimal', () {
    rep([clean()]); // 100
    rep([withIssues(['a'])]); // 70
    rep([withIssues(['a'])]); // 70
    expect(stats.gradedReps, 3);
    expect(stats.avgFormScore, 80);
  });

  test('a fault repeated within one rep counts once for that rep', () {
    rep([
      withIssues(['knees']),
      withIssues(['knees']),
      withIssues(['knees']),
    ]);
    expect(stats.errorCounts, {'knees': 1});
  });

  test('counts how many reps each fault appeared in', () {
    rep([withIssues(['knees'])]);
    rep([withIssues(['knees', 'back'])]);
    rep([withIssues(['back'])]);
    rep([withIssues(['back'])]);
    expect(stats.errorCounts, {'back': 3, 'knees': 2});
    expect(stats.mostCommonError, 'back');
  });

  test('errorCounts is ordered most frequent first and is unmodifiable', () {
    rep([withIssues(['rare'])]);
    rep([withIssues(['common'])]);
    rep([withIssues(['common'])]);
    expect(stats.errorCounts.keys.first, 'common');
    expect(() => stats.errorCounts['x'] = 1, throwsUnsupportedError);
  });

  test('faults seen in an uncommitted rep are not banked yet', () {
    stats.observe(withIssues(['knees']));
    expect(stats.gradedReps, 0);
    expect(stats.mostCommonError, isEmpty);

    stats.commitRep();
    expect(stats.mostCommonError, 'knees');
  });

  test('committing a rep resets the buffer for the next one', () {
    rep([withIssues(['knees'])]);
    rep([clean()]);
    expect(stats.errorCounts, {'knees': 1});
    expect(stats.avgFormScore, 85, reason: 'mean of 70 and 100');
  });

  group('estimateCalories', () {
    test('follows the MET formula', () {
      // 5 MET * 3.5 * 70kg / 200 = 6.125 kcal/min, over 10 minutes.
      expect(
        SessionStats.estimateCalories(
          met: 5,
          weightKg: 70,
          durationSeconds: 600,
        ),
        61,
      );
    });

    test('scales with body weight and effort', () {
      final light = SessionStats.estimateCalories(
        met: 3.5,
        weightKg: 55,
        durationSeconds: 600,
      );
      final heavy = SessionStats.estimateCalories(
        met: 6,
        weightKg: 90,
        durationSeconds: 600,
      );
      expect(heavy, greaterThan(light));
    });

    test('returns zero rather than a negative or absurd estimate', () {
      expect(
        SessionStats.estimateCalories(
            met: 5, weightKg: 70, durationSeconds: 0),
        0,
      );
      expect(
        SessionStats.estimateCalories(
            met: 5, weightKg: 0, durationSeconds: 600),
        0,
      );
    });
  });
}
