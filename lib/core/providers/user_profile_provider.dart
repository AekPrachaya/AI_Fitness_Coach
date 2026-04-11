import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/models/user_profile.dart';
import '../utils/mock_data.dart';

/// Provides the current [UserProfile] by reading from Hive.
///
/// Falls back to [MockData.getDefaultUserProfile()] when data is missing.
/// After writing new values to Hive (e.g. via [completeOnboarding] or
/// Settings), call `ref.invalidate(userProfileProvider)` to refresh.
final userProfileProvider = Provider<UserProfile>((ref) {
  final box = Hive.box(MockData.boxUserProfile);

  final name = box.get('name') as String? ?? 'Athlete';
  final email = box.get('logged_in_email') as String? ?? '';
  final age = box.get('age') as int? ?? 25;
  final gender = box.get('gender') as String? ?? 'prefer_not_to_say';
  final heightCm = (box.get('height_cm') as num?)?.toDouble() ?? 170.0;
  final weightKg = (box.get('weight_kg') as num?)?.toDouble() ?? 70.0;
  final fitnessGoal =
      box.get('fitness_goal') as String? ?? 'build_muscle';
  final fitnessLevel =
      box.get('fitness_level') as String? ?? 'beginner';
  final equipment = List<String>.from(
    box.get('equipment', defaultValue: <String>['no_equipment']) as List,
  );
  final joinedAtStr = box.get('joined_at') as String?;
  final joinedAt =
      joinedAtStr != null ? DateTime.parse(joinedAtStr) : DateTime.now();

  return UserProfile(
    name: name,
    email: email,
    age: age,
    gender: gender,
    heightCm: heightCm,
    weightKg: weightKg,
    fitnessGoal: fitnessGoal,
    fitnessLevel: fitnessLevel,
    equipment: equipment,
    joinedAt: joinedAt,
  );
});

/// Convenience — just the display name.
final userNameProvider = Provider<String>((ref) {
  return ref.watch(userProfileProvider).name;
});

/// Convenience — fitness level string for workout filtering.
final userFitnessLevelProvider = Provider<String>((ref) {
  return ref.watch(userProfileProvider).fitnessLevel;
});

/// Convenience — equipment list for workout filtering.
final userEquipmentProvider = Provider<List<String>>((ref) {
  return ref.watch(userProfileProvider).equipment;
});
