import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/form_analyzer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'widgets/pose_overlay_painter.dart';
import 'widgets/rest_overlay.dart';
import 'workout_session_notifier.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    final controller = CameraController(
      _cameras[0],
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.bgra8888,
      enableAudio: false,
    );
    await controller.initialize();
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() => _controller = controller);

    final notifier = ref.read(workoutSessionNotifierProvider.notifier);
    await notifier.startSession(_cameras);
    notifier.onCameraReady();

    controller.startImageStream(notifier.processFrame);
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(workoutSessionNotifierProvider);
    final notifier = ref.read(workoutSessionNotifierProvider.notifier);
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized ||
        session.status == SessionStatus.idle ||
        session.status == SessionStatus.initializing) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final isFront = _cameras[0].lensDirection == CameraLensDirection.front;
    final rot = _cameras[0].sensorOrientation;
    final absSize = (rot == 90 || rot == 270)
        ? Size(
            controller.value.previewSize!.height,
            controller.value.previewSize!.width,
          )
        : Size(
            controller.value.previewSize!.width,
            controller.value.previewSize!.height,
          );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera feed
          CameraPreview(controller),

          // Skeleton overlay
          if (session.poses.isNotEmpty)
            CustomPaint(
              painter: PoseOverlayPainter(
                poses: session.poses,
                absoluteImageSize: absSize,
                isFrontCamera: isFront,
              ),
            ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: _buildTopBar(context, session, notifier),
          ),

          // Form feedback banner
          if (session.formResult != null &&
              session.formResult!.feedback.isNotEmpty &&
              session.status == SessionStatus.tracking)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md + 88,
              child: _buildFormBanner(context, session),
            ),

          // Bottom HUD
          if (session.status != SessionStatus.resting)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              child: _buildHud(context, session, notifier),
            ),

          // Rest overlay (full screen)
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Text(
            'Squat  •  Set ${session.currentSet}/${session.targetSets}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const Spacer(),
          // Pause / Resume
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

  Widget _buildHud(
    BuildContext context,
    WorkoutSessionState session,
    WorkoutSessionNotifier notifier,
  ) {
    final angleText = session.kneeAngle != null
        ? '${session.kneeAngle!.toStringAsFixed(0)}°'
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
          _hudItem(context, 'เข่า (องศา)', angleText),
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
