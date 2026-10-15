import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/core/services/form_fault.dart';
import 'package:ai_fitness_coach/core/services/form_speech.dart';

void main() {
  Map<String, String> voice(
    String name, {
    String locale = 'th-TH',
    String? quality,
    bool network = false,
    String? identifier,
  }) =>
      {
        'name': name,
        'locale': locale,
        'quality': ?quality,
        'identifier': ?identifier,
        'network_required': network ? '1' : '0',
      };

  group('ThaiVoice.pick', () {
    test('ignores every voice in another language', () {
      final best = ThaiVoice.pick([
        voice('Samantha', locale: 'en-US', quality: 'premium'),
        voice('Kanya', quality: 'default'),
      ]);
      expect(best!['name'], 'Kanya');
    });

    test('leaves the default alone when the device speaks no Thai', () {
      final best = ThaiVoice.pick([
        voice('Samantha', locale: 'en-US', quality: 'premium'),
        voice('Yuna', locale: 'ko-KR'),
      ]);
      expect(best, isNull);
    });

    test('takes the best-sounding iOS voice', () {
      final best = ThaiVoice.pick([
        voice('Kanya', quality: 'default'),
        voice('Narisa', quality: 'premium'),
        voice('Somsri', quality: 'enhanced'),
      ]);
      expect(best!['name'], 'Narisa');
    });

    test('takes the best-sounding Android voice', () {
      // Android grades on its own vocabulary, which has to rank alongside
      // iOS's without either platform's words winning by accident.
      final best = ThaiVoice.pick([
        voice('th-th-x-tha-local', quality: 'normal'),
        voice('th-th-x-ttm-local', quality: 'very high'),
        voice('th-th-x-tts-local', quality: 'high'),
      ]);
      expect(best!['name'], 'th-th-x-ttm-local');
    });

    test('prefers an on-device voice over a better one needing the network',
        () {
      // A correction has to land inside the rep. A gym with one bar of signal
      // delivers it after the rep, or not at all.
      final best = ThaiVoice.pick([
        voice('th-th-x-net', quality: 'very high', network: true),
        voice('th-th-x-local', quality: 'normal'),
      ]);
      expect(best!['name'], 'th-th-x-local');
    });

    test('falls back to a network voice when it is the only Thai one', () {
      final best = ThaiVoice.pick([
        voice('th-th-x-net', quality: 'very high', network: true),
      ]);
      expect(best!['name'], 'th-th-x-net');
    });

    test('ranks an unknown quality word last rather than first', () {
      final best = ThaiVoice.pick([
        voice('Mystery', quality: 'ultra-deluxe'),
        voice('Kanya', quality: 'default'),
      ]);
      expect(best!['name'], 'Kanya');
    });

    test('accepts the locale spellings the engines actually report', () {
      for (final locale in ['th-TH', 'th_TH', 'th', 'TH-th']) {
        expect(ThaiVoice.pick([voice('Kanya', locale: locale)]), isNotNull,
            reason: locale);
      }
    });

    test('does not mistake another language starting with th for Thai', () {
      expect(ThaiVoice.pick([voice('X', locale: 'tha-Thai')]), isNull);
    });

    test('carries the identifier through, which is how iOS resolves a voice',
        () {
      final best = ThaiVoice.pick([
        voice('Kanya', quality: 'default', identifier: 'com.apple.voice.kanya'),
      ]);
      expect(best, {
        'name': 'Kanya',
        'locale': 'th-TH',
        'identifier': 'com.apple.voice.kanya',
      });
      expect(best!.containsKey('network_required'), isFalse,
          reason: 'setVoice takes the voice, not the ranking metadata');
    });

    test('survives the shapes a platform channel can actually return', () {
      expect(ThaiVoice.pick(null), isNull);
      expect(ThaiVoice.pick(const []), isNull);
      expect(ThaiVoice.pick('not a list'), isNull);
      expect(ThaiVoice.pick(const [null, 'junk', 42]), isNull);
      // Channels hand back Map<Object?, Object?>, not Map<String, String>.
      expect(
        ThaiVoice.pick(<Object?>[
          <Object?, Object?>{'name': 'Kanya', 'locale': 'th-TH'},
        ])!['name'],
        'Kanya',
      );
    });
  });

  group('SpeechPacer', () {
    final t0 = DateTime(2026, 1, 1, 9, 0, 0);
    DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

    const lean = FormFault.squatTorsoLean;
    const knee = FormFault.squatKneeOverToe;

    late SpeechPacer pacer;
    setUp(() => pacer = SpeechPacer(
          repeatSameLine: const Duration(seconds: 10),
          betweenLines: const Duration(milliseconds: 3500),
        ));

    test('says a new correction straight away', () {
      expect(pacer.claim(lean, at(0)), isTrue);
    });

    test('does not repeat itself on the buzz\'s schedule', () {
      // The coach re-raises an uncorrected fault every 4s. At a second and a
      // half per line that left the coach talking most of the time.
      expect(pacer.claim(lean, at(0)), isTrue);
      for (final ms in [4000, 8000, 9999]) {
        expect(pacer.claim(lean, at(ms)), isFalse, reason: '$ms ms');
      }
      expect(pacer.claim(lean, at(10000)), isTrue);
    });

    test('a second fault cannot machine-gun past the same-line rule', () {
      // Two faults alternating would each pass their own cooldown while the
      // user hears a sentence every couple of seconds.
      expect(pacer.claim(lean, at(0)), isTrue);
      expect(pacer.claim(knee, at(1000)), isFalse);
      expect(pacer.claim(knee, at(3500)), isTrue);
    });

    test('a different correction is not made to wait out the first one', () {
      expect(pacer.claim(lean, at(0)), isTrue);
      expect(pacer.claim(knee, at(4000)), isTrue,
          reason: 'past the floor between lines, and never said before');
    });

    test('a refused claim does not reset the clock', () {
      expect(pacer.claim(lean, at(0)), isTrue);
      expect(pacer.claim(lean, at(5000)), isFalse);
      // Had the refusal been recorded, this would be held until 15s.
      expect(pacer.claim(lean, at(10000)), isTrue);
    });

    test('clear lets the next set speak its first correction', () {
      expect(pacer.claim(lean, at(0)), isTrue);
      expect(pacer.claim(lean, at(2000)), isFalse);
      pacer.clear();
      expect(pacer.claim(lean, at(2000)), isTrue);
    });
  });
}
