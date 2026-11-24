import 'package:ai_fitness_coach/features/profile/profile_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('known ids map to their onboarding labels', () {
    expect(
      optionLabel(genderOptions, 'prefer_not_to_say'),
      'Prefer not to say',
    );
    expect(optionLabel(goalOptions, 'build_muscle'), 'Build Muscle');
    expect(optionLabel(levelOptions, 'advanced'), 'Advanced');
  });

  test('unknown ids fall back to title case', () {
    expect(optionLabel(goalOptions, 'run_a_marathon'), 'Run A Marathon');
  });

  test('equipment summary', () {
    expect(equipmentSummary(const []), 'None');
    expect(
      equipmentSummary(const ['dumbbells', 'barbell']),
      'Dumbbells, Barbell & Plates',
    );
  });
}
