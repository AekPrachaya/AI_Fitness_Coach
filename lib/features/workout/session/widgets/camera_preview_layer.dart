import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import 'camera_permission_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CameraPreviewLayer — full-bleed camera background for the workout session.
// Owns the CameraController: permission, initialization, lifecycle, flip, and
// every failure state. Deliberately knows nothing about pose detection; frames
// leave through [onFrame] so an analysis engine can be attached above it.
// ─────────────────────────────────────────────────────────────────────────────

typedef CameraFrameCallback = void Function(
  CameraImage image,
  CameraDescription camera,
);

enum CameraLayerStatus {
  initializing,
  ready,
  permissionDenied,
  permissionPermanentlyDenied,
  noCamera,
  error,
}

class CameraPreviewLayer extends StatefulWidget {
  const CameraPreviewLayer({
    super.key,
    this.onFrame,
    this.resolution = ResolutionPreset.medium,
    this.initialLens = CameraLensDirection.front,
    this.showFlipButton = true,
  });

  /// When null the image stream is never started — a plain preview costs less.
  final CameraFrameCallback? onFrame;
  final ResolutionPreset resolution;
  final CameraLensDirection initialLens;
  final bool showFlipButton;

  @override
  State<CameraPreviewLayer> createState() => _CameraPreviewLayerState();
}

