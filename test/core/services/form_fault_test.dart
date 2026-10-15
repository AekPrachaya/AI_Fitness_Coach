import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/core/services/form_fault.dart';

void main() {
  group('the cue vocabulary', () {
    test('every fault names both the problem and the fix', () {
      for (final f in FormFault.values) {
        expect(f.label, isNotEmpty, reason: f.name);
        expect(f.cue, isNotEmpty, reason: f.name);
        expect(f.cue, isNot(f.label),
            reason: '${f.name}: the on-screen cue must correct, not diagnose');
      }
    });

    test('cues stay short enough to read in one glance', () {
      // Mid-rep the banner gets about half a second of attention and one
      // line of width. Anything longer is a paragraph nobody reads.
      for (final f in FormFault.values) {
        expect(f.cue.length, lessThanOrEqualTo(26), reason: '${f.name}: ${f.cue}');
      }
    });

    test('no cue is phrased as a bare prohibition', () {
      // "อย่าโน้มตัว" on its own tells the user to stop without telling them
      // what to do instead, which mid-rep is no help at all. Every cue that
      // forbids something also carries the positive instruction.
      for (final f in FormFault.values) {
        if (f.cue.startsWith('อย่า')) {
          fail('${f.name} leads with a prohibition: ${f.cue}');
        }
      }
    });
  });

  group('byPriority', () {
    test('a risky fault outranks a minor one', () {
      final ranked = [FormFault.squatShallow, FormFault.squatTorsoLean]
        ..sort(FormFault.byPriority);
      expect(ranked.first, FormFault.squatTorsoLean);
    });

    test('faults of equal severity keep their declared order', () {
      final ranked = [FormFault.squatKneeOverToe, FormFault.squatTorsoLean]
        ..sort(FormFault.byPriority);
      expect(ranked, [FormFault.squatTorsoLean, FormFault.squatKneeOverToe]);
    });

    test('ranking is antisymmetric, so the sort is well defined', () {
      for (final a in FormFault.values) {
        for (final b in FormFault.values) {
          if (a == b) continue;
          expect(FormFault.byPriority(a, b).sign,
              -FormFault.byPriority(b, a).sign,
              reason: '${a.name} vs ${b.name}');
        }
      }
    });
  });
}
