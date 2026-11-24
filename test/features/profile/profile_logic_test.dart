import 'package:ai_fitness_coach/core/theme/app_colors.dart';
import 'package:ai_fitness_coach/features/profile/profile_logic.dart';
import 'package:ai_fitness_coach/shared/models/session_data.dart';
import 'package:flutter_test/flutter_test.dart';

SessionData _session({int seconds = 600, double score = 80}) => SessionData(
  id: 'x',
  workoutId: 'squats',
  workoutName: 'Squats',
  completedAt: DateTime(2026, 11, 1),
  durationSeconds: seconds,
  totalReps: 10,
  avgFormScore: score,
  estimatedCalories: 5,
  mostCommonError: '',
  exercises: const [],
);

void main() {
  group('profileStats', () {
    test('empty history shows zeros and a dash for form', () {
      final stats = profileStats(const []);
      expect(stats.workouts, 0);
      expect(stats.totalTimeLabel, '0M');
      expect(stats.avgFormScore, isNull);
      expect(stats.avgFormLabel, '--');
    });

    test('counts sessions, sums time and averages form', () {
      final stats = profileStats([
        _session(seconds: 600, score: 90),
        _session(seconds: 900, score: 81),
      ]);
      expect(stats.workouts, 2);
      expect(stats.totalSeconds, 1500);
      expect(stats.totalTimeLabel, '25M');
      expect(stats.avgFormScore, closeTo(85.5, 1e-9));
      expect(stats.avgFormLabel, '86%');
    });

    test('total time switches to whole hours from 60 minutes', () {
      expect(profileStats([_session(seconds: 3599)]).totalTimeLabel, '59M');
      expect(profileStats([_session(seconds: 3600)]).totalTimeLabel, '1H');
      expect(
        profileStats(List.filled(50, _session(seconds: 3000))).totalTimeLabel,
        '41H',
      );
    });
  });

  group('bmiCategory', () {
    test('follows the WHO bands', () {
      expect(bmiCategory(18.4), BmiCategory.under);
      expect(bmiCategory(18.5), BmiCategory.normal);
      expect(bmiCategory(24.9), BmiCategory.normal);
      expect(bmiCategory(25), BmiCategory.over);
      expect(bmiCategory(29.9), BmiCategory.over);
      expect(bmiCategory(30), BmiCategory.obese);
    });

    test('labels and colours', () {
      expect(BmiCategory.under.label, 'UNDER');
      expect(BmiCategory.under.color, AppColors.warning);
      expect(BmiCategory.normal.color, AppColors.scoreGood);
      expect(BmiCategory.over.color, AppColors.warning);
      expect(BmiCategory.obese.color, AppColors.error);
    });
  });

  group('NumberRule', () {
    test('age accepts whole numbers in 13–100', () {
      const rule = NumberRule.age;
      expect(rule.validate('13'), isNull);
      expect(rule.validate(' 100 '), isNull);
      expect(rule.validate('12'), isNotNull);
      expect(rule.validate('101'), isNotNull);
      expect(rule.validate('25.5'), 'Whole numbers only');
      expect(rule.validate(''), 'Enter a value');
      expect(rule.validate('abc'), isNotNull);
      expect(rule.parse('42'), 42);
    });

    test('height accepts 100–250 cm', () {
      const rule = NumberRule.heightCm;
      expect(rule.validate('100'), isNull);
      expect(rule.validate('250'), isNull);
      expect(rule.validate('99'), 'Between 100 and 250 cm');
      expect(rule.validate('251'), isNotNull);
    });

    test('weight accepts 30–250 kg with one decimal', () {
      const rule = NumberRule.weightKg;
      expect(rule.validate('70'), isNull);
      expect(rule.validate('70.5'), isNull);
      expect(rule.validate('70,5'), isNull);
      expect(rule.parse('70,5'), 70.5);
      expect(rule.validate('70.55'), 'Enter a number');
      expect(rule.validate('29.9'), isNotNull);
      expect(rule.validate('250.1'), isNotNull);
      expect(rule.validate('-50'), isNotNull);
    });
  });

  group('validateName', () {
    test('rejects blank and overlong names', () {
      expect(validateName('Pat'), isNull);
      expect(validateName('   '), isNotNull);
      expect(validateName('a' * maxNameLength), isNull);
      expect(validateName('a' * (maxNameLength + 1)), isNotNull);
    });
  });

  group('toggleEquipment', () {
    test('adds and removes an item', () {
      expect(toggleEquipment([], 'dumbbells'), ['dumbbells']);
      expect(toggleEquipment(['dumbbells', 'bench'], 'dumbbells'), ['bench']);
    });

    test('no_equipment clears everything else', () {
      expect(toggleEquipment(['dumbbells', 'bench'], noEquipmentId), [
        noEquipmentId,
      ]);
    });

    test('picking an item clears no_equipment', () {
      expect(toggleEquipment([noEquipmentId], 'bench'), ['bench']);
    });

    test('does not mutate the input', () {
      final input = ['bench'];
      toggleEquipment(input, 'dumbbells');
      expect(input, ['bench']);
    });
  });
}
