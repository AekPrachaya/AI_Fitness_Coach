import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/utils/mock_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Writes profile edits to the `user_profile` box under the same keys
// onboarding uses, so `userProfileProvider` reads them back unchanged.
// Callers invalidate `userProfileProvider` after each write.
// ─────────────────────────────────────────────────────────────────────────────

class ProfileRepository {
  Box get _box => Hive.box(MockData.boxUserProfile);

  Future<void> setName(String name) => _box.put('name', name.trim());
  Future<void> setAge(int age) => _box.put('age', age);
  Future<void> setGender(String gender) => _box.put('gender', gender);
  Future<void> setHeightCm(double cm) => _box.put('height_cm', cm);
  Future<void> setWeightKg(double kg) => _box.put('weight_kg', kg);
  Future<void> setFitnessGoal(String goal) => _box.put('fitness_goal', goal);
  Future<void> setFitnessLevel(String level) =>
      _box.put('fitness_level', level);
  Future<void> setEquipment(List<String> ids) =>
      _box.put('equipment', List<String>.from(ids));
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);
