import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/core/services/rep_counter.dart';

void main() {
  // Defaults: down < 100, up > 160, hysteresis 8 — so the angle must actually
  // cross 92 on the way down and 168 on the way up.
  group('with default thresholds', () {
    late RepCounter counter;
    setUp(() => counter = RepCounter());

    test('starts at zero and does not count a lone descent', () {
      expect(counter.count, 0);
      expect(counter.update(80), isFalse);
      expect(counter.count, 0);
    });

    test('counts one rep for a full down-then-up cycle', () {
      counter.update(170);
      counter.update(80);
      expect(counter.update(170), isTrue);
      expect(counter.count, 1);
    });

    test('jitter inside the dead-band never counts', () {
      // 95 is below downThreshold but not below 100 - 8, and 165 is above
      // upThreshold but not above 160 + 8.
      for (var i = 0; i < 20; i++) {
        counter.update(i.isEven ? 95 : 165);
      }
      expect(counter.count, 0);
    });

    test('holding at the bottom does not count repeatedly', () {
      counter.update(80);
      counter.update(80);
      counter.update(80);
      expect(counter.count, 0);
      expect(counter.update(175), isTrue);
      expect(counter.count, 1);
    });

    test('holding at the top does not count repeatedly', () {
      counter.update(80);
      counter.update(175);
      expect(counter.update(175), isFalse);
      expect(counter.update(178), isFalse);
      expect(counter.count, 1);
    });

    test('counts several consecutive reps', () {
      for (var i = 0; i < 3; i++) {
        counter.update(85);
        counter.update(172);
      }
      expect(counter.count, 3);
    });

    test('reset clears the count and the phase', () {
      counter.update(85);
      counter.update(172);
      expect(counter.count, 1);

      counter.reset();
      expect(counter.count, 0);

      // Phase is back to waitingDown: going straight up must not count.
      expect(counter.update(175), isFalse);
      expect(counter.count, 0);
    });
  });

  test('honours per-exercise thresholds', () {
    // Bicep curl range: down < 50, up > 150.
    final counter = RepCounter(downThreshold: 50, upThreshold: 150);
    counter.update(70); // not deep enough for a curl
    counter.update(160);
    expect(counter.count, 0);

    counter.update(40);
    counter.update(160);
    expect(counter.count, 1);
  });

  test('a wider hysteresis rejects a shallower rep', () {
    final strict = RepCounter(
      downThreshold: 100,
      upThreshold: 160,
      hysteresis: 20,
    );
    strict.update(85); // above 100 - 20, so the descent is not registered
    strict.update(175);
    expect(strict.count, 0);

    strict.update(75);
    strict.update(185);
    expect(strict.count, 1);
  });

  group('abandonRep', () {
    // The phantom rep: a rep is only counted on the way back up, so a
    // half-finished one leaves the counter waiting for a high angle — which
    // is exactly what the first frame after an interruption hands it.
    test('a rep interrupted at the bottom is not completed by standing up',
        () {
      final counter = RepCounter();
      counter.update(150);
      counter.update(80); // down
      counter.abandonRep(); // phone call, lost tracking, pause
      expect(counter.update(175), isFalse,
          reason: 'back on their feet, but that rep never happened');
      expect(counter.count, 0);
    });

    test('keeps the reps already earned', () {
      final counter = RepCounter();
      counter.update(150);
      counter.update(80);
      counter.update(175); // a real rep
      expect(counter.count, 1);

      counter.update(80); // into a second
      counter.abandonRep();
      counter.update(175);
      expect(counter.count, 1, reason: 'the first rep is still banked');
    });

    test('the next honest rep still counts', () {
      final counter = RepCounter();
      counter.update(80);
      counter.abandonRep();

      counter.update(175); // swallowed, as it must be
      counter.update(80); // a full rep, start to finish
      expect(counter.update(175), isTrue);
      expect(counter.count, 1);
    });

    test('abandoning between reps changes nothing', () {
      final counter = RepCounter();
      counter.update(175);
      counter.abandonRep();
      counter.update(80);
      expect(counter.update(175), isTrue);
      expect(counter.count, 1);
    });

    test('abandoning repeatedly is harmless', () {
      final counter = RepCounter();
      counter.update(80);
      for (var i = 0; i < 5; i++) {
        counter.abandonRep();
      }
      counter.update(80);
      expect(counter.update(175), isTrue, reason: 'a fresh rep after the mess');
      expect(counter.count, 1);
    });
  });
}
