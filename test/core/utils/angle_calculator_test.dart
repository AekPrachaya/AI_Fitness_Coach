import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ai_fitness_coach/core/utils/angle_calculator.dart';

import '../../support/pose_fixtures.dart';

void main() {
  // Image coordinates: x grows right, y grows *down*.
  const hip = PoseLandmarkType.leftHip;
  const knee = PoseLandmarkType.leftKnee;
  const ankle = PoseLandmarkType.leftAnkle;

  test('a straight limb measures 180 degrees', () {
    final angle = calculateAngle(
      lm(hip, 100, 100),
      lm(knee, 100, 200),
      lm(ankle, 100, 300),
    );
    expect(angle, closeTo(180, 0.001));
  });

  test('a right angle measures 90 degrees', () {
    final angle = calculateAngle(
      lm(hip, 100, 100),
      lm(knee, 100, 200),
      lm(ankle, 200, 200),
    );
    expect(angle, closeTo(90, 0.001));
  });

  test('a fully folded limb measures 0 degrees', () {
    final angle = calculateAngle(
      lm(hip, 100, 100),
      lm(knee, 100, 200),
      lm(ankle, 100, 100),
    );
    expect(angle, closeTo(0, 0.001));
  });

  test('the result does not depend on which ray is given first', () {
    final a = lm(hip, 120, 80);
    final vertex = lm(knee, 100, 200);
    final c = lm(ankle, 210, 240);
    expect(
      calculateAngle(a, vertex, c),
      closeTo(calculateAngle(c, vertex, a), 0.001),
    );
  });

  test('reflex geometry is folded back into [0, 180]', () {
    // Sweeping the far point all the way around must never exceed 180.
    for (var deg = 0; deg < 360; deg += 15) {
      final radians = deg * math.pi / 180;
      final angle = calculateAngle(
        lm(hip, 100, 100),
        lm(knee, 100, 200),
        lm(ankle, 100 + 100 * math.cos(radians), 200 + 100 * math.sin(radians)),
      );
      expect(angle, inInclusiveRange(0, 180), reason: 'far point at $deg deg');
    }
  });
}
