/// Why the current frame could not be used for rep counting.
enum TrackingLoss {
  /// ML Kit found no body at all — the user has stepped out of frame.
  noBody,

  /// A body is there, but the joints being measured are not confident enough
  /// to trust. Usually poor lighting, or the joint is hidden behind something.
  lowConfidence,
}

/// Decides when a run of unusable frames has lasted long enough to tell the
/// user about it.
///
/// Detection drops out constantly — a hand crossing a knee, a frame skipped
/// while the detector is busy — so surfacing the first bad frame would make
/// the session flicker between tracking and error. Loss has to persist past
/// [grace] before it counts.
class TrackingWatchdog {
  TrackingWatchdog({
    this.grace = const Duration(milliseconds: 1200),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration grace;
  final DateTime Function() _now;

  TrackingLoss? _loss;
  DateTime? _lostAt;

  /// Feeds one frame's outcome — [loss] is null when the joints were usable.
  ///
  /// Returns the loss once it has outlasted [grace] and for every frame after,
  /// so the caller can hold an error state. Returns null while tracking is
  /// healthy or the loss is still inside its grace period.
  TrackingLoss? observe(TrackingLoss? loss) {
    if (loss == null) {
      reset();
      return null;
    }
    // A different kind of loss restarts the clock: a body that vanishes after
    // a dim patch is a new problem with different advice.
    if (_loss != loss) {
      _loss = loss;
      _lostAt = _now();
      return null;
    }
    final lostAt = _lostAt;
    if (lostAt == null) return null;
    return _now().difference(lostAt) >= grace ? loss : null;
  }

  /// True once a loss has been surfaced and not yet recovered from.
  bool get isLost => _loss != null;

  void reset() {
    _loss = null;
    _lostAt = null;
  }
}
