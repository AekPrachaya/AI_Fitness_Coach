import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../core/services/pose_detection_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/angle_calculator.dart';
import 'widgets/pose_overlay_painter.dart';

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  final int _cameraIndex = 0;

  final _poseService = PoseDetectionService();
  List<Pose> _poses = [];
  Size _absoluteImageSize = Size.zero;
  String _kneeAngleText = '--';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;
    await _startCamera(_cameras[_cameraIndex]);
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
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
    controller.startImageStream(_onFrame);
  }

  void _onFrame(CameraImage image) async {
    final camera = _cameras[_cameraIndex];
    final poses = await _poseService.processFrame(image, camera);
    if (poses == null || !mounted) return;

    // Derive portrait-orientation size from raw image + sensor rotation
    final rot = camera.sensorOrientation;
    final absSize = (rot == 90 || rot == 270)
        ? Size(image.height.toDouble(), image.width.toDouble())
        : Size(image.width.toDouble(), image.height.toDouble());

    String angleText = '--';
    if (poses.isNotEmpty) {
      final lms = poses.first.landmarks;
      final hip = lms[PoseLandmarkType.leftHip];
      final knee = lms[PoseLandmarkType.leftKnee];
      final ankle = lms[PoseLandmarkType.leftAnkle];
      if (hip != null && knee != null && ankle != null &&
          hip.likelihood > 0.5 && knee.likelihood > 0.5 && ankle.likelihood > 0.5) {
        final angle = calculateAngle(hip, knee, ankle);
        angleText = '${angle.toStringAsFixed(0)}°';
      }
    }

    setState(() {
      _poses = poses;
      _absoluteImageSize = absSize;
      _kneeAngleText = angleText;
    });
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _poseService.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final isFront =
        _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera feed
          CameraPreview(controller),

          // Skeleton overlay
          if (_poses.isNotEmpty && _absoluteImageSize != Size.zero)
            CustomPaint(
              painter: PoseOverlayPainter(
                poses: _poses,
                absoluteImageSize: _absoluteImageSize,
                isFrontCamera: isFront,
              ),
            ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: _buildTopBar(context),
          ),

          // Bottom HUD
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
            child: _buildHud(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
            'Squat',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const Spacer(),
          // Placeholder for symmetry
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHud(BuildContext context) {
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
          _hudItem(context, 'เข่า (องศา)', _kneeAngleText),
          Container(width: 1, height: 40, color: AppColors.divider),
          _hudItem(
            context,
            'สถานะ',
            _poses.isEmpty ? 'ไม่เจอร่างกาย' : 'ตรวจจับได้',
            valueColor: _poses.isEmpty ? AppColors.error : AppColors.success,
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
