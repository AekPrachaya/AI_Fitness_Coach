import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ai_fitness_coach/core/services/body_view.dart';
import 'package:ai_fitness_coach/core/services/exercise_analyzer.dart';

import '../../support/pose_fixtures.dart';

void main() {
  /// Shoulders [width] apart with a [torso]-long trunk. [scale] multiplies
  /// every coordinate, standing in for the user moving nearer or further.
  Map<PoseLandmarkType, PoseLandmark> body({
    required double width,
    double torso = 150,
    double scale = 1,
    double shoulderLikelihood = 0.9,
  }) {
    final midX = 200 * scale;
    final shoulderY = 100 * scale;
    final hipY = shoulderY + torso * scale;
    final half = width * scale / 2;
    return {
      for (final l in [
        lm(PoseLandmarkType.leftShoulder, midX - half, shoulderY,
            likelihood: shoulderLikelihood),
        lm(PoseLandmarkType.rightShoulder, midX + half, shoulderY,
            likelihood: shoulderLikelihood),
        lm(PoseLandmarkType.leftHip, midX - half, hipY),
        lm(PoseLandmarkType.rightHip, midX + half, hipY),
      ])
        l.type: l,
    };
  }

  group('of', () {
    test('a profile reads as a side view', () {
      // Side-on, the body's left-right axis points at the camera and the two
      // shoulders land almost on top of each other.
      expect(BodyView.of(body(width: 10)), ViewAngle.side);
    });

    test('a body square to the camera reads as a front view', () {
      // 80 across a 150 trunk — roughly real adult proportions seen face-on.
      expect(BodyView.of(body(width: 80)), ViewAngle.front);
    });

    test('the limit itself counts as a side view', () {
      final onLimit = BodyView.sideMaxRatio * 150;
      expect(BodyView.of(body(width: onLimit)), ViewAngle.side);
      expect(BodyView.of(body(width: onLimit + 1)), ViewAngle.front);
    });

    test('the verdict does not change with distance from the camera', () {
      // The whole point of dividing by torso length: a user who steps back
      // shrinks in the frame without turning.
      for (final scale in [0.4, 1.0, 2.5]) {
        expect(BodyView.of(body(width: 10, scale: scale)), ViewAngle.side,
            reason: 'scale $scale');
        expect(BodyView.of(body(width: 80, scale: scale)), ViewAngle.front,
            reason: 'scale $scale');
      }
    });

    test('the verdict does not change with body size', () {
      // A broader user is also taller; the ratio is what carries the meaning.
      expect(BodyView.of(body(width: 100, torso: 190)), ViewAngle.front);
      expect(BodyView.of(body(width: 12, torso: 190)), ViewAngle.side);
    });
  });

  group('standing torso', () {
    // Numbers from a recorded side-on squat: the trunk measured 282px
    // standing and 193px at the bottom, shoulders 88px and 85px apart.
    test('a profile at the bottom of a squat still reads as a side view', () {
      final bottom = body(width: 85, torso: 193);
      expect(BodyView.of(bottom), ViewAngle.front,
          reason: 'the bug: the folded trunk alone pushes the ratio to 0.44');
      expect(BodyView.of(bottom, standingTorso: 282), ViewAngle.side);
    });

    test('a body square to the camera is still a front view', () {
      expect(BodyView.of(body(width: 80), standingTorso: 150), ViewAngle.front);
    });

    test('a stale shorter reference does not shrink the divisor', () {
      // The user stepped closer since the reference was taken: the trunk is
      // now longer than it, and the current frame must win.
      expect(BodyView.of(body(width: 10, scale: 2), standingTorso: 40),
          ViewAngle.side);
      expect(BodyView.of(body(width: 80, scale: 2), standingTorso: 40),
          ViewAngle.front);
    });

    test('a reference does not make an unreadable view readable', () {
      expect(
        BodyView.of(body(width: 80, shoulderLikelihood: 0.2),
            standingTorso: 150),
        ViewAngle.unknown,
      );
    });

    test('torsoLength measures shoulder to hip on the better side', () {
      expect(BodyView.torsoLength(body(width: 10, torso: 150)), 150);
      expect(BodyView.torsoLength(body(width: 10, torso: 0)), isNull);
      expect(BodyView.torsoLength(const {}), isNull);
    });
  });

  group('refusing to guess', () {
    test('an unreadable view is never reported as a front view', () {
      // This is the safety property the whole check rests on. Reporting
      // `front` stops the session, so it may only be said with confidence —
      // and in a true profile the far shoulder is often exactly what ML Kit
      // is least sure about.
      final verdicts = [
        BodyView.of(body(width: 80, shoulderLikelihood: 0.2)),
        BodyView.of(body(width: 80, shoulderLikelihood: 0.5)),
        BodyView.of(
          body(width: 80, shoulderLikelihood: ExerciseAnalyzer.minLikelihood),
        ),
      ];
      expect(verdicts, everyElement(ViewAngle.unknown));
    });

    test('one missing shoulder is unknown, not a side view', () {
      final lms = body(width: 80)..remove(PoseLandmarkType.rightShoulder);
      expect(BodyView.of(lms), ViewAngle.unknown);
    });

    test('no usable torso to measure against is unknown', () {
      final lms = body(width: 80)
        ..remove(PoseLandmarkType.leftHip)
        ..remove(PoseLandmarkType.rightHip);
      expect(BodyView.of(lms), ViewAngle.unknown);
    });

    test('a collapsed torso is unknown rather than a division by zero', () {
      expect(BodyView.of(body(width: 80, torso: 0)), ViewAngle.unknown);
    });

    test('an empty pose is unknown', () {
      expect(BodyView.of(const {}), ViewAngle.unknown);
    });

    test('falls back to the other side for the torso measurement', () {
      // Left hip occluded: the trunk is still measurable on the right, so the
      // check must not give up.
      final lms = body(width: 80);
      lms[PoseLandmarkType.leftHip] = lm(
        PoseLandmarkType.leftHip,
        lms[PoseLandmarkType.leftHip]!.x,
        lms[PoseLandmarkType.leftHip]!.y,
        likelihood: 0.1,
      );
      expect(BodyView.of(lms), ViewAngle.front);
    });
  });
}
