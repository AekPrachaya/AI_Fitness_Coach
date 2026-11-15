import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../core/services/body_view.dart';
import '../../../core/services/exercise_analyzer.dart';
import '../../../core/services/form_alerts.dart';
import '../../../core/services/form_coach.dart';
import '../../../core/services/form_speech.dart';
import '../../../core/services/movement_tracker.dart';
import '../../../core/services/pose_detection_service.dart';
import '../../../core/services/rep_counter.dart';
import '../../../core/utils/angle_calculator.dart';
import 'session_clock.dart';
import 'session_stats.dart';
import 'tracking_watchdog.dart';

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
    this.cue,
    this.errorMessage,
    this.poses = const [],
    this.absoluteImageSize = Size.zero,
    this.elapsedSeconds = 0,
    this.avgFormScore = 0,
    this.mostCommonError = '',
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

  /// The coaching line to show right now — one correction, held long enough
  /// to read. Null when there is nothing to say.
  final FormCue? cue;

  final String? errorMessage;
  final List<Pose> poses;
  final Size absoluteImageSize;

  /// Wall-clock length of the session, rest included. Settled when the session
  /// finishes.
  final int elapsedSeconds;

  /// Mean form grade over the graded reps, 0–100.
  final double avgFormScore;

  /// The fault seen in the most reps; empty when the workout was clean.
  final String mostCommonError;

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
    FormCue? cue,
    String? errorMessage,
    List<Pose>? poses,
    Size? absoluteImageSize,
    int? elapsedSeconds,
    double? avgFormScore,
    String? mostCommonError,
    // `x ?? this.x` cannot express "set back to null", so clearing the
    // frame-scoped fields (body left the frame) needs explicit flags.
    bool clearJointAngle = false,
    bool clearFormResult = false,
    bool clearCue = false,
  }) {
    return WorkoutSessionState(
      status: status ?? this.status,
      currentSet: currentSet ?? this.currentSet,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      repCount: repCount ?? this.repCount,
      totalReps: totalReps ?? this.totalReps,
      restSecondsLeft: restSecondsLeft ?? this.restSecondsLeft,
      jointAngle: clearJointAngle ? null : (jointAngle ?? this.jointAngle),
      angleLabel: angleLabel ?? this.angleLabel,
      formResult: clearFormResult ? null : (formResult ?? this.formResult),
      cue: clearCue ? null : (cue ?? this.cue),
      errorMessage: errorMessage,
      poses: poses ?? this.poses,
      absoluteImageSize: absoluteImageSize ?? this.absoluteImageSize,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      avgFormScore: avgFormScore ?? this.avgFormScore,
      mostCommonError: mostCommonError ?? this.mostCommonError,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  WorkoutSessionNotifier(
    String exerciseId, {
    FormAlerts? alerts,
  })  : _analyzer = ExerciseAnalyzer.forId(exerciseId),
        _alerts = alerts ?? _coachingAlerts(),
        super(const WorkoutSessionState()) {
    _repCounter = RepCounter(
      downThreshold: _analyzer.downThreshold,
      upThreshold: _analyzer.upThreshold,
      hysteresis: _analyzer.hysteresis,
    );
    state = state.copyWith(angleLabel: _analyzer.angleLabel);
  }

  /// Buzz and voice together: the buzz lands instantly and says *something*
  /// is wrong, the voice arrives a beat later and says what to do about it.
  static FormAlerts _coachingAlerts() => CombinedFormAlerts([
        const HapticFormAlerts(),
        SpokenFormAlerts(),
      ]);

  final ExerciseAnalyzer _analyzer;
  final FormAlerts _alerts;
  final _coach = FormCoach();
  final _movement = MovementTracker();
  final _poseService = PoseDetectionService();
  final _stats = SessionStats();
  final _clock = SessionClock();
  final _watchdog = TrackingWatchdog();

  /// Torso length last seen at the top of the movement, for [BodyView].
  double? _standingTorso;
  late final RepCounter _repCounter;
  Timer? _restTimer;

  /// Read by the summary screen to estimate calories burned.
  double get met => _analyzer.met;

  /// Every fault seen this session, most frequent first.
  Map<String, int> get errorCounts => _stats.errorCounts;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Applies the workout's own set and rep targets. Only takes effect before
  /// the session starts, so a rebuild cannot resize a set already under way.
  void setTargets({int? sets, int? reps}) {
    if (state.status != SessionStatus.idle) return;
    state = state.copyWith(
      targetSets: sets != null && sets > 0 ? sets : null,
      targetReps: reps != null && reps > 0 ? reps : null,
    );
  }

  Future<void> startSession() async {
    if (state.status != SessionStatus.idle) return;
    state = state.copyWith(status: SessionStatus.initializing);
  }

  void onCameraReady() {
    if (state.status == SessionStatus.initializing) {
      _clock.start();
      state = state.copyWith(status: SessionStatus.tracking);
    }
  }

  void processFrame(CameraImage image, CameraDescription camera) async {
    // Error keeps processing: it is how the session notices the body is back.
    if (state.status != SessionStatus.tracking &&
        state.status != SessionStatus.error) {
      return;
    }

    final poses = await _poseService.processFrame(image, camera);
    if (poses == null) return;

    final absSize = Size(image.width.toDouble(), image.height.toDouble());

    if (poses.isEmpty) {
      _applyTracking(TrackingLoss.noBody);
      _coach.reset();
      _movement.reset();
      state = state.copyWith(
        poses: [],
        clearJointAngle: true,
        clearFormResult: true,
        clearCue: true,
        absoluteImageSize: absSize,
        errorMessage: state.errorMessage,
      );
      return;
    }

    final lms = poses.first.landmarks;
    final joints = ExerciseAnalyzer.bestSide(
      lms,
      [_analyzer.primaryA, _analyzer.primaryB, _analyzer.primaryC],
      [_analyzer.altA, _analyzer.altB, _analyzer.altC],
    );

    // A camera square to the user defeats every horizontal measurement the
    // form checks are built on, so it is reported before a confidence problem:
    // the tracking is fine, the camera is in the wrong place, and that is the
    // advice the user can act on.
    // The top of the movement is the one moment the trunk is upright and its
    // full length is on show; remember it so the bottom of the rep is not
    // mistaken for a turn toward the camera.
    if (joints case [final a, final b, final c]
        when calculateAngle(a, b, c) > _analyzer.upThreshold) {
      _standingTorso = BodyView.torsoLength(lms) ?? _standingTorso;
    }

    final TrackingLoss? loss;
    if (_analyzer.needsSideView &&
        BodyView.of(lms, standingTorso: _standingTorso) == ViewAngle.front) {
      loss = TrackingLoss.notSideOn;
    } else if (joints == null) {
      loss = TrackingLoss.lowConfidence;
    } else {
      loss = null;
    }

    _applyTracking(loss);
    if (loss != null) _coachOn(FormResult.notEvaluated);

    double? angle;
    FormResult? form;

    // Nothing is graded through a loss. Reps are not counted either: an angle
    // measured from the wrong side is not a smaller truth, it is a different
    // number, and counting reps off it would inflate the session.
    if (joints case [final a, final b, final c] when loss == null) {
      if (state.status != SessionStatus.tracking) return;
      angle = calculateAngle(a, b, c);
      _movement.update(angle);
      // Faults the current point in the rep cannot judge are dropped before
      // anything sees them — the live cue and the session tally alike.
      form = _analyzer
          .analyze(poses.first, angle)
          .judgeableNow(bottomedOut: _movement.bottomedOut);
      _stats.observe(form);
      _coachOn(form);

      final repDone = _repCounter.update(angle);
      if (repDone) {
        _stats.commitRep();
        final newCount = _repCounter.count;
        if (newCount >= state.targetReps) {
          await _onSetComplete();
          return;
        }
        state = state.copyWith(
          repCount: newCount,
          status: SessionStatus.repComplete,
          poses: poses,
          jointAngle: angle,
          formResult: form,
          cue: _coach.cue,
          clearCue: _coach.cue == null,
          absoluteImageSize: absSize,
        );
        await Future.delayed(const Duration(milliseconds: 600));
        // Only resume if nothing else moved the session on — backgrounding the
        // app mid-flash pauses it, and that must stick.
        if (mounted && state.status == SessionStatus.repComplete) {
          state = state.copyWith(status: SessionStatus.tracking);
        }
        return;
      }
    }

    state = state.copyWith(
      poses: poses,
      jointAngle: angle,
      clearJointAngle: angle == null,
      formResult: form,
      clearFormResult: form == null,
      cue: _coach.cue,
      clearCue: _coach.cue == null,
      repCount: _repCounter.count,
      absoluteImageSize: absSize,
      errorMessage: state.errorMessage,
    );
  }

  /// Runs one graded frame past the coach and buzzes if it raised something.
  void _coachOn(FormResult form) {
    final cue = _coach.update(form);
    if (cue != null && cue.alert) _alerts.raise(cue);
  }

  /// Moves the session between tracking and error as detection comes and goes.
  void _applyTracking(TrackingLoss? loss) {
    final sustained = _watchdog.observe(loss);

    if (sustained != null && state.status == SessionStatus.tracking) {
      // Whatever the user was in the middle of, it is not finishable now.
      _repCounter.abandonRep();
      state = state.copyWith(
        status: SessionStatus.error,
        errorMessage: _messageFor(sustained),
      );
      return;
    }
    if (loss == null && state.status == SessionStatus.error) {
      state = state.copyWith(status: SessionStatus.tracking);
    }
  }

  static String _messageFor(TrackingLoss loss) => switch (loss) {
        TrackingLoss.noBody => 'ไม่เห็นตัวคุณ — ถอยห่างให้กล้องเห็นทั้งตัว',
        TrackingLoss.lowConfidence =>
          'มองข้อต่อไม่ชัด — ลองเพิ่มแสงหรือปรับมุมกล้อง',
        TrackingLoss.notSideOn =>
          'ตรวจท่าจากด้านหน้าไม่ได้ — ย้ายกล้องไปด้านข้างลำตัว',
      };

  void pause() {
    if (state.status == SessionStatus.tracking ||
        state.status == SessionStatus.repComplete ||
        state.status == SessionStatus.error) {
      _clock.pause();
      _repCounter.abandonRep();
      _coach.reset();
      _movement.reset();
      _alerts.silence();
      state = state.copyWith(
        status: SessionStatus.paused,
        clearCue: true,
      );
    }
  }

  void resume() {
    if (state.status == SessionStatus.paused) {
      _clock.resume();
      // Detection starts over rather than resuming into a stale error.
      _watchdog.reset();
      _coach.reset();
      _movement.reset();
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
    _coach.reset();
    _alerts.silence();
    state = _settled(state.copyWith(status: SessionStatus.finished));
  }

  // ── Private ────────────────────────────────────────────────────────────────

  /// How long the "set done" beat is held before the rest timer takes over.
  static const _setCompletePause = Duration(milliseconds: 900);

  Future<void> _onSetComplete() async {
    _restTimer?.cancel();
    _watchdog.reset();
    _coach.reset();
    _movement.reset();
    _alerts.silence();

    final setReps = _repCounter.count;
    final isLastSet = state.currentSet >= state.targetSets;

    state = state.copyWith(
      status: SessionStatus.setComplete,
      repCount: setReps,
      totalReps: state.totalReps + setReps,
    );

    await Future.delayed(_setCompletePause);
    if (!mounted || state.status != SessionStatus.setComplete) return;

    if (isLastSet) {
      state = _settled(state.copyWith(status: SessionStatus.finished));
      return;
    }
    state = state.copyWith(
      status: SessionStatus.resting,
      restSecondsLeft: 60,
    );
    _startRestTimer();
  }

  /// Stamps the totals that only make sense once the session is over.
  WorkoutSessionState _settled(WorkoutSessionState finished) {
    return finished.copyWith(
      elapsedSeconds: _clock.elapsedSeconds,
      avgFormScore: _stats.avgFormScore,
      mostCommonError: _stats.mostCommonError,
    );
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
    _watchdog.reset();
    _coach.reset();
    _movement.reset();
    state = state.copyWith(
      status: SessionStatus.tracking,
      currentSet: state.currentSet + 1,
      repCount: 0,
      restSecondsLeft: 60,
      clearCue: true,
    );
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _alerts.dispose();
    _poseService.dispose();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final workoutSessionNotifierProvider = StateNotifierProvider.autoDispose
    .family<WorkoutSessionNotifier, WorkoutSessionState, String>(
  (ref, exerciseId) => WorkoutSessionNotifier(exerciseId),
);
