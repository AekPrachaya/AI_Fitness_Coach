import 'package:flutter/services.dart';
import 'exercise_analyzer.dart';
import 'form_coach.dart';

/// The half of a form warning that does not need the user to be looking at
/// the screen.
///
/// Mid-rep the phone is propped across the room and the user is watching
/// their own knees, so a correction that exists only as text on the preview
/// is a correction they find out about afterwards.
abstract interface class FormAlerts {
  /// Announces [cue], which the coach has just raised.
  void raise(FormCue cue);

  /// Cuts off anything still playing. For a pause, a finished set, or the end
  /// of a session: a correction for a rep that is already over is noise.
  void silence();

  void dispose();
}

class HapticFormAlerts implements FormAlerts {
  const HapticFormAlerts();

  @override
  void raise(FormCue cue) {
    switch (cue.score) {
      // A risky fault gets the buzz that is hard to miss, a sloppy one a
      // lighter nudge, so the body learns which is which without reading.
      case FormScore.poor:
        HapticFeedback.heavyImpact();
      case FormScore.fair:
        HapticFeedback.mediumImpact();
      case FormScore.good:
        break; // praise stays silent
    }
  }

  @override
  void silence() {}

  @override
  void dispose() {}
}

/// Fans one cue out to several channels — a buzz and a spoken line together.
class CombinedFormAlerts implements FormAlerts {
  const CombinedFormAlerts(this.channels);

  final List<FormAlerts> channels;

  @override
  void raise(FormCue cue) {
    for (final c in channels) {
      c.raise(cue);
    }
  }

  @override
  void silence() {
    for (final c in channels) {
      c.silence();
    }
  }

  @override
  void dispose() {
    for (final c in channels) {
      c.dispose();
    }
  }
}

/// For tests, and for a session the user has muted.
class SilentFormAlerts implements FormAlerts {
  const SilentFormAlerts();

  @override
  void raise(FormCue cue) {}

  @override
  void silence() {}

  @override
  void dispose() {}
}