class _CameraPreviewLayerState extends State<CameraPreviewLayer>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  late CameraLensDirection _lens = widget.initialLens;

  CameraLayerStatus _status = CameraLayerStatus.initializing;
  String? _errorMessage;

  /// Guards against a slow initialize() completing after a flip or a teardown.
  int _generation = 0;
  bool _busy = false;
  bool _flipping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Not _teardown(): it calls setState, which the framework forbids here.
    _generation++;
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Chrome reports `inactive` on tab blur, which would kill a working preview.
    if (kIsWeb) return;

    if (state == AppLifecycleState.resumed) {
      if (_controller == null) _initialize();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _teardown();
    }
  }

  // ── Camera ──────────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    if (_busy) return;
    _busy = true;
    _setStatus(CameraLayerStatus.initializing);

    try {
      if (!await _ensurePermission()) return;

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _setStatus(CameraLayerStatus.noCamera);
        return;
      }

      final description = _cameras.firstWhere(
        (camera) => camera.lensDirection == _lens,
        orElse: () => _cameras.first,
      );
      _lens = description.lensDirection;

      final controller = CameraController(
        description,
        widget.resolution,
        enableAudio: false,
        imageFormatGroup: _imageFormatGroup(),
      );

      final generation = ++_generation;
      await controller.initialize();
      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }

      try {
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (_) {
        // Unimplemented on web and unsupported on some devices; the lock is a
        // nicety and must never cost us the preview.
      }

      await _startStream(controller, description);
      // Starting the stream is another await the widget could not survive.
      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _status = CameraLayerStatus.ready;
        _errorMessage = null;
      });
    } on CameraException catch (e) {
      if (_isPermissionCode(e.code)) {
        _setStatus(CameraLayerStatus.permissionDenied);
      } else {
        _errorMessage = e.description ?? e.code;
        _setStatus(CameraLayerStatus.error);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraLayerStatus.error);
    } finally {
      _busy = false;
    }
  }

  Future<void> _startStream(
    CameraController controller,
    CameraDescription description,
  ) async {
    final onFrame = widget.onFrame;
    // Streaming is unimplemented on web; the preview must survive without it.
    if (onFrame == null || kIsWeb) return;
    try {
      await controller.startImageStream((image) => onFrame(image, description));
    } on CameraException catch (_) {
      // Preview stays usable even when frames are unavailable.
    }
  }

  Future<void> _teardown() async {
    final controller = _controller;
    if (controller == null) return;

    _generation++;
    if (mounted) {
      setState(() => _controller = null);
    } else {
      _controller = null;
    }

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } on CameraException catch (_) {
      // Nothing left to do — the controller is going away regardless.
    }
    await controller.dispose();
  }

  Future<void> _flipCamera() async {
    // _busy alone is not enough: it is only held during _initialize, leaving a
    // window during _teardown where a second tap could interleave.
    if (_busy || _flipping || _cameras.length < 2) return;
    _flipping = true;
    try {
      _lens = _lens == CameraLensDirection.front
          ? CameraLensDirection.back
          : CameraLensDirection.front;
      await _teardown();
      await _initialize();
    } finally {
      _flipping = false;
    }
  }

  // ── Permission ──────────────────────────────────────────────────────────

  /// Returns true when the camera may be opened.
  Future<bool> _ensurePermission() async {
    // On web, permission_handler can report `denied` while getUserMedia would
    // succeed — let the browser prompt and let CameraException be the truth.
    if (kIsWeb) return true;

    var status = await Permission.camera.status;
    if (!status.isGranted) status = await Permission.camera.request();
    if (status.isGranted) return true;

    _setStatus(status.isPermanentlyDenied || status.isRestricted
        ? CameraLayerStatus.permissionPermanentlyDenied
        : CameraLayerStatus.permissionDenied);
    return false;
  }

  bool _isPermissionCode(String code) =>
      code == 'CameraAccessDenied' ||
      code == 'CameraAccessDeniedWithoutPrompt' ||
      code == 'CameraAccessRestricted';

  ImageFormatGroup? _imageFormatGroup() {
    if (kIsWeb) return null;
    return defaultTargetPlatform == TargetPlatform.android
        ? ImageFormatGroup.yuv420
        : ImageFormatGroup.bgra8888;
  }

  void _setStatus(CameraLayerStatus status) {
    if (!mounted) {
      _status = status;
      return;
    }
    setState(() => _status = status);
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady =
        _status == CameraLayerStatus.ready && controller != null;

    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isReady)
            _CoverFitPreview(controller: controller)
          else
            _statusView(),
          if (isReady && widget.showFlipButton && _cameras.length > 1)
            Align(
              alignment: Alignment.topRight,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppIconButton(
                    icon: Icons.cameraswitch_rounded,
                    onTap: _busy ? null : _flipCamera,
                    tooltip: 'Flip camera',
                    size: 40,
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    iconColor: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusView() => switch (_status) {
        CameraLayerStatus.initializing => const _CameraStarting(),
        CameraLayerStatus.ready => const SizedBox.shrink(),
        CameraLayerStatus.permissionDenied => _CameraLayerMessage(
            icon: Icons.videocam_off_rounded,
            title: 'Camera access needed',
            message: 'FormAI needs your camera to track your form during '
                'the workout.',
            actionLabel: 'Allow camera',
            onAction: _initialize,
          ),
        CameraLayerStatus.permissionPermanentlyDenied => _CameraLayerMessage(
            icon: Icons.videocam_off_rounded,
            title: 'Camera access blocked',
            message: 'Camera permission is turned off for FormAI. Enable it '
                'in your device settings to start the session.',
            actionLabel: 'Open settings',
            onAction: () => showCameraSettingsDialog(context),
          ),
        CameraLayerStatus.noCamera => const _CameraLayerMessage(
            icon: Icons.no_photography_rounded,
            title: 'No camera found',
            message: 'This device has no camera available for pose tracking.',
          ),
        CameraLayerStatus.error => _CameraLayerMessage(
            icon: Icons.error_outline_rounded,
            title: 'Camera could not start',
            message: _errorMessage ?? 'Something went wrong opening the camera.',
            actionLabel: 'Retry',
            onAction: _initialize,
          ),
      };
}

// ── Cover-fit preview ─────────────────────────────────────────────────────────

/// [CameraPreview] letterboxes itself inside an [AspectRatio]. This forces the
/// same box to cover the screen instead, cropping the overflowing axis.
class _CoverFitPreview extends StatelessWidget {
  const _CoverFitPreview({required this.controller});

  final CameraController controller;

  /// Arbitrary box the preview ratio is expressed in before being scaled up.
  static const double _base = 1000.0;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    // CameraPreview applies the same inversion internally in portrait.
    final ratio = isLandscape
        ? controller.value.aspectRatio
        : 1 / controller.value.aspectRatio;

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _base * ratio,
            height: _base,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

// ── Status views ──────────────────────────────────────────────────────────────

class _CameraStarting extends StatelessWidget {
  const _CameraStarting();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_camera_rounded,
            size: 48,
            color: AppColors.accent,
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(
                begin: 0.9,
                end: 1.1,
                duration: 900.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Starting camera…',
            style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CameraLayerMessage extends StatelessWidget {
  const _CameraLayerMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final label = actionLabel;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.warning),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: tt.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: tt.bodySmall?.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (label != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppSecondaryButton(label: label, onTap: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
