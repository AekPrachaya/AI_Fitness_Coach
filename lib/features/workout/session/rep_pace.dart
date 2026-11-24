import 'workout_session_notifier.dart';

/// Times each rep for the HUD's REP TIME readout, from the session's own
/// state changes — the rep counter keeps no clock of its own.
///
/// A rep is timed from the previous counted rep, or from the moment counting
/// (re)started. Pauses, rests and tracking losses drop the start mark, so time
/// spent not exercising never lands on a rep; the notifier throws away the
/// half-done rep in those cases anyway.
class RepPace {
  DateTime? _since;
  int _lastCount = 0;
  Duration? _lastRep;

  /// How long the most recent rep took, or null before the first rep of the
  /// current set.
  Duration? get lastRep => _lastRep;

  /// Feeds one state change. Call it on every change, in order.
  void update({
    required SessionStatus status,
    required int repCount,
    required DateTime now,
  }) {
    // Counted before the status is looked at: the last rep of a set arrives
    // in the same change that moves the session to setComplete.
    if (repCount > _lastCount) {
      final since = _since;
      if (since != null) _lastRep = now.difference(since);
      _since = now;
    } else if (repCount < _lastCount) {
      _lastRep = null; // a new set began
    }
    _lastCount = repCount;

    switch (status) {
      case SessionStatus.tracking:
      case SessionStatus.repComplete:
        _since ??= now;
      case SessionStatus.paused:
      case SessionStatus.resting:
      case SessionStatus.error:
      case SessionStatus.setComplete:
      case SessionStatus.finished:
        _since = null;
      case SessionStatus.idle:
      case SessionStatus.initializing:
        break;
    }
  }
}
