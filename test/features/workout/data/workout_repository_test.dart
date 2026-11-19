import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ai_fitness_coach/core/utils/mock_data.dart';
import 'package:ai_fitness_coach/features/workout/data/workout_repository.dart';

Map<String, dynamic> _session(String id, DateTime at, {int reps = 10}) => {
      'id': id,
      'workout_id': 'squats',
      'workout_name': 'Squats',
      'completed_at': at.toIso8601String(),
      'duration_seconds': 60,
      'total_reps': reps,
      'avg_form_score': 80.0,
      'estimated_calories': 5,
      'most_common_error': '',
      'ai_tip': '',
      'exercises': const [],
    };

void main() {
  late Directory dir;
  late WorkoutRepository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_repo_test');
    Hive.init(dir.path);
    await Hive.openBox(MockData.boxSessionHistory);
    await Hive.openBox(MockData.boxUserProfile);
    repo = WorkoutRepository();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  Future<void> seedDemo() => Hive.box(MockData.boxSessionHistory).put(
        'sessions',
        [_session('mock_session_1', DateTime(2026, 1, 1))],
      );

  test('a saved session reads back', () async {
    expect(await repo.saveSession(_session('1', DateTime(2026, 11, 1))), isTrue);
    final all = repo.getAllSessions();
    expect(all, hasLength(1));
    expect(all.single.totalReps, 10);
  });

  test('sessions come back newest first', () async {
    await repo.saveSession(_session('old', DateTime(2026, 11, 1)));
    await repo.saveSession(_session('new', DateTime(2026, 11, 2), reps: 7));
    expect(repo.getAllSessions().first.totalReps, 7);
  });

  test('demo history stays out unless it is switched on', () async {
    // Merged by default it would pass a year of made-up workouts off as the
    // user's own on Home and Progress.
    await seedDemo();
    await repo.saveSession(_session('1', DateTime(2026, 11, 1)));
    expect(repo.showDemoHistory, isFalse);
    expect(repo.getAllSessions(), hasLength(1));

    await repo.setShowDemoHistory(true);
    expect(repo.getAllSessions(), hasLength(2));
  });

  test('clearing removes recorded sessions and keeps the demo history',
      () async {
    await seedDemo();
    await repo.setShowDemoHistory(true);
    await repo.saveSession(_session('1', DateTime(2026, 11, 1)));
    await repo.saveSession(_session('2', DateTime(2026, 11, 2)));

    expect(await repo.clearRecordedSessions(), 2);
    expect(repo.getRealSessions(), isEmpty);
    expect(repo.getAllSessions(), hasLength(1));
  });

  test('a failed write reports false instead of throwing', () async {
    await Hive.box(MockData.boxSessionHistory).close();
    expect(await repo.saveSession(_session('1', DateTime(2026, 11, 1))),
        isFalse);
  });
}
