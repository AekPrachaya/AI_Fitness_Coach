import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/features/workout/session/session_clock.dart';

void main() {
  late DateTime now;
  late SessionClock clock;

  setUp(() {
    now = DateTime(2026, 1, 1, 10, 0, 0);
    clock = SessionClock(now: () => now);
  });

  void advance(Duration d) => now = now.add(d);

  test('reads zero until it is started', () {
    advance(const Duration(minutes: 5));
    expect(clock.elapsedSeconds, 0);
  });

  test('counts time once started', () {
    clock.start();
    advance(const Duration(minutes: 2, seconds: 30));
    expect(clock.elapsedSeconds, 150);
  });

  test('restarting does not reset the elapsed time', () {
    // The camera re-initialises when the app returns to the foreground.
    clock.start();
    advance(const Duration(minutes: 1));
    clock.start();
    advance(const Duration(minutes: 1));
    expect(clock.elapsedSeconds, 120);
  });

  test('excludes time spent paused', () {
    clock.start();
    advance(const Duration(minutes: 1));
    clock.pause();
    advance(const Duration(hours: 1)); // app in the background
    clock.resume();
    advance(const Duration(minutes: 1));
    expect(clock.elapsedSeconds, 120);
  });

  test('stops advancing while still paused', () {
    clock.start();
    advance(const Duration(minutes: 1));
    clock.pause();
    advance(const Duration(minutes: 30));
    expect(clock.elapsedSeconds, 60,
        reason: 'reading mid-pause must not count the pause');
  });

  test('adds up several pauses', () {
    clock.start();
    for (var i = 0; i < 3; i++) {
      advance(const Duration(seconds: 20));
      clock.pause();
      advance(const Duration(minutes: 5));
      clock.resume();
    }
    expect(clock.elapsedSeconds, 60);
  });

  test('ignores a pause before the clock has started', () {
    clock.pause();
    advance(const Duration(minutes: 5));
    clock.start();
    advance(const Duration(seconds: 30));
    expect(clock.elapsedSeconds, 30);
  });

  test('ignores a redundant pause or resume', () {
    clock.start();
    advance(const Duration(seconds: 10));
    clock.pause();
    clock.pause(); // no second anchor
    advance(const Duration(minutes: 5));
    clock.resume();
    clock.resume(); // nothing left to close out
    advance(const Duration(seconds: 10));
    expect(clock.elapsedSeconds, 20);
  });

  test('never reports a negative duration if the clock jumps back', () {
    clock.start();
    now = now.subtract(const Duration(minutes: 5));
    expect(clock.elapsedSeconds, 0);
  });
}
