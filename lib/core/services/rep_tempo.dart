/// How long one rep took on the way down and on the way back up.
class RepTempo {
  const RepTempo({required this.descent, required this.ascent});

  /// From leaving the top of the movement to its lowest point.
  final Duration descent;

  /// From the lowest point back to the top.
  final Duration ascent;

  double get descentSeconds => descent.inMicroseconds / 1e6;
  double get ascentSeconds => ascent.inMicroseconds / 1e6;
}

/// Times each rep from the joint angle, frame by frame.
///
/// The top of the movement is the same line the rep counter waits for
/// ([top], the analyzer's upThreshold). A rep's descent runs from the last
/// frame above it to the lowest angle that follows; its ascent from that low
/// point to the first frame back above it. Timing off the lowest *frame*
/// rather than a smoothed curve is good enough here: replaying recorded reps
/// at 5 fps moved the measured bottom by under 3°, because people slow down
/// as they reach it.
///
/// Display only, for now. On 49 recorded reps the descent took a median of
/// 0.75 s (0.44–1.77 s) — much quicker than the 2–3 s strength coaching
/// recommends — so a "slow down" cue at any defensible threshold would fire
/// on most ordinary reps. Until there is evidence for a line, the app shows
/// the tempo and leaves the judgement to the user.
class TempoTracker {
  TempoTracker({required this.top});

  final double top;

  DateTime? _leftTop;
  DateTime? _lowAt;
  double? _low;
  RepTempo? _completed;

  void update(double angle, DateTime at) {
    if (angle > top) {
      final leftTop = _leftTop, lowAt = _lowAt;
      if (leftTop != null && lowAt != null) {
        _completed = RepTempo(
          descent: lowAt.difference(leftTop),
          ascent: at.difference(lowAt),
        );
      }
      // Still at the top: the descent starts from the latest frame up here.
      _leftTop = at;
      _lowAt = null;
      _low = null;
      return;
    }
    if (_leftTop == null) return; // never seen the top: no start to time from
    if (_low == null || angle < _low!) {
      _low = angle;
      _lowAt = at;
    }
  }

  /// The most recent rep to return to the top, handed over once.
  RepTempo? takeCompleted() {
    final t = _completed;
    _completed = null;
    return t;
  }

  /// Forgets the rep in progress — for a lost body or a pause, after which
  /// the next descent has to start from a fresh top.
  void reset() {
    _leftTop = null;
    _lowAt = null;
    _low = null;
    _completed = null;
  }
}
