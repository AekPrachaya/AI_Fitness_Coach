import 'package:ai_fitness_coach/features/workout/session/rest_adjust.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('+30 adds to both what is left and the total', () {
    expect(adjustRest((left: 40, total: 60), 30), (left: 70, total: 90));
  });

  test('-15 takes from what is left and keeps the total', () {
    expect(adjustRest((left: 40, total: 60), -15), (left: 25, total: 60));
  });

  test('-15 with 15 seconds or less to go ends the rest', () {
    expect(adjustRest((left: 15, total: 60), -15), isNull);
    expect(adjustRest((left: 3, total: 60), -15), isNull);
  });

  test('-15 with a second more than that leaves one second', () {
    expect(adjustRest((left: 16, total: 60), -15), (left: 1, total: 60));
  });

  test(
    '+30 stops at the maximum, and the total only grows by what was added',
    () {
      expect(adjustRest((left: 290, total: 300), 30), (
        left: maxRestSeconds,
        total: 310,
      ));
      expect(adjustRest((left: maxRestSeconds, total: 330), 30), (
        left: maxRestSeconds,
        total: 330,
      ));
    },
  );

  test('the total is never smaller than what is left', () {
    // A stale total (e.g. state from before the field existed) must not
    // produce a ring past full.
    final r = adjustRest((left: 50, total: 10), -15)!;
    expect(r.total, greaterThanOrEqualTo(r.left));
  });
}
