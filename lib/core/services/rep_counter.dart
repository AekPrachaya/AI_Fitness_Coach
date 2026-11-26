enum _RepPhase { waitingDown, down }

class RepCounter {
  RepCounter({
    this.downThreshold = 100.0,
    this.upThreshold = 160.0,
    this.hysteresis = 8.0,
    this.framesBelowToArm = 2,
  });

  final double downThreshold;
  final double upThreshold;
  // Dead-band around each threshold — angle must cross by this many degrees
  // before the phase changes, preventing jitter from counting false reps.
  final double hysteresis;

  /// Consecutive frames the angle must spend below the down line before the
  /// rep counts as having gone down.
  ///
  /// One wild frame was enough to count a rep: a participant setting up her
  /// phone, shirt filling the lens, read as a 7° knee for a single frame and
  /// banked a squat she never did. Across 90 real reps from two recording
  /// rounds the shortest stay below the line was 13 frames. Two rejects the
  /// one-frame glitch and, replayed at 27, 15, 10 and even 5 fps, lost no
  /// real rep; three already lost reps at 5 fps.
  final int framesBelowToArm;

  int _framesBelow = 0;

  _RepPhase _phase = _RepPhase.waitingDown;
  int _count = 0;

  int get count => _count;

  bool update(double angle) {
    switch (_phase) {
      case _RepPhase.waitingDown:
        _framesBelow = angle < downThreshold - hysteresis ? _framesBelow + 1 : 0;
        if (_framesBelow >= framesBelowToArm) {
          _phase = _RepPhase.down;
          _framesBelow = 0;
        }
        return false;
      case _RepPhase.down:
        if (angle > upThreshold + hysteresis) {
          _count++;
          _phase = _RepPhase.waitingDown;
          return true;
        }
        return false;
    }
  }

  /// Throws away the rep in progress, keeping the tally.
  ///
  /// A rep is only counted on the way back up, so a half-finished one leaves
  /// the counter waiting for an angle above [upThreshold] — and anything that
  /// interrupts the session mid-rep hands it exactly that. Squat down, take a
  /// phone call, come back standing, and the first frame of the recovery
  /// completes a rep nobody performed, banking a form grade with it.
  ///
  /// Only for an interruption the user has actually noticed: a loss that has
  /// outlasted the tracking grace period, or a pause. Abandoning on every
  /// dropped frame would be the worse bug, because detection drops constantly
  /// — a hand crossing a knee is enough — and legitimate reps would stop
  /// counting.
  void abandonRep() {
    _phase = _RepPhase.waitingDown;
    _framesBelow = 0;
  }

  void reset() {
    _count = 0;
    _phase = _RepPhase.waitingDown;
    _framesBelow = 0;
  }
}
