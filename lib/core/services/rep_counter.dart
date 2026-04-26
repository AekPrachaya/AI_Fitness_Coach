enum _RepPhase { waitingDown, down }

class RepCounter {
  static const double _downThreshold = 100.0;
  static const double _upThreshold = 160.0;

  _RepPhase _phase = _RepPhase.waitingDown;
  int _count = 0;

  int get count => _count;

  /// Feed a knee angle per frame. Returns true when a rep is completed.
  bool update(double kneeAngle) {
    switch (_phase) {
      case _RepPhase.waitingDown:
        if (kneeAngle < _downThreshold) {
          _phase = _RepPhase.down;
        }
        return false;
      case _RepPhase.down:
        if (kneeAngle > _upThreshold) {
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
