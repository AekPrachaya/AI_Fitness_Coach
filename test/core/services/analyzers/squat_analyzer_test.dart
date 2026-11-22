import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ai_fitness_coach/core/services/analyzers/squat_analyzer.dart';
import 'package:ai_fitness_coach/core/services/exercise_analyzer.dart';
import 'package:ai_fitness_coach/core/services/form_fault.dart';
import 'package:ai_fitness_coach/core/services/rep_counter.dart';

import '../../../support/pose_fixtures.dart';

void main() {
  late SquatAnalyzer analyzer;
  // The angle-rule path; the model path has its own group at the end.
  setUp(() => analyzer = SquatAnalyzer(useFormModel: false));

  // Vertical shin (knee directly above ankle) and vertical torso (shoulder
  // directly above hip) — the reference "clean squat" geometry.
  Pose stackedPose({
    double kneeX = 100,
    double ankleX = 100,
    double shoulderX = 100,
    double hipX = 100,
  }) =>
      poseOf(withMirroredSide([
        lm(PoseLandmarkType.leftShoulder, shoulderX, 50),
        lm(PoseLandmarkType.leftHip, hipX, 150),
        lm(PoseLandmarkType.leftKnee, kneeX, 200),
        lm(PoseLandmarkType.leftAnkle, ankleX, 300),
      ]));

  test('stays silent while the user is still standing', () {
    final result = analyzer.analyze(stackedPose(), 150);
    expect(result.score, FormScore.good);
    expect(result.feedback, isEmpty);
  });

  test('praises a deep squat with a vertical shin and torso', () {
    final result = analyzer.analyze(stackedPose(), 85);
    expect(result.score, FormScore.good);
    expect(result.feedback, FormResult.praise);
  });

  test('flags insufficient depth on its own as fair', () {
    final result = analyzer.analyze(stackedPose(), 110);
    expect(result.score, FormScore.fair);
    expect(result.topFault, FormFault.squatShallow);
    expect(result.feedback, FormFault.squatShallow.cue);
  });

  test('flags the knee travelling past the toes', () {
    // Knee 100px in front of the ankle over a 100px shin — a 45 degree shin,
    // past the 35 degree limit.
    final result = analyzer.analyze(stackedPose(kneeX: 200), 85);
    expect(result.topFault, FormFault.squatKneeOverToe);
    expect(result.feedback, FormFault.squatKneeOverToe.cue);
  });

  test('flags a shin a few degrees past the limit', () {
    // About 43°: a knee pushed forward by lifted heels.
    final result = analyzer.analyze(stackedPose(kneeX: 193), 85);
    expect(result.faults, contains(FormFault.squatKneeOverToe));
  });

  test('leaves the forward shin of a deep squat alone', () {
    // About 37°: what ML Kit read for a very deep squat with the heels down,
    // past the 35° the labelled images suggested.
    final result = analyzer.analyze(stackedPose(kneeX: 176), 85);
    expect(result.faults, isNot(contains(FormFault.squatKneeOverToe)));
  });

  test('flags an over-folded torso', () {
    // Shoulder 200px ahead of the hip over a 100px torso — about 63 degrees,
    // past the 55 degree limit.
    final result = analyzer.analyze(stackedPose(shoulderX: 300), 85);
    expect(result.topFault, FormFault.squatTorsoLean);
    expect(result.feedback, FormFault.squatTorsoLean.cue);
  });

  test('keeps every fault when they stack up but coaches the worst one', () {
    final result = analyzer.analyze(
      stackedPose(kneeX: 200, shoulderX: 300),
      110,
    );
    expect(result.score, FormScore.poor);
    expect(
      result.faults,
      containsAll([
        FormFault.squatShallow,
        FormFault.squatKneeOverToe,
        FormFault.squatTorsoLean,
      ]),
    );
    expect(result.feedback, FormFault.squatTorsoLean.cue);
  });

  test('skips the geometry checks when the body is not confidently tracked', () {
    final pose = poseOf([
      lm(PoseLandmarkType.leftShoulder, 300, 50, likelihood: 0.2),
      lm(PoseLandmarkType.leftHip, 100, 150, likelihood: 0.2),
      lm(PoseLandmarkType.leftKnee, 200, 200, likelihood: 0.2),
      lm(PoseLandmarkType.leftAnkle, 100, 300, likelihood: 0.2),
    ]);
    // Depth is angle-only so it still applies; the landmark-based checks must
    // not fire on untrustworthy points.
    final result = analyzer.analyze(pose, 85);
    expect(result.score, FormScore.good);
    expect(result.feedback, FormResult.praise);
  });

  test('exposes the rep thresholds the counter is built from', () {
    expect(analyzer.downThreshold, lessThan(analyzer.upThreshold));
    expect(analyzer.angleLabel, isNotEmpty);
  });

  group('rep thresholds against recorded footage', () {
    RepCounter counterFor(SquatAnalyzer a) => RepCounter(
          downThreshold: a.downThreshold,
          upThreshold: a.upThreshold,
          hysteresis: a.hysteresis,
        );

    test('counts a thighs-parallel squat that bottoms out near 98 degrees', () {
      // Knee angle of one real rep filmed side-on, every 4th frame at 30 fps.
      // The old 100° threshold needed the angle below 92 and missed it.
      const trace = [
        177, 177, 176, 174, 171, 165, 153, 144, 131, 124, 114, 105, 101, 98,
        100, 102, 102, 109, 118, 138, 165, 177, 179, 180, 180, 179, 179, 177,
      ];
      final counter = counterFor(analyzer);
      for (final angle in trace) {
        counter.update(angle.toDouble());
      }
      expect(counter.count, 1);
    });

    test('does not count a shallow dip', () {
      final counter = counterFor(analyzer);
      for (final angle in [175, 160, 140, 125, 140, 160, 175]) {
        counter.update(angle.toDouble());
      }
      expect(counter.count, 0);
    });
  });

  group('with the form model', () {
    final model = SquatAnalyzer(useFormModel: true);

    // Whole side-on bodies at the bottom of a squat, facing right: the
    // median pose of each class in the training images, in pixels. A heel
    // lift is more than a raised heel — the ankle rises and the foot sits
    // further back under the hip — and the model reads the whole shape.
    Pose body(List<(double, double)> p) => poseOf(withMirroredSide([
          for (final (i, t) in const [
            PoseLandmarkType.leftEar, PoseLandmarkType.leftShoulder,
            PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee,
            PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel,
            PoseLandmarkType.leftFootIndex,
          ].indexed)
            lm(t, p[i].$1, p[i].$2),
        ]));
    final good = body(const [(612, 254), (576, 333), (450, 520), (605, 547),
        (522, 696), (495, 725), (596, 725)]);
    final liftedHeels = body(const [(598, 259), (569, 329), (450, 520),
        (608, 554), (493, 682), (464, 698), (540, 736)]);

    test('still grades depth by rule', () {
      final result = model.analyze(good, 110);
      expect(result.faults, contains(FormFault.squatShallow));
    });

    test('stays silent while standing, like the rules', () {
      expect(model.analyze(good, 150), FormResult.notEvaluated);
    });

    test('passes a typical good squat', () {
      expect(model.analyze(good, 85).faults, isEmpty);
    });

    test('flags lifted heels', () {
      expect(model.analyze(liftedHeels, 85).faults, [FormFault.squatHeelLift]);
    });

    test('falls back to the rules when it cannot see the whole leg', () {
      // No ear, heel or toe: the model must not guess, but the rules need
      // only shoulder, hip, knee and ankle and still catch what they can.
      final result = model.analyze(stackedPose(kneeX: 200, shoulderX: 300), 85);
      expect(result.faults,
          containsAll([FormFault.squatTorsoLean, FormFault.squatKneeOverToe]));
      expect(result.faults, isNot(contains(FormFault.squatHeelLift)));
    });

    test('does not call heels lifted when the feet are only guessed', () {
      final guessed = Pose(landmarks: {
        for (final e in liftedHeels.landmarks.entries)
          e.key: switch (e.key) {
            PoseLandmarkType.leftHeel ||
            PoseLandmarkType.rightHeel ||
            PoseLandmarkType.leftFootIndex ||
            PoseLandmarkType.rightFootIndex =>
              lm(e.key, e.value.x, e.value.y, likelihood: 0.7),
            _ => e.value,
          },
      });
      expect(model.analyze(guessed, 85).faults,
          isNot(contains(FormFault.squatHeelLift)));
    });

    test('never raises the knee-over-toe rule it replaces', () {
      for (final pose in [good, liftedHeels]) {
        expect(model.analyze(pose, 85).faults,
            isNot(contains(FormFault.squatKneeOverToe)));
      }
    });
  });
}
