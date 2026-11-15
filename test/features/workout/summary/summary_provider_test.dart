import 'package:ai_fitness_coach/features/workout/summary/summary_provider.dart';
import 'package:ai_fitness_coach/shared/models/session_data.dart';
import 'package:flutter_test/flutter_test.dart';

SessionData _session(String id, String workoutId, int day) => SessionData(
      id: id,
      workoutId: workoutId,
      workoutName: workoutId,
      completedAt: DateTime(2026, 11, day),
      durationSeconds: 60,
      totalReps: 10,
      avgFormScore: 80,
      estimatedCalories: 10,
      mostCommonError: '',
      exercises: const [],
    );

void main() {
  // Newest first, as sessionHistoryProvider hands them over.
  final history = [
    _session('c', 'push_ups', 15),
    _session('b', 'squats', 14),
    _session('a', 'squats', 13),
  ];

  test('without a session id picks the newest session for the workout', () {
    expect(pickSummarySession(history, workoutId: 'squats')?.id, 'b');
  });

  test('ignores sessions of other workouts', () {
    expect(pickSummarySession(history, workoutId: 'push_ups')?.id, 'c');
  });

  test('with a session id picks exactly that session', () {
    expect(
      pickSummarySession(history, workoutId: 'squats', sessionId: 'a')?.id,
      'a',
    );
  });

  test('is null when the workout has no sessions', () {
    expect(pickSummarySession(history, workoutId: 'deadlifts'), isNull);
  });

  test('is null when the session id is unknown', () {
    expect(
      pickSummarySession(history, workoutId: 'squats', sessionId: 'zzz'),
      isNull,
    );
  });

  test('is null for an empty history', () {
    expect(pickSummarySession(const [], workoutId: 'squats'), isNull);
  });
}
