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

  void reset() {
    _count = 0;
    _phase = _RepPhase.waitingDown;
  }
}
