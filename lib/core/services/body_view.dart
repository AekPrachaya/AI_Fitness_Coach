import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_analyzer.dart';

/// Where the camera is standing relative to the user.
enum ViewAngle {
  /// Beside the user, looking at their profile. What the form checks need.
  side,

  /// In front of or behind the user, looking at their chest or back. For a
  /// push-up, down the length of their body.
  front,

  /// Not enough of the body is confidently tracked to say.
  unknown,
}

/// Works out which way the user is facing the camera.
///
/// This matters because almost every form check measures a *horizontal*
/// distance in the image and reads it as forward lean: the shoulder ahead of
/// the hip, the knee ahead of the ankle, the hip off the shoulder-knee line.
/// Those readings only mean what they claim when the camera is beside the
/// user. Facing the camera, a deeply rounded back projects to a shoulder
/// almost directly above the hip — so the check measures nothing, finds no
/// fault, and the session congratulates the user on a position that could
/// hurt them. Silence would be better than that, and a correction better
/// still.
abstract final class BodyView {
  /// Largest shoulder-separation-to-torso ratio still read as a side view.
  ///
  /// The two shoulders are separated along the body's own left-right axis.
  /// Side-on, that axis points at the camera and collapses to nearly nothing
  /// in the image; face-on it lies across the image at full width. Dividing
  /// by torso length makes the measure independent of how far away the user
  /// stands and of how big they are.
  ///
  /// Adult shoulder breadth runs about 38-42cm against a 45-55cm trunk, so a
  /// square-on view lands near 0.8 and a profile near zero. Rotation scales
  /// the width by its cosine, which puts this limit around 25-30° off a true
  /// profile — within which the horizontal measurements keep about 90% of
  /// their real magnitude. Checked against 15 recorded squat videos: profiles
  /// measured 0.06-0.34, front and three-quarter views 0.44-0.80.
  static const sideMaxRatio = 0.35;

  /// Reads the view from [lms].
  ///
  /// [standingTorso] is the torso length measured at the top of the movement
  /// (see [torsoLength]); the larger of it and this frame's torso is used as
  /// the divisor. The trunk shortens in the image as the user folds forward —
  /// by about a third at the bottom of a squat — while shoulder width barely
  /// moves, so dividing by the current frame alone pushed a side view over
  /// the limit at the bottom of every rep and the session stopped counting
  /// exactly where the rep is decided. Taking the larger length errs toward
  /// [ViewAngle.side], the direction that costs the user nothing.
  static ViewAngle of(
    Map<PoseLandmarkType, PoseLandmark> lms, {
    double? standingTorso,
  }) {
    final left = lms[PoseLandmarkType.leftShoulder];
    final right = lms[PoseLandmarkType.rightShoulder];

    // Both shoulders have to be trustworthy, and in a true profile the far
    // one usually is not — which is why an unreadable view is never reported
    // as [front]. The check only ever fires when the body is confidently
    // square to the camera, so uncertainty costs the user nothing.
    if (left == null ||
        right == null ||
        left.likelihood <= ExerciseAnalyzer.minLikelihood ||
        right.likelihood <= ExerciseAnalyzer.minLikelihood) {
      return ViewAngle.unknown;
    }

    final current = torsoLength(lms);
    if (current == null) return ViewAngle.unknown;
    final divisor = math.max(current, standingTorso ?? 0);
    final ratio = _distance(left, right) / divisor;
    return ratio <= sideMaxRatio ? ViewAngle.side : ViewAngle.front;
  }

  /// Shoulder-to-hip length in the image, or null when it cannot be measured.
  ///
  /// Taken off whichever side is tracked better, rather than from both hips,
  /// so one occluded hip does not blind the whole check.
  static double? torsoLength(Map<PoseLandmarkType, PoseLandmark> lms) {
    final torso = ExerciseAnalyzer.bestSide(
      lms,
      const [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      const [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    );
    if (torso case [final shoulder, final hip]) {
      final length = _distance(shoulder, hip);
      return length > 0 ? length : null;
    }
    return null;
  }

  static double _distance(PoseLandmark a, PoseLandmark b) =>
      math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
}
