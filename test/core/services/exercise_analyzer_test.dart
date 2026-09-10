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
