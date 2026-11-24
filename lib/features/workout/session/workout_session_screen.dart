import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/session_history_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/exercise_analyzer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/workout_repository.dart';
import 'rep_pace.dart';
import 'session_progress.dart';
import 'session_stats.dart';
import 'widgets/form_cue_banner.dart';
import 'widgets/pose_overlay_painter.dart';
import 'widgets/rep_counter_panel.dart';
import 'widgets/rest_overlay.dart';
import 'widgets/session_interrupted_overlay.dart';
import 'widgets/session_top_bar.dart';
import 'widgets/set_complete_overlay.dart';
import 'widgets/tracking_error_overlay.dart';
import 'workout_session_notifier.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    this.targetSets,
    this.targetReps,
  });

  final String exerciseId;

  /// Display name, e.g. 'Bicep Curls' — carried through so the summary and the
  /// stored history never show the raw id.
  final String exerciseName;

  /// The workout's own targets, as advertised on the home card. Null falls
  /// back to the notifier's defaults.
  final int? targetSets;
  final int? targetReps;

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isSwitching = false;
  bool _isStreaming = false;

  /// True once the session has had a working camera, so a null controller
  /// afterwards means "taken away and coming back", not "still starting up".
  bool _cameraWasReady = false;

  /// Set when reopening the camera after an interruption failed outright and
  /// the user has to be offered a retry.
  bool _cameraFailed = false;

  /// Times each rep for the HUD's REP TIME readout.
  final _pace = RepPace();

  /// Camera work is serialised through this chain: start, stop, switch and the
  /// lifecycle teardown all throw if they interleave on the same controller.
  Future<void> _cameraQueue = Future.value();

  WorkoutSessionNotifier get _notifier =>
      ref.read(workoutSessionNotifierProvider(widget.exerciseId).notifier);

  /// Pose detection only earns its battery cost while a set is running. Rests
  /// and pauses stop the stream; the brief repComplete flash does not, since
  /// restarting the stream every rep would be far more expensive.
  static bool _wantsFrames(SessionStatus status) =>
      status != SessionStatus.paused &&
      status != SessionStatus.resting &&
      status != SessionStatus.finished;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _enqueue(_initCamera);
  }

  /// Runs [action] once any camera work already in flight has settled.
  void _enqueue(Future<void> Function() action) {
    _cameraQueue = _cameraQueue.then((_) => action()).catchError((Object e) {
      debugPrint('WorkoutSessionScreen camera error: $e');
    });
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty || !mounted) return;

    _cameraIndex = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    if (_cameraIndex < 0) _cameraIndex = 0;

    await _startCamera(_cameraIndex);
    if (!mounted) return;

    final notifier = _notifier;
    notifier.setTargets(sets: widget.targetSets, reps: widget.targetReps);
    await notifier.startSession();
    notifier.onCameraReady();
  }

  Future<void> _startCamera(int index) async {
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.medium,
      // Must match what PoseDetectionService decodes: BGRA on iOS,
      // YUV 420 on Android. bgra8888 is not supported by the Android camera.
      // dart:io Platform throws on web, and camera_web ignores this field
      // anyway, so it is left null there.
      imageFormatGroup: kIsWeb
          ? null
          : (defaultTargetPlatform == TargetPlatform.iOS
              ? ImageFormatGroup.bgra8888
              : ImageFormatGroup.yuv420),
      enableAudio: false,
    );
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    _isStreaming = false;
    _cameraWasReady = true;
    setState(() {
      _controller = controller;
      _cameraFailed = false;
    });

    await _applyStreaming(_wantsFrames(
      ref.read(workoutSessionNotifierProvider(widget.exerciseId)).status,
    ));
  }

  /// Brings the image stream in line with [wanted]. Safe to call repeatedly.
  ///
  /// No-ops on web: camera_web has no startImageStream implementation, so the
  /// preview shows but pose tracking never runs there.
  Future<void> _applyStreaming(bool wanted) async {
    if (kIsWeb) return;
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        wanted == _isStreaming) {
      return;
    }
    if (wanted) {
      await controller.startImageStream(_onFrame);
      _isStreaming = true;
    } else {
      await controller.stopImageStream();
      _isStreaming = false;
    }
  }

  void _onFrame(CameraImage image) {
    // A frame can still land after dispose: stopping the stream is async, and
    // reading a provider off a disposed State throws.
    if (!mounted) return;
    _notifier.processFrame(image, _cameras[_cameraIndex]);
  }

  /// Releases the camera. The OS reclaims it whenever the app leaves the
  /// foreground, so a controller held across that comes back dead.
  Future<void> _releaseCamera() async {
    final controller = _controller;
    if (controller == null) return;

    if (mounted) {
      setState(() => _controller = null);
    } else {
      _controller = null;
    }

    if (_isStreaming) {
      _isStreaming = false;
      try {
        await controller.stopImageStream();
      } catch (e) {
        debugPrint('WorkoutSessionScreen stopImageStream failed: $e');
      }
    }
    await controller.dispose();
  }

  /// How many times reopening the camera is attempted before the user is
  /// asked to retry by hand, and how long to wait between tries.
  ///
  /// iOS does not always hand the capture device back the instant the app is
  /// foregrounded again — right after a call ends, the first `initialize()`
  /// can still fail. One immediate try plus a couple of spaced retries covers
  /// that without leaving the session stuck on a spinner forever, which is
  /// what a single silent attempt used to do.
  static const _cameraRetries = 3;
  static const _cameraRetryDelay = Duration(milliseconds: 600);

  /// Restores the camera after the app comes back to the foreground.
  Future<void> _ensureCamera() async {
    if (!mounted || _controller != null || _cameras.isEmpty) return;

    for (var attempt = 1; attempt <= _cameraRetries; attempt++) {
      if (!mounted) return;
      try {
        await _startCamera(_cameraIndex);
        return;
      } catch (e) {
        debugPrint('WorkoutSessionScreen camera restore $attempt failed: $e');
        if (attempt < _cameraRetries) {
          await Future.delayed(_cameraRetryDelay);
        }
      }
    }
    if (mounted) setState(() => _cameraFailed = true);
  }

  /// Retries the camera from the overlay's button.
  void _retryCamera() {
    setState(() => _cameraFailed = false);
    _enqueue(_ensureCamera);
  }

  /// Disables the button straight away, then queues the switch behind any
  /// camera work already running.
  void _requestCameraSwitch() {
    if (_isSwitching || _cameras.length < 2) return;
    setState(() => _isSwitching = true);
    _enqueue(_switchCamera);
  }

  Future<void> _switchCamera() async {
    try {
      await _releaseCamera();
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
      await _startCamera(_cameraIndex);
    } finally {
      // Without this the button stays disabled for good if the switch throws.
      if (mounted) setState(() => _isSwitching = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        // Hand the session back paused rather than resuming mid-rep: the user
        // is not in position when they return.
        if (mounted) _notifier.pause();
        _enqueue(_releaseCamera);
      case AppLifecycleState.resumed:
        // Decided inside the queue, not here: a quick background-foreground
        // flick can deliver `resumed` before the release above has run, and
        // reading _controller now would see a camera that is about to go away.
        _enqueue(_ensureCamera);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      if (_isStreaming) {
        _isStreaming = false;
        controller.stopImageStream().catchError((Object _) {});
      }
      controller.dispose();
    }
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  /// Writes the finished session to history.
  ///
  /// This belongs to the session rather than to the summary screen: the summary
  /// is only a view of the result, and a workout that was actually performed
  /// has to be recorded whether or not the user ever looks at it.
  void _saveSession(WorkoutSessionState state) {
    final repo = ref.read(workoutRepositoryProvider);
    final calories = SessionStats.estimateCalories(
      met: ExerciseAnalyzer.forId(widget.exerciseId).met,
      weightKg: ref.read(userProfileProvider).weightKg,
      durationSeconds: state.elapsedSeconds,
    );

    repo.saveSession({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'workout_id': widget.exerciseId,
      'workout_name': widget.exerciseName,
      'completed_at': DateTime.now().toIso8601String(),
      'duration_seconds': state.elapsedSeconds,
      'total_reps': state.totalReps,
      'avg_form_score': state.avgFormScore,
      'estimated_calories': calories,
      'most_common_error': state.mostCommonError,
      // Left to the AI backend; no coaching text is generated on-device.
      'ai_tip': '',
      'exercises': [
        {
          'exercise_id': widget.exerciseId,
          'exercise_name': widget.exerciseName,
          'sets_completed': state.currentSet,
          'total_reps': state.totalReps,
          'avg_form_score': state.avgFormScore,
          'most_common_error': state.mostCommonError,
        },
      ],
    });

    // Home and Progress both hold cached reads of the box.
    ref.invalidate(sessionHistoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final session =
        ref.watch(workoutSessionNotifierProvider(widget.exerciseId));
    final notifier =
        ref.read(workoutSessionNotifierProvider(widget.exerciseId).notifier);
    final controller = _controller;

    ref.listen<SessionStatus>(
      workoutSessionNotifierProvider(widget.exerciseId)
          .select((s) => s.status),
      (prev, next) {
        if (prev != next) _enqueue(() => _applyStreaming(_wantsFrames(next)));
      },
    );

    // A light tap per counted rep — lighter than the form-fault buzz, so the
    // two cannot be mistaken for each other. The last rep of a set arrives
    // together with setComplete and still raises the count; the reset to zero
    // for the next set does not.
    ref.listen<int>(
      workoutSessionNotifierProvider(widget.exerciseId)
          .select((s) => s.repCount),
      (prev, next) {
        if (next > (prev ?? 0)) HapticFeedback.lightImpact();
      },
    );

    ref.listen<WorkoutSessionState>(
      workoutSessionNotifierProvider(widget.exerciseId),
      (prev, next) {
        _pace.update(
          status: next.status,
          repCount: next.repCount,
          now: DateTime.now(),
        );
        if (next.status == SessionStatus.finished &&
            prev?.status != SessionStatus.finished) {
          _saveSession(next);
          context.go(RouteNames.workoutSummaryPath(widget.exerciseId));
        }
      },
    );

    final hasPreview = controller != null && controller.value.isInitialized;

    // The camera was working and is now gone: the OS reclaimed it for a call
    // or another app. This is a recoverable interruption, and it has to say so
    // and offer a way forward — rendering the bare spinner below would hide
    // the pause button and every other control with it.
    //
    // A deliberate flip passes through the same gap, and must not be dressed
    // up as an interruption on its way through.
    if (!hasPreview && _cameraWasReady && !_isSwitching) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SessionInterruptedOverlay(
          kind: _cameraFailed
              ? SessionInterruption.cameraFailed
              : SessionInterruption.reconnecting,
          onAction: _cameraFailed ? _retryCamera : null,
        ),
      );
    }

    // Genuine cold start — nothing to control yet.
    if (!hasPreview ||
        session.status == SessionStatus.idle ||
        session.status == SessionStatus.initializing) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final isFront =
        _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;
    final absSize = session.absoluteImageSize;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(controller),

          if (session.poses.isNotEmpty && absSize != Size.zero)
            CustomPaint(
              painter: PoseOverlayPainter(
                poses: session.poses,
                absoluteImageSize: absSize,
                isFrontCamera: isFront,
              ),
            ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SessionTopBar(
              exerciseName: widget.exerciseName,
              currentSet: session.currentSet,
              targetSets: session.targetSets,
              progress: sessionProgress(session),
              isPaused: session.status == SessionStatus.paused,
              readElapsed: () => _notifier.liveElapsedSeconds,
              onBack: () => context.pop(),
              onFlipCamera: _isSwitching ? null : _requestCameraSwitch,
              onTogglePause: session.status == SessionStatus.paused
                  ? notifier.resume
                  : notifier.pause,
            ),
          ),

          // The cue rides on top of the rep panel in one column, so the panel
          // can change height without the banner sliding underneath it.
          if (session.status != SessionStatus.resting)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (session.cue != null &&
                      (session.status == SessionStatus.tracking ||
                          session.status == SessionStatus.repComplete)) ...[
                    FormCueBanner(cue: session.cue!),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  RepCounterPanel(
                    repCount: session.repCount,
                    targetReps: session.targetReps,
                    angleLabel: session.angleLabel,
                    angleText: session.jointAngle != null
                        ? '${session.jointAngle!.toStringAsFixed(0)}°'
                        : '--',
                    bodyFound: session.poses.isNotEmpty,
                    repTimeText: _repTimeText(),
                    formScore: _notifier.liveFormScore,
                  ),
                ],
              ),
            ),

          if (session.status == SessionStatus.error &&
              session.errorMessage != null)
            TrackingErrorOverlay(message: session.errorMessage!),

          // A session paused by an interruption needs more than the small
          // top-bar toggle: the user has just come back to the app and has to
          // be told, in one place, that nothing is being counted yet.
          if (session.status == SessionStatus.paused)
            SessionInterruptedOverlay(
              kind: SessionInterruption.paused,
              onAction: notifier.resume,
            ),

          if (session.status == SessionStatus.setComplete)
            SetCompleteOverlay(
              currentSet: session.currentSet,
              targetSets: session.targetSets,
              reps: session.repCount,
            ),

          if (session.status == SessionStatus.resting)
            RestOverlay(
              secondsLeft: session.restSecondsLeft,
              totalSeconds: session.restTotalSeconds,
              nextSet: session.currentSet + 1,
              targetSets: session.targetSets,
              onAdd30: () => notifier.adjustRest(30),
              onSubtract15: () => notifier.adjustRest(-15),
              onSkip: notifier.skipRest,
            ),
        ],
      ),
    );
  }

  /// The last rep's duration for the HUD, e.g. `2.4s`; `--` before the first
  /// rep of a set.
  String _repTimeText() {
    final rep = _pace.lastRep;
    if (rep == null) return '--';
    return '${(rep.inMilliseconds / 1000).toStringAsFixed(1)}s';
  }

  /// Fills the screen without distorting the image.
  ///
  /// Under `StackFit.expand` a bare CameraPreview is handed a tight constraint,
  /// so its own AspectRatio is overridden and the frame is squeezed to whatever
  /// shape the phone happens to be. Sizing it to the sensor's own ratio first
  /// and then cover-fitting keeps the picture true and crops the overflow —
  /// the same transform PoseOverlayPainter maps the skeleton with.
  Widget _buildPreview(CameraController controller) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: SizedBox(
          // previewSize is reported in sensor orientation, which is landscape
          // on essentially every phone; the session is locked to portrait.
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}
