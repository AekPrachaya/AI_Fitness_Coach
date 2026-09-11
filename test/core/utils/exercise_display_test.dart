import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/core/utils/exercise_display.dart';

void main() {
  test('turns a snake_case id into a readable name', () {
    expect(displayNameFor('bicep_curls'), 'Bicep Curls');
    expect(displayNameFor('squats'), 'Squats');
  });

  test('survives malformed ids', () {
    expect(displayNameFor(''), '');
    expect(displayNameFor('__'), '');
    expect(displayNameFor('_push__ups_'), 'Push Ups');
  });
}
