import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import 'widgets/camera_preview_layer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SessionScreen — camera background plus session chrome.
// The HUD (set counter, rep counter, feedback) arrives in Tasks 4.4–4.6.
// ─────────────────────────────────────────────────────────────────────────────

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  @override
  void initState() {
    super.initState();
    // Pose analysis assumes a portrait frame. On web this resolves to a
    // fullscreen request that browsers reject outside a user gesture.
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    super.dispose();
  }

  void _exitSession() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.workoutDetailPath(widget.workoutId));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const CameraPreviewLayer(),
            Align(
              alignment: Alignment.topLeft,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppIconButton(
                    icon: Icons.close_rounded,
                    onTap: _exitSession,
                    tooltip: 'End session',
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
