import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/utils/mock_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingState
// Accumulates data across all 5 onboarding steps. All values are stored in
// SI units (cm, kg) regardless of the display unit the user selected.
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class OnboardingState {
  const OnboardingState({
    // ── Step 1 — Personal Info ─────────────────────────────────────────────
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.heightInFeet = false,
    this.weightInLbs = false,
    // ── Steps 2–5 stub fields (filled by Tasks 2.4–2.6) ───────────────────
    this.fitnessGoal,
    this.fitnessLevel,
    this.equipment = const [],
    this.cameraGranted = false,
  });

  final int? age;
  final String? gender; // 'male' | 'female' | 'prefer_not_to_say'
  final double? heightCm;
  final double? weightKg;
  final bool heightInFeet;
  final bool weightInLbs;

  final String? fitnessGoal; // Task 2.4
  final String? fitnessLevel; // Task 2.5
  final List<String> equipment; // Task 2.5
  final bool cameraGranted; // Task 2.6

  // ── Computed ──────────────────────────────────────────────────────────────

  double? get bmi {
    if (heightCm == null || weightKg == null) return null;
    final h = heightCm! / 100;
    return weightKg! / (h * h);
  }

  String? get bmiCategory {
    final b = bmi;
    if (b == null) return null;
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  bool get step1Complete =>
      age != null && gender != null && heightCm != null && weightKg != null;

  bool get step2Complete => fitnessGoal != null;

  bool get step3Complete => fitnessLevel != null;

  bool get step4Complete => true; // equipment is optional

  bool get step5Complete => true; // camera is optional — user can skip

  OnboardingState copyWith({
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    bool? heightInFeet,
    bool? weightInLbs,
    String? fitnessGoal,
    String? fitnessLevel,
    List<String>? equipment,
    bool? cameraGranted,
  }) {
    return OnboardingState(
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      heightInFeet: heightInFeet ?? this.heightInFeet,
      weightInLbs: weightInLbs ?? this.weightInLbs,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      equipment: equipment ?? this.equipment,
      cameraGranted: cameraGranted ?? this.cameraGranted,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingNotifier
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  // ── Step 1 setters ────────────────────────────────────────────────────────

  void setAge(int age) => state = state.copyWith(age: age);

  void setGender(String gender) => state = state.copyWith(gender: gender);

  void setHeightCm(double cm) => state = state.copyWith(heightCm: cm);

  void setHeightFt(double totalInches) =>
      state = state.copyWith(heightCm: _inchesToCm(totalInches));

  void toggleHeightUnit() =>
      state = state.copyWith(heightInFeet: !state.heightInFeet);

  void setWeightKg(double kg) => state = state.copyWith(weightKg: kg);

  void setWeightLbs(double lbs) =>
      state = state.copyWith(weightKg: _lbsToKg(lbs));

  void toggleWeightUnit() =>
      state = state.copyWith(weightInLbs: !state.weightInLbs);

  // ── Step 2 setters ────────────────────────────────────────────────────────

  void setFitnessGoal(String goal) =>
      state = state.copyWith(fitnessGoal: goal);

  // ── Step 3 setters ────────────────────────────────────────────────────────

  void setFitnessLevel(String level) =>
      state = state.copyWith(fitnessLevel: level);

  // ── Step 4 setters ────────────────────────────────────────────────────────

  void toggleEquipment(String item) {
    final current = List<String>.from(state.equipment);
    if (current.contains(item)) {
      current.remove(item);
    } else {
      if (item == 'no_equipment') {
        current.clear();
      } else {
        current.remove('no_equipment');
      }
      current.add(item);
    }
    state = state.copyWith(equipment: current);
  }

  void clearEquipment() => state = state.copyWith(equipment: []);

  // ── Step 5 setters ────────────────────────────────────────────────────────

  void setCameraGranted(bool granted) =>
      state = state.copyWith(cameraGranted: granted);

  /// Saves all collected onboarding data to Hive and marks onboarding as done.
  Future<void> completeOnboarding() async {
    final box = Hive.box(MockData.boxUserProfile);
    await box.put('age', state.age);
    await box.put('gender', state.gender);
    await box.put('height_cm', state.heightCm);
    await box.put('weight_kg', state.weightKg);
    await box.put('fitness_goal', state.fitnessGoal);
    await box.put('fitness_level', state.fitnessLevel);
    await box.put('equipment', state.equipment);
    await box.put('camera_granted', state.cameraGranted);
    await box.put('joined_at', DateTime.now().toIso8601String());
    await box.put(MockData.prefOnboardingComplete, true);
  }

  /// Reloads saved onboarding data from Hive (used by Settings screen).
  void loadFromHive() {
    final box = Hive.box(MockData.boxUserProfile);
    state = OnboardingState(
      age: box.get('age') as int?,
      gender: box.get('gender') as String?,
      heightCm: (box.get('height_cm') as num?)?.toDouble(),
      weightKg: (box.get('weight_kg') as num?)?.toDouble(),
      fitnessGoal: box.get('fitness_goal') as String?,
      fitnessLevel: box.get('fitness_level') as String?,
      equipment: List<String>.from(
        box.get('equipment', defaultValue: <String>[]) as List,
      ),
      cameraGranted:
          box.get('camera_granted', defaultValue: false) as bool,
    );
  }

  // ── Unit conversion helpers ───────────────────────────────────────────────

  double _inchesToCm(double inches) => inches * 2.54;
  // ignore: unused_element
  double _cmToInches(double cm) => cm / 2.54;
  double _lbsToKg(double lbs) => lbs * 0.453592;
  // ignore: unused_element
  double _kgToLbs(double kg) => kg / 0.453592;
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(),
);
