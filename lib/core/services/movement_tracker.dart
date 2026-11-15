/// Which way the joint being measured is currently travelling.
enum MovementPhase { descending, ascending, still }

/// Follows the measured joint angle so the session knows where in a rep it is.
///
/// Form checks need this because a joint angle on its own is ambiguous: 110°
/// at the knee means "still on the way down" or "did not go deep enough"
/// depending entirely on which direction the user is moving, and the angle
/// cannot say which.
class MovementTracker {
  MovementTracker({this.noiseFloor = 1.5});

  /// Degrees of change to ignore before calling the movement a direction.
  ///
  /// Landmark estimates wobble by a degree or two while the user holds still,
  /// and without a floor that wobble reads as a stream of direction changes —
  /// every one of which would look like the bottom of a rep.
  final double noiseFloor;

  double? _last;
  MovementPhase _phase = MovementPhase.still;
  bool _bottomedOut = false;

  MovementPhase get phase => _phase;

  /// True on the one frame where a descent turned into an ascent — the moment,
  /// and the only moment, at which how deep this rep went is a settled fact.
  bool get bottomedOut => _bottomedOut;

  void update(double angle) {
    _bottomedOut = false;

    final last = _last;
    if (last == null) {
      _last = angle;
      return;
    }

    final delta = angle - last;
    if (delta.abs() < noiseFloor) return; // held still; keep the phase we had

    _last = angle;
    if (delta < 0) {
      _phase = MovementPhase.descending;
      return;
    }

    // Rising. A rise that follows a descent is the turnaround.
    if (_phase == MovementPhase.descending) _bottomedOut = true;
    _phase = MovementPhase.ascending;
  }

  /// Starts over, forgetting which way the joint was going.
  void reset() {
    _last = null;
    _phase = MovementPhase.still;
    _bottomedOut = false;
  }
}
