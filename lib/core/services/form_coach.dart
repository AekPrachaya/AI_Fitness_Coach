import 'exercise_analyzer.dart';
import 'form_fault.dart';

/// One line of coaching, as it should appear on screen right now.
class FormCue {
  const FormCue({
    required this.message,
    required this.score,
    this.fault,
    this.alert = false,
  });

  /// What the user reads: a correction for [fault], or praise when there is
  /// nothing to correct.
  final String message;

  final FormScore score;

  /// The fault being corrected. Null for praise.
  final FormFault? fault;

  /// True on the single frame this cue is raised, and again each time it is
  /// repeated after a lull. The session uses it to fire a haptic buzz — the
  /// user is looking at their own knees, not at the phone, so a cue that only
  /// exists on screen is a cue they will not see.
  final bool alert;

  FormCue get silenced => alert
      ? FormCue(message: message, score: score, fault: fault)
      : this;

  @override
  bool operator ==(Object other) =>
      other is FormCue &&
      other.message == message &&
      other.score == score &&
      other.fault == fault &&
      other.alert == alert;

  @override
  int get hashCode => Object.hash(message, score, fault, alert);
}

/// Turns the analyzer's per-frame verdict into coaching a human can follow.
///
/// The analyzers grade every frame, roughly thirty times a second, and that
/// raw stream is unusable as feedback for three reasons this class fixes:
///
/// * **It flickers.** A landmark wobbling across a threshold raises and drops
///   a fault within a few frames. A cue is only raised after the same fault
///   survives [confirmFrames] frames in a row, so a single bad estimate never
///   reaches the user.
/// * **It vanishes before it is read.** The frame that fixes the fault also
///   clears the warning, which in practice means the warning was on screen for
///   a tenth of a second. A raised cue is held for at least [minHold].
/// * **It nags.** Repeating the same correction thirty times a second buzzes
///   the phone into uselessness. A fault that stays uncorrected is re-alerted
///   only once per [repeatAfter].
class FormCoach {
  FormCoach({
    this.confirmFrames = 3,
    this.minHold = const Duration(milliseconds: 1500),
    this.repeatAfter = const Duration(seconds: 4),
  });

  /// Consecutive frames a fault must hold before the user hears about it.
  final int confirmFrames;

  /// How long a cue stays on screen after it is raised, even once the fault
  /// is gone — long enough to be read and acted on.
  final Duration minHold;

  /// Quiet period before an uncorrected fault alerts again.
  final Duration repeatAfter;

  FormCue? _cue;
  DateTime? _raisedAt;
  FormFault? _candidate;
  int _candidateFrames = 0;
  final Map<FormFault, DateTime> _lastAlert = {};

  /// The cue that should be on screen, or null for none.
  FormCue? get cue => _cue;

  /// Folds one graded frame in and returns the cue to display.
  ///
  /// Pass [FormResult.notEvaluated] for frames with nothing to grade — the
  /// body out of frame, or a joint between reps. Those do not clear a cue
  /// that has not yet had its [minHold]; a user who stands up the instant a
  /// warning appears still gets to read it.
  ///
  /// [at] exists for tests; it defaults to now.
  FormCue? update(FormResult result, {DateTime? at}) {
    final now = at ?? DateTime.now();
    final top = result.topFault;

    if (top == null) {
      _candidate = null;
      _candidateFrames = 0;
    } else if (top == _candidate) {
      _candidateFrames++;
    } else {
      _candidate = top;
      _candidateFrames = 1;
    }

    if (top != null && _candidateFrames >= _framesToConfirm(top)) {
      final isNewCue = _cue?.fault != top;
      final lastAlert = _lastAlert[top];
      final alert = isNewCue ||
          lastAlert == null ||
          now.difference(lastAlert) >= repeatAfter;

      if (alert) _lastAlert[top] = now;
      if (isNewCue) _raisedAt = now;

      return _cue = FormCue(
        message: top.cue,
        score: result.score,
        fault: top,
        alert: alert,
      );
    }

    // Nothing confirmed this frame. A correction already on screen keeps its
    // place until it has been readable for [minHold], but never re-alerts.
    final shown = _cue;
    final raisedAt = _raisedAt;
    if (shown?.fault != null &&
        raisedAt != null &&
        now.difference(raisedAt) < minHold) {
      return _cue = shown!.silenced;
    }

    _raisedAt = null;
    if (result.isClean) {
      return _cue = const FormCue(
        message: FormResult.praise,
        score: FormScore.good,
      );
    }
    return _cue = null;
  }

  /// How many frames this fault has to survive before the user hears it.
  ///
  /// [confirmFrames] exists to outlast a landmark wobbling across a threshold,
  /// which is a hazard of judging a position frame by frame. A range-of-motion
  /// fault is not judged that way: it is one measurement taken at the bottom
  /// of the rep, exists for exactly that frame, and waiting for it to repeat
  /// would mean never reporting it at all.
  int _framesToConfirm(FormFault fault) =>
      fault.timing == FaultTiming.rangeOfMotion ? 1 : confirmFrames;

  /// Drops everything, including the repeat cooldowns. For a new set, or a
  /// session coming back from pause: the first fault after a break is worth
  /// alerting on again even if it is the same one that ended the last set.
  void reset() {
    _cue = null;
    _raisedAt = null;
    _candidate = null;
    _candidateFrames = 0;
    _lastAlert.clear();
  }
}
