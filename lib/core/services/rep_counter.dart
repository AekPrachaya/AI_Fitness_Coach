enum _RepPhase { waitingDown, down }

class RepCounter {
  RepCounter({this.downThreshold = 100.0, this.upThreshold = 160.0});

  final double downThreshold;
  final double upThreshold;

  _RepPhase _phase = _RepPhase.waitingDown;
  int _count = 0;

  int get count => _count;

  /// Feed a joint angle per frame. Returns true when a rep is completed.
  bool update(double angle) {
    switch (_phase) {
      case _RepPhase.waitingDown:
        if (angle < downThreshold) _phase = _RepPhase.down;
        return false;
      case _RepPhase.down:
        if (angle > upThreshold) {
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
