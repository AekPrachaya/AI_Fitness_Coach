/// How badly one fault needs correcting — the axis the session HUD ranks by.
enum FormSeverity {
  /// Costs range of motion or makes the rep easier than intended, but will
  /// not hurt anyone. Worth a nudge.
  minor,

  /// Loads a joint or the spine in a position it should not be loaded in.
  /// Shown ahead of anything minor, and graded [FormScore.poor] on its own.
  risky,
}

/// When in a rep a fault can honestly be judged.
enum FaultTiming {
  /// Judgeable on any frame, because the body either is or is not in the
  /// position right now — a rounded back is wrong while it is rounded.
  posture,

  /// Judgeable only once the movement has bottomed out.
  ///
  /// Depth is the example: at a knee angle of 110° on the way *down* the user
  /// is not shallow, they are mid-descent, and warning them then is both
  /// wrong and maddening. The same reading on the way *up* describes a rep
  /// that is already over. Only the turnaround says how deep they went.
  rangeOfMotion,
}

/// A form fault the analyzers can detect, paired with the one line the user
/// is shown to fix it.
///
/// The two strings are deliberately different jobs:
///
/// * [cue] goes on screen mid-rep. It is an instruction, not a diagnosis —
///   someone glancing at it for half a second between reps has to know what
///   to do with their body, so it names the correction ("ดันสะโพกไปข้างหลัง")
///   and never the symptom. Kept under roughly 24 Thai characters so it fits
///   one line of the banner without wrapping.
/// * [label] goes in the session summary afterwards, where naming the fault
///   reads better than ordering the user around — "เข่าเลยปลายเท้า ×4".
///
/// Faults are declared most-important-first within each exercise; that order
/// breaks ties between faults of equal [severity] when the HUD picks which
/// single cue to show.
enum FormFault {
  // ── Squat ─────────────────────────────────────────────────────────────────
  squatTorsoLean(
    label: 'หลังเอนไปข้างหน้า',
    cue: 'ยืดอกขึ้น อย่าโน้มตัว',
    severity: FormSeverity.risky,
  ),
  squatKneeOverToe(
    label: 'เข่าเลยปลายเท้า',
    cue: 'ดันสะโพกไปข้างหลัง',
    severity: FormSeverity.risky,
  ),
  squatShallow(
    label: 'ลงไม่ลึกพอ',
    cue: 'ย่อลงอีก ให้ต้นขาขนานพื้น',
    severity: FormSeverity.minor,
    timing: FaultTiming.rangeOfMotion,
  ),

  // ── Push-up ───────────────────────────────────────────────────────────────
  pushUpHipSag(
    label: 'สะโพกหย่อน',
    cue: 'เกร็งท้อง ยกสะโพกขึ้น',
    severity: FormSeverity.risky,
  ),
  pushUpHipPike(
    label: 'สะโพกยกสูง',
    cue: 'ลดสะโพกลง ให้ลำตัวตรง',
    severity: FormSeverity.minor,
  ),
  pushUpShallow(
    label: 'ลงไม่ลึกพอ',
    cue: 'ลดตัวลงให้ศอกงอ 90 องศา',
    severity: FormSeverity.minor,
    timing: FaultTiming.rangeOfMotion,
  ),

  // ── Deadlift ──────────────────────────────────────────────────────────────
  deadliftTorsoDrop(
    label: 'ก้มตัวต่ำเกินไป',
    cue: 'ยกอกขึ้น หลังตรง',
    severity: FormSeverity.risky,
  ),

  // ── Bicep curl ────────────────────────────────────────────────────────────
  curlBodySway(
    label: 'เหวี่ยงตัวช่วย',
    cue: 'ยืนนิ่ง อย่าเหวี่ยงตัว',
    severity: FormSeverity.minor,
  ),
  curlElbowDrift(
    label: 'ข้อศอกกางออก',
    cue: 'ล็อกศอกแนบลำตัว',
    severity: FormSeverity.minor,
  );

  const FormFault({
    required this.label,
    required this.cue,
    required this.severity,
    this.timing = FaultTiming.posture,
  });

  /// Names the fault. For the summary screen and the stored error tally.
  final String label;

  /// Tells the user what to change. For the live HUD.
  final String cue;

  final FormSeverity severity;

  final FaultTiming timing;

  /// Ranks [a] before [b] if it is the one the user should hear about first:
  /// risky faults ahead of minor ones, then declaration order.
  static int byPriority(FormFault a, FormFault b) {
    final bySeverity = b.severity.index.compareTo(a.severity.index);
    return bySeverity != 0 ? bySeverity : a.index.compareTo(b.index);
  }
}
