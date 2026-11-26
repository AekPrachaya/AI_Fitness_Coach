import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Turns one pose into the feature vector the squat form model was trained on.
///
/// A line-for-line port of `tool/pose_eval/form_features.py`; the parity test
/// feeds both the same landmarks and expects the same numbers, so change the
/// two together or not at all.
///
/// * the better-tracked side, as [ExerciseAnalyzer.bestSide] picks it
/// * mirrored so the person always faces +x (the nose is ahead of the ear)
/// * hip at the origin, lengths in units of that side's shoulder→hip, so
///   camera distance and body size drop out
/// * the joint angles the rules use, plus a few they do not
///
/// No heel or toe: a phone propped high makes out-turned toes look lower
/// than the heel, and side-on the far foot is placed at random behind the
/// near one, so flat heels read as lifted. The shin and knee show a heel
/// lift too, and the model caught every one on held-out images without them.
abstract final class FormFeatures {
  static const minLikelihood = 0.65;

  /// Column order of [of]'s result. The model's weights are in this order.
  static const names = [
    'ear_x', 'ear_y', 'shoulder_x', 'shoulder_y',
    'knee_x', 'knee_y', 'ankle_x', 'ankle_y',
    'knee_deg', 'hip_deg', 'torso_deg', 'shin_deg', 'neck_deg', 'thigh_deg',
  ];

  static const _left = [
    PoseLandmarkType.leftEar, PoseLandmarkType.leftShoulder,
    PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee,
    PoseLandmarkType.leftAnkle,
  ];
  static const _right = [
    PoseLandmarkType.rightEar, PoseLandmarkType.rightShoulder,
    PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee,
    PoseLandmarkType.rightAnkle,
  ];

  /// Indices into [_left]/[_right] of the joints a side must track well:
  /// shoulder, hip, knee, ankle.
  static const _required = [1, 2, 3, 4];

  /// The feature vector, or null when neither side is tracked well enough to
  /// trust — the same frames the rule checks skip.
  static List<double>? of(Map<PoseLandmarkType, PoseLandmark> lms) {
    final side = _pickSide(lms);
    final nose = lms[PoseLandmarkType.nose];
    if (side == null || nose == null) return null;
    final p = [for (final t in side) lms[t]];
    if (p.any((l) => l == null)) return null;
    final ear = p[0]!, sh = p[1]!, hip = p[2]!, kn = p[3]!, an = p[4]!;

    final torso = _dist(sh.x, sh.y, hip.x, hip.y);
    if (torso < 1e-6) return null;
    final facing = nose.x >= ear.x ? 1.0 : -1.0;

    // (x, y) relative to the hip, mirrored and in torso lengths.
    (double, double) rel(PoseLandmark l) =>
        ((l.x - hip.x) * facing / torso, (l.y - hip.y) / torso);

    final e = rel(ear), s = rel(sh), k = rel(kn), a = rel(an);
    const o = (0.0, 0.0);

    final thigh = _deg(math.atan2(k.$2 - o.$2, _nz((k.$1 - o.$1).abs())));

    return [
      e.$1, e.$2, s.$1, s.$2, k.$1, k.$2, a.$1, a.$2,
      _angle(o, k, a),
      _angle(s, o, k),
      _fromVertical(s, o),
      _fromVertical(k, a),
      _angle(e, s, o),
      thigh,
    ];
  }

  /// Every joint [of] reads for the side it would use — nose, then ear to
  /// ankle — or null when neither side is tracked well enough.
  static List<PoseLandmarkType>? jointsUsed(
    Map<PoseLandmarkType, PoseLandmark> lms,
  ) {
    final side = _pickSide(lms);
    return side == null ? null : [PoseLandmarkType.nose, ...side];
  }

  static List<PoseLandmarkType>? _pickSide(
    Map<PoseLandmarkType, PoseLandmark> lms,
  ) {
    double score(List<PoseLandmarkType> side) => _required
        .map((i) => lms[side[i]]?.likelihood ?? 0)
        .reduce(math.min);
    final l = score(_left), r = score(_right);
    final okL = l > minLikelihood, okR = r > minLikelihood;
    if (!okL && !okR) return null;
    return okL && (!okR || l >= r) ? _left : _right;
  }

  /// Angle at b in degrees, as [ExerciseAnalyzer.calculateAngle] measures it.
  static double _angle((double, double) a, (double, double) b,
      (double, double) c) {
    final r = math.atan2(c.$2 - b.$2, c.$1 - b.$1) -
        math.atan2(a.$2 - b.$2, a.$1 - b.$1);
    final d = _deg(r).abs();
    return d > 180 ? 360 - d : d;
  }

  static double _fromVertical((double, double) top, (double, double) bottom) =>
      _deg(math.atan2((top.$1 - bottom.$1).abs(), (top.$2 - bottom.$2).abs()));

  static double _dist(double x1, double y1, double x2, double y2) =>
      math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));

  static double _deg(double rad) => rad * 180 / math.pi;

  /// Python's `abs(dx) or 1e-9`: never divide the direction by exactly zero.
  static double _nz(double v) => v == 0 ? 1e-9 : v;
}
