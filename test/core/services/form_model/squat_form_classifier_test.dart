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
    // Side-on squat bottoms, facing right, image y growing downward: the
    // median pose of each class in the training images, in pixels.
    List<PoseLandmark> body(List<(double, double)> p) => [
          lm(PoseLandmarkType.nose, p[0].$1 + 40, p[0].$2),
          for (final (i, t) in const [
            PoseLandmarkType.leftEar, PoseLandmarkType.leftShoulder,
            PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee,
            PoseLandmarkType.leftAnkle,
          ].indexed)
            lm(t, p[i].$1, p[i].$2),
        ];
    final good = body(const [
      (612, 255), (576, 334), (450, 520), (606, 547), (522, 696),
    ]);
    final bentOver = body(const [
      (714, 381), (647, 421), (450, 520), (621, 566), (556, 729),
    ]);
    final liftedHeels = body(const [
      (600, 260), (569, 329), (450, 520), (607, 553), (492, 681),
    ]);

    SquatFormPrediction predict(List<PoseLandmark> l) =>
        SquatFormClassifier.predict(poseOf(l).landmarks)!;

    test('probabilities sum to one', () {
      expect(predict(good).probabilities.fold(0.0, (a, b) => a + b),
          closeTo(1, 1e-9));
    });

    test('tells the three class medians apart', () {
      expect(predict(good).best, SquatFormClass.good);
      expect(predict(bentOver).best, SquatFormClass.badBack);
      expect(predict(liftedHeels).best, SquatFormClass.badHeel);
    });

    test('mirroring the pose does not change the verdict', () {
      final left = [for (final l in liftedHeels) lm(l.type, 1000 - l.x, l.y)];
      final a = predict(liftedHeels), b = predict(left);
      for (var k = 0; k < 3; k++) {
        expect(b.probabilities[k], closeTo(a.probabilities[k], 1e-9));
      }
    });

    test('scaling the pose does not change the verdict', () {
      final far = [for (final l in liftedHeels) lm(l.type, l.x / 2, l.y / 2)];
      final a = predict(liftedHeels), b = predict(far);
      for (var k = 0; k < 3; k++) {
        expect(b.probabilities[k], closeTo(a.probabilities[k], 1e-9));
      }
    });

    test('pays no attention to the feet', () {
      // Heel and toe are where a high camera and a hidden far foot mislead;
      // wherever they land, and however unsure ML Kit is of them, the
      // verdict must not move.
      final withFeet = [
        ...good,
        lm(PoseLandmarkType.leftHeel, 480, 600, likelihood: 0.3),
        lm(PoseLandmarkType.leftFootIndex, 700, 760, likelihood: 0.3),
      ];
      final a = predict(good), b = predict(withFeet);
      for (var k = 0; k < 3; k++) {
        expect(b.probabilities[k], a.probabilities[k]);
      }
    });

    test('refuses to judge a joint it can only guess at', () {
      final guessedAnkle = [
        for (final l in good)
          l.type == PoseLandmarkType.leftAnkle
              ? lm(l.type, l.x, l.y, likelihood: 0.7)
              : l,
      ];
      expect(FormFeatures.of(poseOf(guessedAnkle).landmarks), isNotNull);
      expect(SquatFormClassifier.predict(poseOf(guessedAnkle).landmarks),
          isNull);
    });

    test('refuses a pose with no side tracked', () {
      final blurry = [
        for (final l in good) lm(l.type, l.x, l.y, likelihood: 0.3),
      ];
      expect(SquatFormClassifier.predict(poseOf(blurry).landmarks), isNull);
    });
  });
}
