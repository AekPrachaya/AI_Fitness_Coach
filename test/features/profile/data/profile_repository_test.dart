import 'dart:io';

import 'package:ai_fitness_coach/core/providers/user_profile_provider.dart';
import 'package:ai_fitness_coach/core/utils/mock_data.dart';
import 'package:ai_fitness_coach/features/profile/data/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_profile_test');
    Hive.init(dir.path);
    await Hive.openBox(MockData.boxUserProfile);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('edits read back through userProfileProvider', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final repo = container.read(profileRepositoryProvider);

    await repo.setName('  Pat  ');
    await repo.setAge(31);
    await repo.setGender('female');
    await repo.setHeightCm(180);
    await repo.setWeightKg(72.5);
    await repo.setFitnessGoal('boost_endurance');
    await repo.setFitnessLevel('advanced');
    await repo.setEquipment(['dumbbells', 'bench']);
    container.invalidate(userProfileProvider);

    final p = container.read(userProfileProvider);
    expect(p.name, 'Pat');
    expect(p.age, 31);
    expect(p.gender, 'female');
    expect(p.heightCm, 180);
    expect(p.weightKg, 72.5);
    expect(p.fitnessGoal, 'boost_endurance');
    expect(p.fitnessLevel, 'advanced');
    expect(p.equipment, ['dumbbells', 'bench']);
  });
}
