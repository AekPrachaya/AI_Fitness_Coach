import 'dart:io';

import 'package:ai_fitness_coach/core/utils/mock_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory dir;
  late Box box;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_seed_test');
    Hive.init(dir.path);
    box = await Hive.openBox(MockData.boxSessionHistory);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  List<Map> demo() => List<Map>.from(box.get('sessions') as List);

  DateTime newest(List<Map> sessions) => sessions
      .map((s) => DateTime.parse(s['completed_at'] as String))
      .reduce((a, b) => a.isAfter(b) ? a : b);

  /// Today, or yesterday when today falls on the generator's rest day — so
  /// the current streak is still alive either way.
  bool isFresh(DateTime newest, DateTime today) {
    final day = DateTime(newest.year, newest.month, newest.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    return todayDate.difference(day).inDays <= 1 && !day.isAfter(todayDate);
  }

  test('the demo history runs up to the day it was seeded', () async {
    final day = DateTime(2026, 11, 15, 9);
    await MockData.seedProgressHistory(now: day);

    expect(isFresh(newest(demo()), day), isTrue);
    expect(box.get(MockData.seededOnKey), '2026-11-15');
  });

  test('a later day regenerates the history so it ends today', () async {
    await MockData.seedProgressHistory(now: DateTime(2026, 11, 15, 9));
    final demoDay = DateTime(2026, 12, 10, 9);
    await MockData.seedProgressHistory(now: demoDay);

    expect(isFresh(newest(demo()), demoDay), isTrue);
    expect(box.get(MockData.seededOnKey), '2026-12-10');
  });

  test('the same day does not regenerate', () async {
    await MockData.seedProgressHistory(now: DateTime(2026, 11, 15, 9));
    // A marker the generator would never write: it survives only if the
    // second call leaves the key alone.
    await box.put('sessions', [
      {'id': 'marker'},
    ]);
    await MockData.seedProgressHistory(now: DateTime(2026, 11, 15, 23, 59));

    expect(demo().single['id'], 'marker');
  });

  test('recorded sessions survive a regeneration', () async {
    await box.put('real_session_1', '{"id":"1"}');
    await MockData.seedProgressHistory(now: DateTime(2026, 11, 15, 9));
    await MockData.seedProgressHistory(now: DateTime(2026, 11, 16, 9));

    expect(box.get('real_session_1'), '{"id":"1"}');
  });

  test("each demo session's exercise reps match the session total", () async {
    await MockData.seedProgressHistory(now: DateTime(2026, 11, 15, 9));

    for (final s in demo()) {
      final exercise = (s['exercises'] as List).single as Map;
      expect(exercise['total_reps'], s['total_reps'], reason: '${s['id']}');
    }
  });
}
