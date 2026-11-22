import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ai_fitness_coach/core/services/form_model/form_features.dart';
import 'package:ai_fitness_coach/core/services/form_model/squat_form_classifier.dart';

import '../../../support/pose_fixtures.dart';

/// Landmarks as the fixture stores them: 33 rows of x, y, z, likelihood, in
/// ML Kit's PoseLandmarkType order (which is BlazePose's index order).
Map<PoseLandmarkType, PoseLandmark> _landmarks(List<dynamic> rows) => {
      for (var i = 0; i < rows.length; i++)
        PoseLandmarkType.values[i]: PoseLandmark(
          type: PoseLandmarkType.values[i],
          x: (rows[i][0] as num).toDouble(),
          y: (rows[i][1] as num).toDouble(),
          z: (rows[i][2] as num).toDouble(),
          likelihood: (rows[i][3] as num).toDouble(),
        ),
    };

void main() {
  // Written by tool/pose_eval/export_form_model.py from form_features.py and
  // the exported weights. If these fail after retraining, re-export both.
  final fixture = jsonDecode(
    File('test/fixtures/squat_form_parity.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final cases = fixture['cases'] as List<dynamic>;

  test('feature order matches the Python feature extractor', () {
    expect(FormFeatures.names, fixture['features']);
  });

  group('parity with the Python model', () {
    for (final (i, c) in cases.indexed) {
      final expectedFeatures = c['features'] as List<dynamic>?;
      final expectedProbs = c['probabilities'] as List<dynamic>?;

      test('case $i', () {
        final lms = _landmarks(c['landmarks'] as List<dynamic>);
        final features = FormFeatures.of(lms);
        if (expectedFeatures == null) {
          expect(features, isNull);
          expect(SquatFormClassifier.predict(lms), isNull);
          return;
        }
        expect(features, hasLength(expectedFeatures.length));
        for (var j = 0; j < features!.length; j++) {
          expect(
            features[j],
            closeTo((expectedFeatures[j] as num).toDouble(), 1e-3),
            reason: FormFeatures.names[j],
          );
        }
        // fromFeatures, not predict: the random poses do not all clear the
        // likelihood gate, and the gate is tested on its own below.
        final p = SquatFormClassifier.fromFeatures(features).probabilities;
        for (var k = 0; k < p.length; k++) {
          expect(p[k], closeTo((expectedProbs![k] as num).toDouble(), 1e-4));
        }
      });
    }
  });

  group('on hand-built poses', () {
    // Side-on squat bottom, facing right, image y growing downward.
    List<PoseLandmark> squat({double heelY = 780, double shoulderX = 500,
            double earX = 520, double earY = 250}) =>
        [
          lm(PoseLandmarkType.leftEar, earX, earY),
          lm(PoseLandmarkType.leftShoulder, shoulderX, 300),
          lm(PoseLandmarkType.leftHip, 450, 520),
          lm(PoseLandmarkType.leftKnee, 600, 560),
          lm(PoseLandmarkType.leftAnkle, 560, 760),
          lm(PoseLandmarkType.leftHeel, 530, heelY),
          lm(PoseLandmarkType.leftFootIndex, 640, 785),
        ];

    test('probabilities sum to one', () {
      final p = SquatFormClassifier.predict(poseOf(squat()).landmarks)!;
      expect(p.probabilities.fold(0.0, (a, b) => a + b), closeTo(1, 1e-9));
    });

    test('raising the heel moves the verdict toward bad heel', () {
      final flat = SquatFormClassifier.predict(poseOf(squat()).landmarks)!;
      final lifted =
          SquatFormClassifier.predict(poseOf(squat(heelY: 730)).landmarks)!;
      expect(
        lifted.probabilityOf(SquatFormClass.badHeel),
        greaterThan(flat.probabilityOf(SquatFormClass.badHeel)),
      );
    });

    test('mirroring the pose does not change the verdict', () {
      final right = squat();
      final left = [for (final l in right) lm(l.type, 1000 - l.x, l.y)];
      final a = SquatFormClassifier.predict(poseOf(right).landmarks)!;
      final b = SquatFormClassifier.predict(poseOf(left).landmarks)!;
      for (var k = 0; k < 3; k++) {
        expect(b.probabilities[k], closeTo(a.probabilities[k], 1e-9));
      }
    });

    test('scaling the pose does not change the verdict', () {
      final near = squat();
      final far = [for (final l in near) lm(l.type, l.x / 2, l.y / 2)];
      final a = SquatFormClassifier.predict(poseOf(near).landmarks)!;
      final b = SquatFormClassifier.predict(poseOf(far).landmarks)!;
      for (var k = 0; k < 3; k++) {
        expect(b.probabilities[k], closeTo(a.probabilities[k], 1e-9));
      }
    });

    test('refuses to judge feet it can only guess at', () {
      // Feet slipping off the bottom of the frame: ML Kit still places them,
      // at likelihoods around 0.6–0.75, and the positions are noise.
      final guessedFeet = [
        for (final l in squat())
          l.type == PoseLandmarkType.leftHeel ||
                  l.type == PoseLandmarkType.leftFootIndex
              ? lm(l.type, l.x, l.y, likelihood: 0.7)
              : l,
      ];
      expect(FormFeatures.of(poseOf(guessedFeet).landmarks), isNotNull);
      expect(SquatFormClassifier.predict(poseOf(guessedFeet).landmarks), isNull);
    });

    test('refuses a pose with no side tracked', () {
      final blurry = [
        for (final l in squat()) lm(l.type, l.x, l.y, likelihood: 0.3),
      ];
      expect(SquatFormClassifier.predict(poseOf(blurry).landmarks), isNull);
    });
  });
}
