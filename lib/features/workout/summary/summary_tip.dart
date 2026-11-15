import '../../../core/services/form_fault.dart';
import '../../../shared/models/session_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The coaching line on the summary screen. There is no AI backend, so the tip
// is chosen on-device, most specific source first:
//
//   1. a tip stored with the session (the seeded demo rows carry one),
//   2. the correction cue for the fault the user made most often,
//   3. a line keyed to the overall form score.
// ─────────────────────────────────────────────────────────────────────────────

class SummaryTip {
  const SummaryTip({required this.message, this.focus});

  /// The fault the tip is about, as named in the stored history — or null
  /// when the tip is general.
  final String? focus;

  final String message;
}

/// Maps a workout id to the prefix its faults carry in [FormFault]'s names,
/// so a label shared by two exercises resolves to the right cue.
const _faultPrefixByWorkout = {
  'squats': 'squat',
  'push_ups': 'pushUp',
  'deadlifts': 'deadlift',
  'bicep_curls': 'curl',
};

SummaryTip summaryTipFor(SessionData session) {
  if (session.aiTip.isNotEmpty) return SummaryTip(message: session.aiTip);

  final fault = _faultFor(session.mostCommonError, session.workoutId);
  if (fault != null) {
    return SummaryTip(focus: fault.label, message: fault.cue);
  }

  return SummaryTip(message: _scoreLine(session.avgFormScore));
}

/// The [FormFault] whose label is [label]. Labels are not unique across
/// exercises ('ลงไม่ลึกพอ' is both a squat and a push-up fault), so the one
/// belonging to [workoutId] wins; any match is better than none.
FormFault? _faultFor(String label, String workoutId) {
  if (label.isEmpty) return null;
  final matches = FormFault.values.where((f) => f.label == label).toList();
  if (matches.isEmpty) return null;

  final prefix = _faultPrefixByWorkout[workoutId];
  if (prefix != null) {
    for (final fault in matches) {
      if (fault.name.startsWith(prefix)) return fault;
    }
  }
  return matches.first;
}

/// Tiers match `FormScoreBadge` and `AppColors.formScoreColor`. Zero means no
/// rep was graded at all, which is not the same as a poor workout.
String _scoreLine(double score) {
  if (score <= 0) {
    return 'ครั้งนี้ยังวัดฟอร์มไม่ได้ ลองยืนให้กล้องเห็นทั้งตัวในครั้งหน้า';
  }
  if (score >= 85) {
    return 'ฟอร์มดีมาก! ครั้งหน้าลองเพิ่มจำนวน rep หรือเซ็ตดู';
  }
  if (score >= 70) {
    return 'ฟอร์มใช้ได้ดี ลองทำช้าลงอีกนิดเพื่อคุมท่าให้นิ่งขึ้น';
  }
  return 'ลดความเร็วและจำนวน rep ลงก่อน แล้วเน้นทำท่าให้ถูกต้อง';
}
