import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'form_alerts.dart';
import 'form_coach.dart';
import 'form_fault.dart';

/// Reads the coach's corrections out loud in Thai.
///
/// The point of speech over a buzz is that it needs none of the user's
/// attention: a buzz says "something is wrong" and sends them looking at the
/// phone, while "ดันสะโพกไปข้างหลัง" is the whole correction, delivered
/// without them taking their eyes off their own form.
class SpokenFormAlerts implements FormAlerts {
  SpokenFormAlerts({FlutterTts? tts})
      : _tts = tts ?? (_shared ??= FlutterTts()) {
    // Warmed up now rather than on the first fault: an engine cold-starting
    // mid-rep would deliver the correction after the rep it belongs to.
    _ready = _configure();
    _watchLifecycle();
  }

  /// One engine for the whole app, however many sessions are opened.
  ///
  /// Every `FlutterTts` claims the plugin's method channel handler as it is
  /// built, so a second one silently takes the first one's completion
  /// callbacks. Sessions come and go — one per exercise screen — and sharing
  /// the engine keeps that from mattering. Settings are still re-applied per
  /// session, which is cheap and leaves no room for stale state.
  static FlutterTts? _shared;

  /// Normal conversational speed on both platforms, which is the setting
  /// that sounds like a person rather than an announcement.
  ///
  /// The value means the same thing on each, but only by coincidence of two
  /// different conventions: iOS passes it straight to
  /// `AVSpeechUtterance.rate`, whose default is 0.5, while flutter_tts doubles
  /// it for Android, whose native normal is 1.0. Do not "fix" it to 1.0.
  static const _rate = 0.5;

  /// Unshifted. A raised pitch reads as urgency and gets tiring over a set.
  static const _pitch = 1.0;


  final FlutterTts _tts;
  AppLifecycleListener? _lifecycle;

  // Reassigned when the app comes back and the engine has to be set up again,
  // so [_say] always awaits the configuration that is actually in force.
  late Future<void> _ready;

  bool _usable = false;

  final _pacer = SpeechPacer();

  /// Resolves false when the device has no Thai voice to speak with, which on
  /// Android is the common case until the user installs the Thai voice data.
  /// The banner and the haptic buzz carry the session on their own.
  Future<bool> get isUsable async {
    await _ready;
    return _usable;
  }

  @override
  void raise(FormCue cue) {
    // Praise is deliberately not spoken. The coach only raises it between
    // corrections, and a voice saying "ท่าดีมาก" every few reps turns into
    // something the user mutes — which costs them the corrections too.
    final fault = cue.fault;
    if (fault == null) return;

    if (!_pacer.claim(fault, DateTime.now())) return;
    unawaited(_say(cue.message));
  }

  @override
  void silence() {
    // A new set deserves to hear its first correction, however recently the
    // last set said the same thing.
    _pacer.clear();
    unawaited(_tts.stop());
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _lifecycle = null;
    unawaited(_tts.stop());
  }

  Future<void> _say(String line) async {
    await _ready;
    if (!_usable) return;
    try {
      // A half-spoken correction for the previous fault is worse than
      // silence, so a new cue cuts it off rather than queueing behind it.
      await _tts.stop();
      await _tts.speak(line);
    } catch (e) {
      debugPrint('SpokenFormAlerts: speak failed — $e');
    }
  }

  /// Rebuilds whatever the app losing the foreground took away.
  ///
  /// A phone call tears down the audio session underneath us, and nothing
  /// puts it back: without this the coach goes quiet for the rest of the
  /// workout while the screen carries on as though it were still talking.
  ///
  /// It doubles as the moment a device that had no Thai voice gets a second
  /// look — the user who just went to Settings to install one comes back
  /// through here, and the full setup runs again rather than leaving them
  /// with a feature that only works after a restart.
  void _watchLifecycle() {
    try {
      _lifecycle = AppLifecycleListener(
        onResume: () => _ready = _usable ? _activateAudio() : _configure(),
      );
    } catch (e) {
      // No binding to listen on — a unit test, or a headless host. Speech
      // still works; it just will not recover from an interruption.
      debugPrint('SpokenFormAlerts: no lifecycle listener — $e');
    }
  }

  /// The iOS audio session only. Cheaper than [_configure] for the common
  /// case where the engine itself is still configured correctly.
  Future<void> _activateAudio() async {
    if (!Platform.isIOS) return;
    try {
      await _tts.setSharedInstance(true);
      await _applyIosAudioCategory();
    } catch (e) {
      debugPrint('SpokenFormAlerts: audio session not restored — $e');
    }
  }

