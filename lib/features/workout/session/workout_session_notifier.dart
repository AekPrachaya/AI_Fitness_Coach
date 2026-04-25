import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../core/services/form_analyzer.dart';
import '../../../core/services/pose_detection_service.dart';
import '../../../core/services/rep_counter.dart';
import '../../../core/utils/angle_calculator.dart';

// ── State ──────────────────────────────────────────────────────────────────

enum SessionStatus {
  idle,
  initializing,
  tracking,
  repComplete,
  setComplete,
  resting,
  paused,
  error,
  finished,
}

class WorkoutSessionState {
  const WorkoutSessionState({
    this.status = SessionStatus.idle,
    this.currentSet = 1,
    this.targetSets = 3,
    this.targetReps = 10,
    this.repCount = 0,
    this.restSecondsLeft = 60,
    this.kneeAngle,
    this.formResult,
    this.errorMessage,
    this.poses = const [],
  });

  final SessionStatus status;
  final int currentSet;
  final int targetSets;
  final int targetReps;
  final int repCount;
  final int restSecondsLeft;
  final double? kneeAngle;
  final FormResult? formResult;
  final String? errorMessage;
  final List<Pose> poses;

  WorkoutSessionState copyWith({
    SessionStatus? status,
    int? currentSet,
    int? targetSets,
    int? targetReps,
    int? repCount,
    int? restSecondsLeft,
    double? kneeAngle,
    FormResult? formResult,
    String? errorMessage,
    List<Pose>? poses,
  }) {
    return WorkoutSessionState(
      status: status ?? this.status,
      currentSet: currentSet ?? this.currentSet,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      repCount: repCount ?? this.repCount,
      restSecondsLeft: restSecondsLeft ?? this.restSecondsLeft,
      kneeAngle: kneeAngle ?? this.kneeAngle,
      formResult: formResult ?? this.formResult,
      errorMessage: errorMessage,
      poses: poses ?? this.poses,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  WorkoutSessionNotifier() : super(const WorkoutSessionState());

  final _poseService = PoseDetectionService();
  final _repCounter = RepCounter();
  final _formAnalyzer = FormAnalyzer();
  Timer? _restTimer;

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> startSession() async {
    if (state.status != SessionStatus.idle) return;
    state = state.copyWith(status: SessionStatus.initializing);
  }

  void onCameraReady() {
    if (state.status == SessionStatus.initializing) {
      state = state.copyWith(status: SessionStatus.tracking);
    }
  }

  void processFrame(CameraImage image, CameraDescription camera) async {
    if (state.status != SessionStatus.tracking) return;

    final poses = await _poseService.processFrame(image, camera);
    if (poses == null) return;

    if (poses.isEmpty) {
      // Body lost for a full second is handled by caller watching state
      state = state.copyWith(poses: [], kneeAngle: null, formResult: null);
      return;
    }

    final lms = poses.first.landmarks;
    final hip = lms[PoseLandmarkType.leftHip];
    final knee = lms[PoseLandmarkType.leftKnee];
    final ankle = lms[PoseLandmarkType.leftAnkle];

    double? angle;
    FormResult? form;

    if (hip != null && knee != null && ankle != null &&
        hip.likelihood > 0.5 && knee.likelihood > 0.5 && ankle.likelihood > 0.5) {
      angle = calculateAngle(hip, knee, ankle);
      form = _formAnalyzer.analyze(poses.first, angle);

      final repDone = _repCounter.update(angle);
      if (repDone) {
        final newCount = _repCounter.count;
        if (newCount >= state.targetReps) {
          _onSetComplete();
          return;
        }
        state = state.copyWith(
          repCount: newCount,
          status: SessionStatus.repComplete,
          poses: poses,
          kneeAngle: angle,
          formResult: form,
        );
        // Brief repComplete flash, then back to tracking
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          state = state.copyWith(status: SessionStatus.tracking);
        }
        return;
      }
    }

    state = state.copyWith(
      poses: poses,
      kneeAngle: angle,
      formResult: form,
      repCount: _repCounter.count,
    );
  }

  void pause() {
    if (state.status == SessionStatus.tracking) {
      state = state.copyWith(status: SessionStatus.paused);
    }
  }

  void resume() {
    if (state.status == SessionStatus.paused) {
      state = state.copyWith(status: SessionStatus.tracking);
    }
  }

  void skipRest() {
    if (state.status == SessionStatus.resting) {
      _restTimer?.cancel();
      _startNextSet();
    }
  }

  void endSession() {
    _restTimer?.cancel();
    state = state.copyWith(status: SessionStatus.finished);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  void _onSetComplete() {
    _restTimer?.cancel();
    if (state.currentSet >= state.targetSets) {
      state = state.copyWith(
        status: SessionStatus.finished,
        repCount: _repCounter.count,
      );
      return;
    }
    state = state.copyWith(
      status: SessionStatus.resting,
      repCount: _repCounter.count,
      restSecondsLeft: 60,
    );
    _startRestTimer();
  }

  void _startRestTimer() {
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = state.restSecondsLeft - 1;
      if (left <= 0) {
        t.cancel();
        _startNextSet();
      } else {
        state = state.copyWith(restSecondsLeft: left);
      }
    });
  }

  void _startNextSet() {
    _repCounter.reset();
    state = state.copyWith(
      status: SessionStatus.tracking,
      currentSet: state.currentSet + 1,
      repCount: 0,
      restSecondsLeft: 60,
    );
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _poseService.dispose();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final workoutSessionNotifierProvider =
    StateNotifierProvider.autoDispose<WorkoutSessionNotifier, WorkoutSessionState>(
  (ref) => WorkoutSessionNotifier(),
);
