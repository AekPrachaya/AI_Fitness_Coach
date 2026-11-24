// ─────────────────────────────────────────────────────────────────────────────
// Option ids and labels for the profile editors.
//
// DUPLICATED from onboarding (personal_info_screen.dart, fitness_goal_screen,
// fitness_level_screen, equipment_screen.dart), whose lists are private to
// those screens. The ids are what Hive stores, so a change on one side must be
// mirrored on the other.
// ─────────────────────────────────────────────────────────────────────────────

class ProfileOption {
  const ProfileOption(this.id, this.label);
  final String id;
  final String label;
}

const genderOptions = [
  ProfileOption('male', 'Male'),
  ProfileOption('female', 'Female'),
  ProfileOption('prefer_not_to_say', 'Prefer not to say'),
];

const goalOptions = [
  ProfileOption('lose_weight', 'Lose Weight'),
  ProfileOption('build_muscle', 'Build Muscle'),
  ProfileOption('improve_flexibility', 'Improve Flexibility'),
  ProfileOption('boost_endurance', 'Boost Endurance'),
];

const levelOptions = [
  ProfileOption('beginner', 'Beginner'),
  ProfileOption('intermediate', 'Intermediate'),
  ProfileOption('advanced', 'Advanced'),
];

const equipmentOptions = [
  ProfileOption('no_equipment', 'No Equipment'),
  ProfileOption('dumbbells', 'Dumbbells'),
  ProfileOption('barbell', 'Barbell & Plates'),
  ProfileOption('resistance_bands', 'Resistance Bands'),
  ProfileOption('pull_up_bar', 'Pull-up Bar'),
  ProfileOption('bench', 'Bench'),
  ProfileOption('kettlebell', 'Kettlebell'),
];

/// The label for [id], or a title-cased fallback for ids no list knows.
String optionLabel(List<ProfileOption> options, String id) {
  for (final o in options) {
    if (o.id == id) return o.label;
  }
  return id
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// `Dumbbells, Bench` — or `None` for an empty list.
String equipmentSummary(List<String> ids) => ids.isEmpty
    ? 'None'
    : ids.map((id) => optionLabel(equipmentOptions, id)).join(', ');