  /// The configuration a turn-by-turn navigation app uses, and for the same
  /// reason: short spoken prompts that have to be heard over the user's music
  /// and over the Ring/Silent switch, ducking that music for a second instead
  /// of stopping it.
  Future<void> _applyIosAudioCategory() => _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.duckOthers,
          IosTextToSpeechAudioCategoryOptions
              .interruptSpokenAudioAndMixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );

  Future<void> _configure() async {
    try {
      if (Platform.isIOS) {
        await _tts.setSharedInstance(true);
        await _applyIosAudioCategory();
      }

      if (await _tts.isLanguageAvailable(ThaiVoice.languageTag) != true) {
        debugPrint(
          'SpokenFormAlerts: no ${ThaiVoice.languageTag} voice on this device '
          '— install the Thai voice data to hear the coach',
        );
        return;
      }

      await _tts.setLanguage(ThaiVoice.languageTag);
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(1.0);
      // Lets [_say] await an utterance, so stop/speak cannot interleave.
      await _tts.awaitSpeakCompletion(true);
      await _selectVoice();

      _usable = true;
    } catch (e) {
      debugPrint('SpokenFormAlerts: setup failed — $e');
    }
  }

  /// Upgrades from the default Thai voice to the best one installed, which is
  /// most of the difference between sounding synthetic and sounding spoken.
  Future<void> _selectVoice() async {
    final voices = await _tts.getVoices;
    final best = ThaiVoice.pick(voices);
    if (best == null) return;
    await _tts.setVoice(best);
    debugPrint('SpokenFormAlerts: speaking Thai as ${best['name']}');
  }
}

/// Decides how often the coach is allowed to open its mouth.
///
/// Separate from the rhythm the buzz runs on, because the two want different
/// numbers. The coach re-raises an uncorrected fault every few seconds, which
/// is right for a buzz and far too fast for a sentence: a Thai cue takes about
/// a second and a half to say, so matching the buzz leaves the voice talking
/// almost continuously — which is how a helpful coach becomes one the user
/// mutes, losing them the corrections as well.
class SpeechPacer {
  SpeechPacer({
    this.repeatSameLine = const Duration(seconds: 10),
    this.betweenLines = const Duration(milliseconds: 3500),
  });

  /// Quiet period before the same correction is said a second time. Said
  /// once, then the buzz carries the reminder.
  final Duration repeatSameLine;

  /// Floor between any two spoken lines, whatever they say. Two faults that
  /// alternate would otherwise slip past [repeatSameLine] and fire a sentence
  /// every couple of seconds. The buzz still lands instantly, so a correction
  /// held back here is announced on time — just not in words.
  final Duration betweenLines;

  final Map<FormFault, DateTime> _lastSpoken = {};
  DateTime? _lastSpokenAt;

  /// True when [fault] may be spoken at [now], recording the slot if so.
  bool claim(FormFault fault, DateTime now) {
    final sameLine = _lastSpoken[fault];
    if (sameLine != null && now.difference(sameLine) < repeatSameLine) {
      return false;
    }
    final anyLine = _lastSpokenAt;
    if (anyLine != null && now.difference(anyLine) < betweenLines) {
      return false;
    }
    _lastSpoken[fault] = now;
    _lastSpokenAt = now;
    return true;
  }

  /// Forgets everything said so far, so the next correction is never withheld
  /// on account of a set that is already over.
  void clear() {
    _lastSpoken.clear();
    _lastSpokenAt = null;
  }
}

/// Picks which installed Thai voice to speak with.
abstract final class ThaiVoice {
  static const languageTag = 'th-TH';

  /// How good each platform says a voice is, on one scale.
  ///
  /// The two platforms grade on different vocabularies — iOS reports its
  /// `AVSpeechSynthesisVoiceQuality` and Android its `Voice.QUALITY_*` — so
  /// both are mapped onto the same numbers and an unknown word scores lowest.
  static const _quality = <String, int>{
    // iOS
    'premium': 4,
    'enhanced': 3,
    'default': 1,
    // Android
    'very high': 4,
    'high': 3,
    'normal': 2,
    'low': 1,
    'very low': 0,
  };

  /// Returns the voice to hand to `setVoice`, or null when the device has no
  /// Thai voice and the default should be left alone.
  ///
  /// Ranking puts every on-device voice ahead of every voice that needs the
  /// network, even a better-sounding one. A correction has to arrive inside
  /// the rep it is correcting; a round trip from a gym with one bar does not,
  /// and a voice that fails offline is worse than a plainer one that works.
  static Map<String, String>? pick(dynamic voices) {
    if (voices is! List) return null;

    final thai = <Map<String, String>>[];
    for (final voice in voices) {
      if (voice is! Map) continue;
      final map = {
        for (final e in voice.entries) '${e.key}': '${e.value}',
      };
      // Matches 'th-TH' and bare 'th', and tolerates the underscore form
      // some Android engines report.
      final locale = (map['locale'] ?? '').replaceAll('_', '-').toLowerCase();
      if (locale == 'th' || locale.startsWith('th-')) thai.add(map);
    }
    if (thai.isEmpty) return null;

    thai.sort((a, b) {
      final byNetwork = _needsNetwork(a) ? 1 : 0;
      final other = _needsNetwork(b) ? 1 : 0;
      if (byNetwork != other) return byNetwork - other;
      return _score(b).compareTo(_score(a));
    });

    final best = thai.first;
    // iOS resolves a voice unambiguously by identifier; Android matches on
    // name and locale. Passing the keys a platform does not know is harmless,
    // so the winning voice goes over whole minus the ranking metadata.
    return {
      for (final key in const ['name', 'locale', 'identifier']) key: ?best[key],
    };
  }

  static int _score(Map<String, String> voice) =>
      _quality[(voice['quality'] ?? '').toLowerCase()] ?? 0;

  static bool _needsNetwork(Map<String, String> voice) =>
      voice['network_required'] == '1';
}
