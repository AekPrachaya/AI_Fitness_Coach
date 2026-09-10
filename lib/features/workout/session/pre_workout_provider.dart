import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Setup checklist state ─────────────────────────────────────────────────────

/// Immutable value object for the pre-workout setup checklist.
/// All three items must be satisfied before a session can start.
class PreWorkoutState {
  final bool cameraGranted;
  final bool spaceConfirmed;
  final bool lightingConfirmed;

  const PreWorkoutState({
    this.cameraGranted = false,
    this.spaceConfirmed = false,
    this.lightingConfirmed = false,
  });

  bool get isReady => cameraGranted && spaceConfirmed && lightingConfirmed;

  int get completedCount =>
      (cameraGranted ? 1 : 0) +
      (spaceConfirmed ? 1 : 0) +
      (lightingConfirmed ? 1 : 0);

  PreWorkoutState copyWith({
    bool? cameraGranted,
    bool? spaceConfirmed,
    bool? lightingConfirmed,
  }) =>
      PreWorkoutState(
        cameraGranted: cameraGranted ?? this.cameraGranted,
        spaceConfirmed: spaceConfirmed ?? this.spaceConfirmed,
        lightingConfirmed: lightingConfirmed ?? this.lightingConfirmed,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PreWorkoutNotifier extends StateNotifier<PreWorkoutState> {
  PreWorkoutNotifier() : super(const PreWorkoutState());

  void setCameraGranted(bool granted) {
    if (state.cameraGranted == granted) return;
    state = state.copyWith(cameraGranted: granted);
  }

  void confirmSpace() {
    if (state.spaceConfirmed) return;
    state = state.copyWith(spaceConfirmed: true);
  }

  void confirmLighting() {
    if (state.lightingConfirmed) return;
    state = state.copyWith(lightingConfirmed: true);
  }
}

/// autoDispose so a confirmation from an earlier session does not carry over
/// into the next one — the user re-checks their space and lighting every time.
final preWorkoutNotifierProvider = StateNotifierProvider.autoDispose
    .family<PreWorkoutNotifier, PreWorkoutState, String>(
  (ref, workoutId) => PreWorkoutNotifier(),
);
