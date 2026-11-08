enum _RepPhase { waitingDown, down }

class RepCounter {
  RepCounter({
    this.downThreshold = 100.0,
    this.upThreshold = 160.0,
    this.hysteresis = 8.0,
  });

  final double downThreshold;
  final double upThreshold;
  // Dead-band around each threshold — angle must cross by this many degrees
  // before the phase changes, preventing jitter from counting false reps.
  final double hysteresis;

  _RepPhase _phase = _RepPhase.waitingDown;
  int _count = 0;

  int get count => _count;

  bool update(double angle) {
    switch (_phase) {
      case _RepPhase.waitingDown:
        if (angle < downThreshold - hysteresis) _phase = _RepPhase.down;
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
  void abandonRep() => _phase = _RepPhase.waitingDown;

  void reset() {
    _count = 0;
    _phase = _RepPhase.waitingDown;
  }
}
