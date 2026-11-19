import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ai_fitness_coach/core/services/landmark_smoother.dart';

Pose _knee(double x, double y) => Pose(landmarks: {
      PoseLandmarkType.leftKnee: PoseLandmark(
        type: PoseLandmarkType.leftKnee,
        x: x,
        y: y,
        z: 0,
        likelihood: 0.9,
      ),
    });

void main() {
  final t0 = DateTime(2026, 11, 19);
  DateTime at(int frame) => t0.add(Duration(milliseconds: 50 * frame));
  double xOf(Pose p) => p.landmarks[PoseLandmarkType.leftKnee]!.x;

  test('the first frame passes through unchanged', () {
    final s = LandmarkSmoother();
    expect(xOf(s.smooth(_knee(100, 200), at(0))), 100);
  });

  test('steadies a joint that is only jittering', () {
    // A still knee whose estimate wobbles ±4 px frame to frame.
    final s = LandmarkSmoother();
    final out = <double>[];
    for (var i = 0; i < 40; i++) {
      out.add(xOf(s.smooth(_knee(i.isEven ? 104 : 96, 200), at(i))));
    }
    final settled = out.skip(10);
    final spread = settled.reduce((a, b) => a > b ? a : b) -
        settled.reduce((a, b) => a < b ? a : b);
    expect(spread, lessThan(4), reason: 'raw spread is 8 px');
  });

  test('keeps up with a fast movement', () {
    // 30 px per frame, a quick squat: the drawn joint may trail, but not by
    // a whole frame's travel once the movement is under way.
    final s = LandmarkSmoother();
    late double drawn;
    for (var i = 0; i < 15; i++) {
      drawn = xOf(s.smooth(_knee(100.0 + 30 * i, 200), at(i)));
    }
    expect(100.0 + 30 * 14 - drawn, lessThan(30));
  });

  test('keeps every other landmark field', () {
    final s = LandmarkSmoother();
    final lm = s.smooth(_knee(10, 20), at(0)).landmarks[PoseLandmarkType.leftKnee]!;
    expect(lm.type, PoseLandmarkType.leftKnee);
    expect(lm.likelihood, 0.9);
  });

  test('reset forgets where the body was', () {
    final s = LandmarkSmoother();
    for (var i = 0; i < 10; i++) {
      s.smooth(_knee(100, 200), at(i));
    }
    s.reset();
    expect(xOf(s.smooth(_knee(400, 200), at(11))), 400);
  });
}
