import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../core/services/exercise_analyzer.dart';
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
    this.totalReps = 0,
    this.restSecondsLeft = 60,
    this.jointAngle,
    this.angleLabel = 'องศา',
    this.formResult,
    this.errorMessage,
    this.poses = const [],
    this.absoluteImageSize = Size.zero,
  });

  final SessionStatus status;
  final int currentSet;
  final int targetSets;
  final int targetReps;
  final int repCount;
  final int totalReps;
  final int restSecondsLeft;
  final double? jointAngle;
  final String angleLabel;
  final FormResult? formResult;
  final String? errorMessage;
  final List<Pose> poses;
  final Size absoluteImageSize;

  WorkoutSessionState copyWith({
    SessionStatus? status,
    int? currentSet,
    int? targetSets,
    int? targetReps,
    int? repCount,
    int? totalReps,
    int? restSecondsLeft,
    double? jointAngle,
    String? angleLabel,
    FormResult? formResult,
    String? errorMessage,
    List<Pose>? poses,
    Size? absoluteImageSize,
  }) {
    return WorkoutSessionState(
      status: status ?? this.status,
      currentSet: currentSet ?? this.currentSet,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      repCount: repCount ?? this.repCount,
      totalReps: totalReps ?? this.totalReps,
      restSecondsLeft: restSecondsLeft ?? this.restSecondsLeft,
      jointAngle: jointAngle ?? this.jointAngle,
      angleLabel: angleLabel ?? this.angleLabel,
      formResult: formResult ?? this.formResult,
      errorMessage: errorMessage,
      poses: poses ?? this.poses,
      absoluteImageSize: absoluteImageSize ?? this.absoluteImageSize,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  WorkoutSessionNotifier(String exerciseId)
      : _analyzer = ExerciseAnalyzer.forId(exerciseId),
        super(const WorkoutSessionState()) {
    final analyzer = ExerciseAnalyzer.forId(exerciseId);
    _repCounter = RepCounter(
      downThreshold: analyzer.downThreshold,
      upThreshold: analyzer.upThreshold,
    );
    state = state.copyWith(angleLabel: analyzer.angleLabel);
  }

  final ExerciseAnalyzer _analyzer;
  final _poseService = PoseDetectionService();
  late final RepCounter _repCounter;
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

    final absSize = Size(image.width.toDouble(), image.height.toDouble());

    if (poses.isEmpty) {
      state = state.copyWith(
        poses: [],
        jointAngle: null,
        formResult: null,
        absoluteImageSize: absSize,
      );
      return;
    }

    final lms = poses.first.landmarks;
    final a = ExerciseAnalyzer.best(lms, _analyzer.primaryA, _analyzer.altA);
    final b = ExerciseAnalyzer.best(lms, _analyzer.primaryB, _analyzer.altB);
    final c = ExerciseAnalyzer.best(lms, _analyzer.primaryC, _analyzer.altC);

    double? angle;
    FormResult? form;

    if (a != null && b != null && c != null) {
      angle = calculateAngle(a, b, c);
      form = _analyzer.analyze(poses.first, angle);

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
          jointAngle: angle,
          formResult: form,
          absoluteImageSize: absSize,
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) state = state.copyWith(status: SessionStatus.tracking);
        return;
      }
    }

    state = state.copyWith(
      poses: poses,
      jointAngle: angle,
      formResult: form,
      repCount: _repCounter.count,
      absoluteImageSize: absSize,
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
    final setReps = _repCounter.count;
    final newTotal = state.totalReps + setReps;
    if (state.currentSet >= state.targetSets) {
      state = state.copyWith(
        status: SessionStatus.finished,
        repCount: setReps,
        totalReps: newTotal,
      );
      return;
    }
    state = state.copyWith(
      status: SessionStatus.resting,
      repCount: setReps,
      totalReps: newTotal,
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

final workoutSessionNotifierProvider = StateNotifierProvider.autoDispose
    .family<WorkoutSessionNotifier, WorkoutSessionState, String>(
  (ref, exerciseId) => WorkoutSessionNotifier(exerciseId),
);
