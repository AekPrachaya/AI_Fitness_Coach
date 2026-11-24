import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// A short beep for every counted rep.
///
/// The user is watching their own body, not the screen, and the light haptic
/// tap goes unfelt with the phone propped across the room. A sound reaches
/// them wherever they are looking.
///
/// It shares the audio session with the spoken form cues
/// (`SpokenFormAlerts`): playback, mixed with whatever the user is listening
/// to and ducking it rather than stopping it. A different session here would
/// silently change how the cues behave, since iOS has only one per app.
class RepChime {
  RepChime({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  static const _asset = 'sounds/rep_beep.wav';

  final AudioPlayer _player;
  Future<void>? _ready;

  Future<void> _prepare() async {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );
    await _player.setPlayerMode(PlayerMode.lowLatency);
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setSource(AssetSource(_asset));
  }

  /// Plays the beep. Never throws: a missing sound must not end a workout.
  Future<void> play() async {
    try {
      await (_ready ??= _prepare());
      await _player.stop();
      await _player.resume();
    } catch (e) {
      _ready = null; // try setting up again on the next rep
      debugPrint('RepChime: beep not played — $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
