import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/duration_format.dart';

/// The session's top strip: what is being done, how far in, and for how long,
/// with the back, camera-flip and pause controls.
///
/// Sits straight on the camera feed, so it carries its own dark fade — white
/// text over a bright room is otherwise unreadable.
class SessionTopBar extends StatelessWidget {
  const SessionTopBar({
    super.key,
    required this.exerciseName,
    required this.currentSet,
    required this.targetSets,
    required this.progress,
    required this.isPaused,
    required this.readElapsed,
    required this.onBack,
    required this.onFlipCamera,
    required this.onTogglePause,
  });

  final String exerciseName;
  final int currentSet;
  final int targetSets;

  /// Share of the whole workout done, 0–1.
  final double progress;
  final bool isPaused;

  /// Polled once a second for the active session time.
  final int Function() readElapsed;

  final VoidCallback onBack;

  /// Null disables the flip button, e.g. while a switch is under way.
  final VoidCallback? onFlipCamera;
  final VoidCallback onTogglePause;

  static const _progressDuration = Duration(milliseconds: 400);

  /// Room for two standard 48dp icon buttons.
  static const double _sideWidth = AppSpacing.xxl * 2;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.black.withValues(alpha: 0),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sm,
          MediaQuery.paddingOf(context).top + AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Both ends get the same width, so the title sits on the
                // screen's centre line even with two buttons on the right.
                SizedBox(
                  width: _sideWidth,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back',
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: onBack,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        exerciseName,
                        style: tt.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SET $currentSet/$targetSets',
                            style: tt.labelLarge?.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                          Text('  ·  ', style: tt.labelLarge),
                          _ElapsedClock(read: readElapsed),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: _sideWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Switch camera',
                        icon: const Icon(
                          Icons.flip_camera_ios_rounded,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: onFlipCamera,
                      ),
                      IconButton(
                        tooltip: isPaused ? 'Resume' : 'Pause',
                        icon: Icon(
                          isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: onTogglePause,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: ClipRRect(
                borderRadius: AppRadius.circleAll,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress.clamp(0.0, 1.0)),
                  duration: _progressDuration,
                  curve: Curves.easeOut,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: AppSpacing.xs,
                    color: AppColors.accent,
                    backgroundColor: AppColors.borderSubtle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The running session time. Ticks on its own so the rest of the HUD is not
/// rebuilt every second.
class _ElapsedClock extends StatefulWidget {
  const _ElapsedClock({required this.read});

  final int Function() read;

  @override
  State<_ElapsedClock> createState() => _ElapsedClockState();
}

class _ElapsedClockState extends State<_ElapsedClock> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatClock(widget.read()),
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
    );
  }
}
