import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/features/workout/session/tracking_watchdog.dart';

void main() {
  late DateTime now;
  late TrackingWatchdog watchdog;

  const grace = Duration(milliseconds: 1200);

  setUp(() {
    now = DateTime(2026, 1, 1, 10, 0, 0);
    watchdog = TrackingWatchdog(grace: grace, now: () => now);
  });

  void advance(Duration d) => now = now.add(d);

  test('a healthy frame reports nothing', () {
    expect(watchdog.observe(null), isNull);
    expect(watchdog.isLost, isFalse);
  });

  test('a single bad frame is not surfaced', () {
    expect(watchdog.observe(TrackingLoss.noBody), isNull);
  });

  test('a blink of lost tracking is absorbed', () {
    // A hand crossing a knee for a few frames must not flash an error.
    watchdog.observe(TrackingLoss.lowConfidence);
    advance(const Duration(milliseconds: 300));
    expect(watchdog.observe(TrackingLoss.lowConfidence), isNull);
    advance(const Duration(milliseconds: 200));
    expect(watchdog.observe(null), isNull);
    expect(watchdog.isLost, isFalse);
  });

  test('loss lasting past the grace period is surfaced', () {
    watchdog.observe(TrackingLoss.noBody);
    advance(grace);
    expect(watchdog.observe(TrackingLoss.noBody), TrackingLoss.noBody);
  });

  test('keeps reporting the loss so the error state can be held', () {
    watchdog.observe(TrackingLoss.noBody);
    advance(grace);
    for (var i = 0; i < 5; i++) {
      advance(const Duration(milliseconds: 100));
      expect(watchdog.observe(TrackingLoss.noBody), TrackingLoss.noBody);
    }
  });

  test('recovering clears the loss', () {
    watchdog.observe(TrackingLoss.noBody);
    advance(grace);
    expect(watchdog.observe(TrackingLoss.noBody), isNotNull);

    expect(watchdog.observe(null), isNull);
    expect(watchdog.isLost, isFalse);
  });

  test('a fresh loss after recovery serves its own grace period', () {
    watchdog.observe(TrackingLoss.noBody);
    advance(grace);
    watchdog.observe(TrackingLoss.noBody);
    watchdog.observe(null);

    expect(watchdog.observe(TrackingLoss.noBody), isNull);
    advance(const Duration(milliseconds: 500));
    expect(watchdog.observe(TrackingLoss.noBody), isNull);
    advance(const Duration(milliseconds: 700));
    expect(watchdog.observe(TrackingLoss.noBody), TrackingLoss.noBody);
  });

  test('a different kind of loss restarts the clock', () {
    // Dim lighting that turns into the user walking off is a new problem with
    // different advice, so it should not inherit the elapsed time.
    watchdog.observe(TrackingLoss.lowConfidence);
    advance(const Duration(milliseconds: 1100));
    expect(watchdog.observe(TrackingLoss.noBody), isNull);

    advance(const Duration(milliseconds: 500));
    expect(watchdog.observe(TrackingLoss.noBody), isNull);

    advance(const Duration(milliseconds: 700));
    expect(watchdog.observe(TrackingLoss.noBody), TrackingLoss.noBody);
  });

  test('reset drops an in-flight loss', () {
    watchdog.observe(TrackingLoss.noBody);
    advance(grace);
    watchdog.reset();

    expect(watchdog.isLost, isFalse);
    expect(watchdog.observe(TrackingLoss.noBody), isNull,
        reason: 'the grace period starts over after a reset');
  });

  test('surfaces exactly at the grace boundary, not before', () {
    watchdog.observe(TrackingLoss.noBody);
    advance(grace - const Duration(milliseconds: 1));
    expect(watchdog.observe(TrackingLoss.noBody), isNull);
    advance(const Duration(milliseconds: 1));
    expect(watchdog.observe(TrackingLoss.noBody), TrackingLoss.noBody);
  });
}
