/// Which way the joint being measured is currently travelling.
enum MovementPhase { descending, ascending, still }

/// Follows the measured joint angle so the session knows where in a rep it is.
///
/// Form checks need this because a joint angle on its own is ambiguous: 110°
/// at the knee means "still on the way down" or "did not go deep enough"
/// depending entirely on which direction the user is moving, and the angle
/// cannot say which.
class MovementTracker {
  MovementTracker({this.noiseFloor = 1.5, this.riseToTurn = 5.0});

  /// Degrees of change to ignore before calling the movement a direction.
  ///
  /// Landmark estimates wobble by a degree or two while the user holds still,
  /// and without a floor that wobble reads as a stream of direction changes —
  /// every one of which would look like the bottom of a rep.
  final double noiseFloor;

  /// How far the angle has to climb back above the lowest point of a descent
  /// before the descent counts as over.
  ///
  /// Wobble does not stop while the user is moving either. Taken against the
  /// previous frame alone, a two-degree flicker on the way down read as the
  /// bottom of the rep, and the session told users who were still descending
  /// to squat deeper: on recorded footage, 4 of 23 reps that went below 90°
  /// were logged as shallow. Measured from the low point instead, 3° still
  /// let 2 through and 5° none, without missing any rep that really stopped
  /// short.
  final double riseToTurn;

  double? _last;
  double? _low;
  double? _bottomAngle;
  MovementPhase _phase = MovementPhase.still;
  bool _bottomedOut = false;

  MovementPhase get phase => _phase;

  /// True on the one frame where a descent turned into an ascent — the moment,
  /// and the only moment, at which how deep this rep went is a settled fact.
  bool get bottomedOut => _bottomedOut;

  /// The lowest angle of the descent that just turned, set when
  /// [bottomedOut] is. Depth is judged against this rather than the current
  /// angle, which by then is already [riseToTurn] degrees on the way back up.
  double? get bottomAngle => _bottomAngle;

  void update(double angle) {
    _bottomedOut = false;

    final last = _last;
    if (last == null) {
      _last = angle;
      return;
    }

    if (_phase == MovementPhase.descending) {
      final low = angle < _low! ? angle : _low!;
      _low = low;
      if (angle - low >= riseToTurn) {
        _bottomedOut = true;
        _bottomAngle = low;
        _phase = MovementPhase.ascending;
        _last = angle;
      }
      return;
    }

    final delta = angle - last;
    if (delta.abs() < noiseFloor) return; // held still; keep the phase we had

    _last = angle;
    if (delta < 0) {
      _phase = MovementPhase.descending;
      _low = angle;
    } else {
      _phase = MovementPhase.ascending;
    }
  }

  /// Starts over, forgetting which way the joint was going.
  void reset() {
    _last = null;
    _low = null;
    _bottomAngle = null;
    _phase = MovementPhase.still;
    _bottomedOut = false;
  }
}
