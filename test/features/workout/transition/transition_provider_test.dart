import 'package:ai_fitness_coach/features/workout/transition/transition_provider.dart';
import 'package:ai_fitness_coach/shared/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Workout _w(String id) => Workout(
  id: id,
  name: id,
  muscleGroup: 'full_body',
  difficulty: 'beginner',
  defaultSets: 3,
  defaultReps: 10,
  durationMinutes: 10,
  description: '',
  instructions: const [],
  commonMistakes: const [],
  muscleGroupTags: const [],
);

void main() {
  final all = [_w('push_ups'), _w('squats'), _w('deadlifts')];

  test('moves on to the next exercise in the catalogue', () {
    expect(nextWorkoutAfter(all, 'push_ups')?.id, 'squats');
    expect(nextWorkoutAfter(all, 'squats')?.id, 'deadlifts');
  });

  test('wraps round from the last exercise to the first', () {
    expect(nextWorkoutAfter(all, 'deadlifts')?.id, 'push_ups');
  });

  test('an unknown exercise starts from the top', () {
    expect(nextWorkoutAfter(all, 'lunges')?.id, 'push_ups');
  });

  test('a single-exercise catalogue has nowhere else to go', () {
    expect(nextWorkoutAfter([_w('squats')], 'squats'), isNull);
  });

  test('an empty catalogue has nothing', () {
    expect(nextWorkoutAfter(const [], 'squats'), isNull);
  });
}
