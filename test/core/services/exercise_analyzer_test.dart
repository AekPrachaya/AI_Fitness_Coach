import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ai_fitness_coach/core/services/exercise_analyzer.dart';
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
    test('a clean rep is good and carries no issues', () {
      final result = ExerciseAnalyzer.verdict(const []);
      expect(result.score, FormScore.good);
      expect(result.feedback, 'ท่าดีมาก!');
      expect(result.issues, isEmpty);
    });

    test('one fault is fair and keeps the fault for tallying', () {
      final result = ExerciseAnalyzer.verdict(['เข่าเกินนิ้วเท้า']);
      expect(result.score, FormScore.fair);
      expect(result.feedback, 'เข่าเกินนิ้วเท้า');
      expect(result.issues, ['เข่าเกินนิ้วเท้า']);
    });

    test('several faults are poor and stay separable', () {
      final result = ExerciseAnalyzer.verdict(['หลังค่อม', 'ลงไม่ลึก']);
      expect(result.score, FormScore.poor);
      expect(result.feedback, 'หลังค่อม · ลงไม่ลึก');
      expect(result.issues, ['หลังค่อม', 'ลงไม่ลึก']);
    });

    test('the returned issue list cannot be mutated by a caller', () {
      final result = ExerciseAnalyzer.verdict(['a', 'b']);
      expect(() => result.issues.add('c'), throwsUnsupportedError);
    });

    test('notEvaluated is distinguishable from a graded-clean rep', () {
      expect(FormResult.notEvaluated.feedback, isEmpty);
      expect(ExerciseAnalyzer.verdict(const []).feedback, isNotEmpty);
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
