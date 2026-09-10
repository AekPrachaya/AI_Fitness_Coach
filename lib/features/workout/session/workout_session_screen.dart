import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/exercise_analyzer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'widgets/pose_overlay_painter.dart';
import 'widgets/rest_overlay.dart';
import 'widgets/set_complete_overlay.dart';
import 'widgets/tracking_error_overlay.dart';
import 'workout_session_notifier.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  final String exerciseId;

  /// Display name, e.g. 'Bicep Curls' — carried through so the summary and the
  /// stored history never show the raw id.
  final String exerciseName;

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
    await notifier.startSession();
    notifier.onCameraReady();
  }

  Future<void> _startCamera(int index) async {
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.medium,
      // Must match what PoseDetectionService decodes: BGRA on iOS,
      // YUV 420 on Android. bgra8888 is not supported by the Android camera.
      imageFormatGroup:
          Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      enableAudio: false,
    );
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    _isStreaming = false;
    setState(() => _controller = controller);

    await _applyStreaming(_wantsFrames(
      ref.read(workoutSessionNotifierProvider(widget.exerciseId)).status,
    ));
  }

  /// Brings the image stream in line with [wanted]. Safe to call repeatedly.
  Future<void> _applyStreaming(bool wanted) async {
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

  /// Restores the camera after the app comes back to the foreground.
  Future<void> _ensureCamera() async {
    if (!mounted || _controller != null || _cameras.isEmpty) return;
    await _startCamera(_cameraIndex);
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

    ref.listen<WorkoutSessionState>(
      workoutSessionNotifierProvider(widget.exerciseId),
      (prev, next) {
        if (next.status == SessionStatus.finished &&
            prev?.status != SessionStatus.finished) {
          context.go(RouteNames.workoutSummary, extra: {
            'exerciseId': widget.exerciseId,
            'exerciseName': widget.exerciseName,
            'setsCompleted': next.currentSet,
            'targetSets': next.targetSets,
            'totalReps': next.totalReps,
            'durationSeconds': next.elapsedSeconds,
            'avgFormScore': next.avgFormScore,
            'mostCommonError': next.mostCommonError,
          });
        }
      },
    );

    if (controller == null ||
        !controller.value.isInitialized ||
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
          CameraPreview(controller),

          if (session.poses.isNotEmpty && absSize != Size.zero)
            CustomPaint(
              painter: PoseOverlayPainter(
                poses: session.poses,
                absoluteImageSize: absSize,
                isFrontCamera: isFront,
              ),
            ),

          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: _buildTopBar(context, session, notifier),
          ),

          if (session.formResult != null &&
              session.formResult!.feedback.isNotEmpty &&
              session.status == SessionStatus.tracking)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom:
                  MediaQuery.of(context).padding.bottom + AppSpacing.md + 88,
              child: _buildFormBanner(context, session),
            ),

          if (session.status != SessionStatus.resting)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              child: _buildHud(context, session),
            ),

          if (session.status == SessionStatus.error &&
              session.errorMessage != null)
            TrackingErrorOverlay(message: session.errorMessage!),

          if (session.status == SessionStatus.setComplete)
            SetCompleteOverlay(
              currentSet: session.currentSet,
              targetSets: session.targetSets,
              reps: session.repCount,
            ),

          if (session.status == SessionStatus.resting)
            RestOverlay(
              secondsLeft: session.restSecondsLeft,
              currentSet: session.currentSet + 1,
              targetSets: session.targetSets,
              onSkip: notifier.skipRest,
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WorkoutSessionState session,
    WorkoutSessionNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          Text(
            'Set ${session.currentSet}/${session.targetSets}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded,
                color: AppColors.textPrimary),
            onPressed: _isSwitching ? null : _requestCameraSwitch,
          ),
          IconButton(
            icon: Icon(
              session.status == SessionStatus.paused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: session.status == SessionStatus.paused
                ? notifier.resume
                : notifier.pause,
          ),
        ],
      ),
    );
  }

  Widget _buildFormBanner(BuildContext context, WorkoutSessionState session) {
    final result = session.formResult!;
    final color = switch (result.score) {
      FormScore.good => AppColors.scoreGood,
      FormScore.fair => AppColors.scoreOk,
      FormScore.poor => AppColors.scorePoor,
    };
    final icon = switch (result.score) {
      FormScore.good => Icons.check_circle_rounded,
      FormScore.fair => Icons.warning_amber_rounded,
      FormScore.poor => Icons.cancel_rounded,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              result.feedback,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHud(BuildContext context, WorkoutSessionState session) {
    final angleText = session.jointAngle != null
        ? '${session.jointAngle!.toStringAsFixed(0)}°'
        : '--';
    final bodyFound = session.poses.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _hudItem(context, 'Reps', '${session.repCount}'),
          Container(width: 1, height: 40, color: AppColors.divider),
          _hudItem(context, session.angleLabel, angleText),
          Container(width: 1, height: 40, color: AppColors.divider),
          _hudItem(
            context,
            'สถานะ',
            bodyFound ? 'พบแล้ว' : 'ไม่เจอ',
            valueColor: bodyFound ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _hudItem(
    BuildContext context,
    String label,
    String value, {
    Color valueColor = AppColors.accent,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
