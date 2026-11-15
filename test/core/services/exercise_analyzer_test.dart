import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ai_fitness_coach/core/services/exercise_analyzer.dart';
import 'package:ai_fitness_coach/core/services/form_fault.dart';
import 'package:ai_fitness_coach/core/services/analyzers/bicep_curl_analyzer.dart';
import 'package:ai_fitness_coach/core/services/analyzers/deadlift_analyzer.dart';
import 'package:ai_fitness_coach/core/services/analyzers/push_up_analyzer.dart';
import 'package:ai_fitness_coach/core/services/analyzers/squat_analyzer.dart';

import '../../support/pose_fixtures.dart';

void main() {
  const left = [
    PoseLandmarkType.leftHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.leftAnkle,
  ];
  const right = [
    PoseLandmarkType.rightHip,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.rightAnkle,
  ];

  Map<PoseLandmarkType, PoseLandmark> lmsOf(List<PoseLandmark> l) =>
      {for (final e in l) e.type: e};

  group('forId', () {
    test('maps every known exercise id to its analyzer', () {
      expect(ExerciseAnalyzer.forId('squats'), isA<SquatAnalyzer>());
      expect(ExerciseAnalyzer.forId('push_ups'), isA<PushUpAnalyzer>());
      expect(ExerciseAnalyzer.forId('deadlifts'), isA<DeadliftAnalyzer>());
      expect(ExerciseAnalyzer.forId('bicep_curls'), isA<BicepCurlAnalyzer>());
    });

    test('falls back to squats for an unknown id', () {
      expect(ExerciseAnalyzer.forId('kettlebell_swings'), isA<SquatAnalyzer>());
    });
  });

  group('verdict', () {
    test('a clean rep is good and carries no faults', () {
      final result = ExerciseAnalyzer.verdict(const []);
      expect(result.score, FormScore.good);
      expect(result.feedback, FormResult.praise);
      expect(result.faults, isEmpty);
      expect(result.isClean, isTrue);
    });

    test('one minor fault is fair and shows its cue', () {
      final result = ExerciseAnalyzer.verdict([FormFault.squatShallow]);
      expect(result.score, FormScore.fair);
      expect(result.feedback, FormFault.squatShallow.cue);
      expect(result.topFault, FormFault.squatShallow);
    });

    test('one risky fault is poor without needing company', () {
      // Severity, not arithmetic: a spine loaded in a bad position is the
      // worst thing in a set even if it is the only thing wrong with it.
      final result = ExerciseAnalyzer.verdict([FormFault.squatTorsoLean]);
      expect(result.score, FormScore.poor);
    });

    test('several faults are poor and stay separable for the tally', () {
      final result = ExerciseAnalyzer.verdict(
        [FormFault.squatShallow, FormFault.squatKneeOverToe],
      );
      expect(result.score, FormScore.poor);
      expect(result.faults, hasLength(2));
      expect(result.issues, [
        FormFault.squatKneeOverToe.label,
        FormFault.squatShallow.label,
      ]);
    });

    test('shows only the most important cue, never a list of them', () {
      // Three corrections at once is noise to someone halfway through a rep.
      final result = ExerciseAnalyzer.verdict([
        FormFault.squatShallow,
        FormFault.squatKneeOverToe,
        FormFault.squatTorsoLean,
      ]);
      expect(result.feedback, FormFault.squatTorsoLean.cue);
      expect(result.feedback, isNot(contains('·')));
    });

    test('ranks the faults however they arrive', () {
      final result = ExerciseAnalyzer.verdict(
        [FormFault.squatShallow, FormFault.squatTorsoLean],
      );
      expect(result.topFault, FormFault.squatTorsoLean);
    });

    test('the returned fault list cannot be mutated by a caller', () {
      final result = ExerciseAnalyzer.verdict([FormFault.squatShallow]);
      expect(() => result.faults.add(FormFault.squatTorsoLean),
          throwsUnsupportedError);
    });

    test('notEvaluated is distinguishable from a graded-clean rep', () {
      expect(FormResult.notEvaluated.feedback, isEmpty);
      expect(FormResult.notEvaluated.isClean, isFalse);
      expect(ExerciseAnalyzer.verdict(const []).isClean, isTrue);
    });
  });

  group('judgeableNow', () {
    // The bug this exists for: the depth check reads a knee at 110° as
    // shallow, which is true at the top of a rep and nonsense halfway down
    // one. The user was being corrected for not having gone deep yet while
    // still on their way down, and again on the way up when the rep was
    // already over and nothing could be done about it.
    test('hides a depth fault anywhere but the bottom of the rep', () {
      final descending = ExerciseAnalyzer.verdict([FormFault.squatShallow])
          .judgeableNow(bottomedOut: false);
      expect(descending.faults, isEmpty);
      expect(descending.isClean, isTrue,
          reason: 'mid-descent is not a fault, it is a descent');
    });

    test('reports a depth fault at the turnaround', () {
      final bottom = ExerciseAnalyzer.verdict([FormFault.squatShallow])
          .judgeableNow(bottomedOut: true);
      expect(bottom.topFault, FormFault.squatShallow);
      expect(bottom.feedback, FormFault.squatShallow.cue);
    });

    test('posture faults are judged on every frame of the rep', () {
      // A rounded back is wrong while it is rounded, whichever way the user
      // happens to be moving.
      for (final bottomedOut in [true, false]) {
        final result = ExerciseAnalyzer.verdict([FormFault.squatTorsoLean])
            .judgeableNow(bottomedOut: bottomedOut);
        expect(result.topFault, FormFault.squatTorsoLean,
            reason: 'bottomedOut: $bottomedOut');
      }
    });

    test('re-grades what survives instead of keeping a stale score', () {
      // Depth plus a lean scores poor for having two faults. Drop the depth
      // and a single minor fault is left — which is fair, not poor.
      final mixed = ExerciseAnalyzer.verdict(
        [FormFault.squatShallow, FormFault.curlElbowDrift],
      );
      expect(mixed.score, FormScore.poor);

      final descending = mixed.judgeableNow(bottomedOut: false);
      expect(descending.faults, [FormFault.curlElbowDrift]);
      expect(descending.score, FormScore.fair);
      expect(descending.feedback, FormFault.curlElbowDrift.cue);
    });

    test('leaves an all-posture verdict untouched', () {
      final posture = ExerciseAnalyzer.verdict(
        [FormFault.squatTorsoLean, FormFault.squatKneeOverToe],
      );
      expect(posture.judgeableNow(bottomedOut: false), same(posture));
    });

    test('leaves a clean frame and an ungraded one alone', () {
      final clean = ExerciseAnalyzer.verdict(const []);
      expect(clean.judgeableNow(bottomedOut: false), same(clean));
      expect(
        FormResult.notEvaluated.judgeableNow(bottomedOut: false).feedback,
        isEmpty,
      );
    });
  });

  group('per-exercise tuning', () {
    final analyzers = {
      'squats': ExerciseAnalyzer.forId('squats'),
      'push_ups': ExerciseAnalyzer.forId('push_ups'),
      'deadlifts': ExerciseAnalyzer.forId('deadlifts'),
      'bicep_curls': ExerciseAnalyzer.forId('bicep_curls'),
    };

    test('thresholds leave a usable range of motion', () {
      analyzers.forEach((id, a) {
        expect(a.downThreshold, lessThan(a.upThreshold), reason: id);
      });
    });

    test('the dead-band cannot swallow the range of motion', () {
      // Hysteresis is applied at both ends, so twice it must still fit inside
      // the span or no rep could ever be counted.
      analyzers.forEach((id, a) {
        expect(a.hysteresis * 2, lessThan(a.upThreshold - a.downThreshold),
            reason: id);
        expect(a.hysteresis, greaterThan(0), reason: id);
      });
    });

    test('only the bicep curl survives a camera square to the user', () {
      // The other three measure forward travel as horizontal distance in the
      // image, which collapses toward zero face-on — so they would find
      // nothing wrong with any position at all. Both curl checks read the
      // same either way, and demanding a side view there would cost the user
      // more than it buys.
      expect(
        {
          for (final e in analyzers.entries) e.key: e.value.needsSideView,
        },
        {
          'squats': true,
          'push_ups': true,
          'deadlifts': true,
          'bicep_curls': false,
        },
      );
    });

    test('every exercise carries a plausible MET and a label', () {
      analyzers.forEach((id, a) {
        expect(a.met, inExclusiveRange(1, 20), reason: id);
        expect(a.angleLabel, isNotEmpty, reason: id);
      });
    });
  });

  group('bestSide', () {
    test('picks the side whose weakest joint is strongest', () {
      final lms = lmsOf([
        lm(PoseLandmarkType.leftHip, 0, 0, likelihood: 0.90),
        lm(PoseLandmarkType.leftKnee, 0, 0, likelihood: 0.89),
        lm(PoseLandmarkType.leftAnkle, 0, 0, likelihood: 0.88),
        lm(PoseLandmarkType.rightHip, 0, 0, likelihood: 0.70),
        lm(PoseLandmarkType.rightKnee, 0, 0, likelihood: 0.71),
        lm(PoseLandmarkType.rightAnkle, 0, 0, likelihood: 0.72),
      ]);
      expect(ExerciseAnalyzer.bestSide(lms, left, right)!.map((e) => e.type),
          left);
    });

    test('never mixes sides, even when one opposite joint scores highest', () {
      // The old per-joint selection would have taken leftHip (.90) with
      // rightKnee (.95) and leftAnkle (.88) — three joints from two bodies'
      // worth of geometry, producing a meaningless angle.
      final lms = lmsOf([
        lm(PoseLandmarkType.leftHip, 0, 0, likelihood: 0.90),
        lm(PoseLandmarkType.leftKnee, 0, 0, likelihood: 0.89),
        lm(PoseLandmarkType.leftAnkle, 0, 0, likelihood: 0.88),
        lm(PoseLandmarkType.rightHip, 0, 0, likelihood: 0.70),
        lm(PoseLandmarkType.rightKnee, 0, 0, likelihood: 0.95),
        lm(PoseLandmarkType.rightAnkle, 0, 0, likelihood: 0.71),
      ]);
      expect(ExerciseAnalyzer.bestSide(lms, left, right)!.map((e) => e.type),
          left);
    });

    test('falls back to the other side when a joint is occluded', () {
      final lms = lmsOf([
        lm(PoseLandmarkType.leftHip, 0, 0, likelihood: 0.99),
        lm(PoseLandmarkType.leftKnee, 0, 0, likelihood: 0.99),
        // left ankle out of frame
        lm(PoseLandmarkType.rightHip, 0, 0, likelihood: 0.70),
        lm(PoseLandmarkType.rightKnee, 0, 0, likelihood: 0.70),
        lm(PoseLandmarkType.rightAnkle, 0, 0, likelihood: 0.70),
      ]);
      expect(ExerciseAnalyzer.bestSide(lms, left, right)!.map((e) => e.type),
          right);
    });

    test('returns null when neither side clears the likelihood threshold', () {
      final lms = lmsOf([
        for (final t in [...left, ...right]) lm(t, 0, 0, likelihood: 0.60),
      ]);
      expect(ExerciseAnalyzer.bestSide(lms, left, right), isNull);
    });

    test('returns null when a joint sits exactly on the threshold', () {
      final lms = lmsOf([
        for (final t in [...left, ...right])
          lm(t, 0, 0, likelihood: ExerciseAnalyzer.minLikelihood),
      ]);
      expect(ExerciseAnalyzer.bestSide(lms, left, right), isNull);
    });

    test('preserves the requested joint order', () {
      final lms = lmsOf([
        for (final t in [...left, ...right]) lm(t, 0, 0),
      ]);
      final reversed = left.reversed.toList();
      expect(
        ExerciseAnalyzer.bestSide(lms, reversed, right.reversed.toList())!
            .map((e) => e.type),
        reversed,
      );
    });
  });
}
