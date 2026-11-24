import 'package:ai_fitness_coach/features/progress/history_grouping.dart';
import 'package:ai_fitness_coach/shared/models/session_data.dart';
import 'package:flutter_test/flutter_test.dart';

SessionData _session(String id, DateTime completedAt) => SessionData(
  id: id,
  workoutId: 'squats',
  workoutName: 'Squats',
  completedAt: completedAt,
  durationSeconds: 300,
  totalReps: 20,
  avgFormScore: 80,
  estimatedCalories: 40,
  mostCommonError: '',
  exercises: const [],
);

void main() {
  // Tuesday 24 Nov 2026, mid-afternoon.
  final now = DateTime(2026, 11, 24, 15, 30);

  group('historyDayLabel', () {
    test('today and yesterday read as words', () {
      expect(historyDayLabel(DateTime(2026, 11, 24), now), 'TODAY');
      expect(historyDayLabel(DateTime(2026, 11, 24, 23, 59), now), 'TODAY');
      expect(historyDayLabel(DateTime(2026, 11, 23), now), 'YESTERDAY');
    });

    test('older days in this year read weekday day month', () {
      expect(historyDayLabel(DateTime(2026, 11, 22), now), 'SUN 22 NOV');
      expect(historyDayLabel(DateTime(2026, 1, 5), now), 'MON 5 JAN');
    });

    test('days in another year carry the year', () {
      expect(historyDayLabel(DateTime(2025, 11, 18), now), 'TUE 18 NOV 2025');
    });

    test('yesterday crosses month and year boundaries', () {
      expect(
        historyDayLabel(DateTime(2026, 2, 28), DateTime(2026, 3, 1, 0, 5)),
        'YESTERDAY',
      );
      expect(
        historyDayLabel(DateTime(2025, 12, 31, 23, 59), DateTime(2026, 1, 1)),
        'YESTERDAY',
      );
    });
  });

  group('buildHistoryItems', () {
    test('empty history gives no items', () {
      expect(buildHistoryItems(const [], now: now), isEmpty);
    });

    test('groups by local day with a header before each day', () {
      final items = buildHistoryItems([
        _session('a', DateTime(2026, 11, 24, 9)),
        _session('b', DateTime(2026, 11, 24, 0, 0)),
        _session('c', DateTime(2026, 11, 23, 23, 59)),
        _session('d', DateTime(2026, 11, 20, 12)),
      ], now: now);

      expect(items.map(_describe), [
        'TODAY',
        'a',
        'b',
        'YESTERDAY',
        'c',
        'FRI 20 NOV',
        'd',
      ]);
      expect((items.first as HistoryDayHeader).day, DateTime(2026, 11, 24));
    });

    test('orders newest first whatever the input order', () {
      final items = buildHistoryItems([
        _session('old', DateTime(2026, 11, 1, 8)),
        _session('morning', DateTime(2026, 11, 24, 7)),
        _session('evening', DateTime(2026, 11, 24, 19)),
        _session('mid', DateTime(2026, 11, 10, 12)),
      ], now: now);

      expect(items.map(_describe), [
        'TODAY',
        'evening',
        'morning',
        'TUE 10 NOV',
        'mid',
        'SUN 1 NOV',
        'old',
      ]);
    });

    test('a single session gives one header and one row', () {
      final items = buildHistoryItems([
        _session('only', DateTime(2025, 6, 2, 10)),
      ], now: now);
      expect(items.map(_describe), ['MON 2 JUN 2025', 'only']);
    });
  });
}

String _describe(HistoryItem item) => switch (item) {
  HistoryDayHeader(:final label) => label,
  HistorySessionItem(:final session) => session.id,
};
