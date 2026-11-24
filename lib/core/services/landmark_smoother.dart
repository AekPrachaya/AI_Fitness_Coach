import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Smooths landmark positions for drawing the skeleton.
///
/// Detection lands about twenty times a second at uneven intervals, and each
/// estimate wobbles by a few pixels, so the overlay jitters and jumps on top
/// of a camera preview that is perfectly smooth. Each coordinate goes through
/// a One Euro filter (Casiez et al., CHI 2012): heavily smoothed while the
/// joint is still, lightly while it moves fast, so the skeleton steadies
/// without trailing behind a quick squat.
///
/// Display only. The form checks and rep counter keep reading the raw
/// landmarks — every threshold in them was measured on unsmoothed angles, and
/// a filter's lag would shift where a rep's bottom appears to be.
class LandmarkSmoother {
  LandmarkSmoother({
    this.minCutoff = 1.0,
    this.beta = 0.02,
    this.derivativeCutoff = 1.0,
  });

  /// Cutoff frequency (Hz) while a joint is still: lower is steadier.
  final double minCutoff;

  /// How much faster movement raises the cutoff: higher follows quick motion
  /// more closely, at the cost of letting more jitter through.
  final double beta;

  final double derivativeCutoff;

  final Map<PoseLandmarkType, _Filter2D> _filters = {};
  DateTime? _last;

  /// Returns [pose] with every landmark smoothed against the previous frames.
  Pose smooth(Pose pose, DateTime at) {
    final last = _last;
    _last = at;
    final dt = last == null
        ? null
        : math.max(at.difference(last).inMicroseconds / 1e6, 1e-3);

    final out = <PoseLandmarkType, PoseLandmark>{};
    pose.landmarks.forEach((type, lm) {
      final f = _filters.putIfAbsent(
        type,
        () => _Filter2D(minCutoff, beta, derivativeCutoff),
      );
      final (x, y) = f.filter(lm.x, lm.y, dt);
      out[type] = PoseLandmark(
        type: type,
        x: x,
        y: y,
        z: lm.z,
        likelihood: lm.likelihood,
      );
    });
    return Pose(landmarks: out);
  }

  /// Forgets the history, so a body that comes back somewhere else is drawn
  /// where it is rather than sliding over from where it was.
  void reset() {
    _filters.clear();
    _last = null;
  }
}

class _Filter2D {
  _Filter2D(double minCutoff, double beta, double dCutoff)
      : _x = _OneEuro(minCutoff, beta, dCutoff),
        _y = _OneEuro(minCutoff, beta, dCutoff);

  final _OneEuro _x;
  final _OneEuro _y;

  (double, double) filter(double x, double y, double? dt) =>
      (_x.filter(x, dt), _y.filter(y, dt));
}

class _OneEuro {
  _OneEuro(this.minCutoff, this.beta, this.dCutoff);

  final double minCutoff;
  final double beta;
  final double dCutoff;

  double? _value;
  double _derivative = 0;

  static double _alpha(double cutoff, double dt) {
    final tau = 1 / (2 * math.pi * cutoff);
    return 1 / (1 + tau / dt);
  }

  double filter(double raw, double? dt) {
    final prev = _value;
    if (prev == null || dt == null) {
      _value = raw;
      return raw;
    }
    final d = (raw - prev) / dt;
    _derivative += _alpha(dCutoff, dt) * (d - _derivative);
    final cutoff = minCutoff + beta * _derivative.abs();
    final value = prev + _alpha(cutoff, dt) * (raw - prev);
    _value = value;
    return value;
  }
}
