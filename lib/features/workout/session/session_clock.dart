/// Tracks how long a session has actually been running.
///
/// Time spent paused is excluded: backgrounding the app pauses the session, so
/// a wall-clock reading would count a lunch break as exercise and inflate the
/// calorie estimate built on it. Rest between sets still counts — the user is
/// in the workout.
class SessionClock {
  SessionClock({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  DateTime? _startedAt;
  DateTime? _pausedAt;
  Duration _paused = Duration.zero;

  /// Starts the clock. Later calls are ignored, so a camera that re-initialises
  /// mid-session does not reset the elapsed time.
  void start() => _startedAt ??= _now();

  void pause() {
    if (_startedAt != null && _pausedAt == null) _pausedAt = _now();
  }

  void resume() {
    final pausedAt = _pausedAt;
    if (pausedAt == null) return;
    _paused += _now().difference(pausedAt);
    _pausedAt = null;
  }

  /// Seconds of active session so far. Zero until [start] is called.
  int get elapsedSeconds {
    final started = _startedAt;
    if (started == null) return 0;

    var paused = _paused;
    final pausedAt = _pausedAt;
    if (pausedAt != null) paused += _now().difference(pausedAt);

    final elapsed = _now().difference(started) - paused;
    return elapsed.isNegative ? 0 : elapsed.inSeconds;
  }
}
