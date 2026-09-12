import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../detail/workout_detail_provider.dart';
import 'pre_workout_provider.dart';
import 'widgets/camera_permission_dialog.dart';
import 'widgets/countdown_overlay.dart';
import 'widgets/position_guide.dart';
import 'widgets/setup_checklist_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PreWorkoutScreen — setup check before the camera session starts.
// ConsumerStatefulWidget because it owns the countdown Timer: a Timer living in
// a provider would outlive a pop and navigate into the session after the user
// has already left.
// ─────────────────────────────────────────────────────────────────────────────

class PreWorkoutScreen extends ConsumerStatefulWidget {
  const PreWorkoutScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  ConsumerState<PreWorkoutScreen> createState() => _PreWorkoutScreenState();
}

class _PreWorkoutScreenState extends ConsumerState<PreWorkoutScreen>
    with WidgetsBindingObserver {
  static const int _countdownStart = 3;
  static const Duration _goHold = Duration(milliseconds: 600);

  Timer? _timer;
  int? _count;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncCameraStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Also covers coming back from the system settings page.
    if (state == AppLifecycleState.resumed) _syncCameraStatus();
  }

  // ── Camera permission ───────────────────────────────────────────────────

  /// Reads the live OS status rather than the Hive flag from onboarding, which
  /// goes stale as soon as the user revokes access in system settings.
  Future<void> _syncCameraStatus() async {
    final status = await Permission.camera.status;
    if (!mounted) return;
    ref
        .read(preWorkoutNotifierProvider(widget.workoutId).notifier)
        .setCameraGranted(status.isGranted);
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    ref
        .read(preWorkoutNotifierProvider(widget.workoutId).notifier)
        .setCameraGranted(status.isGranted);
    if (status == PermissionStatus.permanentlyDenied) {
      showCameraSettingsDialog(context);
    }
  }

  // ── Countdown ───────────────────────────────────────────────────────────

  void _startCountdown() {
    setState(() => _count = _countdownStart);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = (_count ?? 1) - 1;
      setState(() => _count = next);
      if (next > 0) return;
      timer.cancel();
      _timer = null;
      _goToSession();
    });
  }

  void _cancelCountdown() {
    _timer?.cancel();
    _timer = null;
    setState(() => _count = null);
  }

  Future<void> _goToSession() async {
    await Future<void>.delayed(_goHold);
    // _count is null when the countdown was cancelled during the "GO" hold.
    if (!mounted || _count == null) return;
    context.go(RouteNames.sessionPath(widget.workoutId));
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(workoutDetailProvider(widget.workoutId));
    // Watched here, not only in the children: the checklist provider is
    // autoDispose, and while the workout is still loading no child is mounted
    // to keep it alive — the camera status written in initState would be lost.
    final setup = ref.watch(preWorkoutNotifierProvider(widget.workoutId));
    final isCounting = _count != null;

    return PopScope(
      canPop: !isCounting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelCountdown();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: workoutAsync.when(
                loading: () => const _PreWorkoutSkeleton(),
                error: (_, _) => _PreWorkoutError(
                  onRetry: () =>
                      ref.invalidate(workoutDetailProvider(widget.workoutId)),
                ),
                data: (workout) => workout == null
                    ? const _NotFound()
                    : _PreWorkoutContent(
                        workout: workout,
                        workoutId: widget.workoutId,
                        setup: setup,
                        isCounting: isCounting,
                        onRequestCamera: _requestCamera,
                      ),
              ),
            ),
            bottomNavigationBar: workoutAsync.valueOrNull == null
                ? null
                : _BeginBar(
                    setup: setup,
                    isCounting: isCounting,
                    onBegin: _startCountdown,
                  ),
          ),
          if (_count case final int count)
            CountdownOverlay(count: count, onCancel: _cancelCountdown),
        ],
      ),
    );
  }
}

// ── _PreWorkoutContent ────────────────────────────────────────────────────────

class _PreWorkoutContent extends ConsumerWidget {
  const _PreWorkoutContent({
    required this.workout,
    required this.workoutId,
    required this.setup,
    required this.isCounting,
    required this.onRequestCamera,
  });

  final Workout workout;
  final String workoutId;
  final PreWorkoutState setup;
  final bool isCounting;
  final VoidCallback onRequestCamera;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final plan = ref.watch(workoutPlanProvider(workoutId));
    final notifier = ref.read(preWorkoutNotifierProvider(workoutId).notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Back ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: AppIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: isCounting ? null : () => context.pop(),
              size: 40,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Title ─────────────────────────────────────────────────────
          Text(
            'GET READY',
            style: tt.labelLarge?.copyWith(color: AppColors.accent),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: AppSpacing.xs),

          Text(
            workout.name.toUpperCase(),
            style: tt.displayMedium?.copyWith(height: 1.0),
          )
              .animate(delay: 60.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.08, duration: 300.ms, curve: Curves.easeOut),

          const SizedBox(height: AppSpacing.lg),

          // ── Plan summary ──────────────────────────────────────────────
          AppCard(
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _PlanCell(label: 'SETS', value: '${plan.sets}'),
                  const _CellDivider(),
                  _PlanCell(label: 'REPS', value: '${plan.reps}'),
                  const _CellDivider(),
                  _PlanCell(
                    label: 'MODE',
                    value: plan.mode == 'beginner' ? 'BEGINNER' : 'PRO',
                  ),
                ],
              ),
            ),
          )
              .animate(delay: 140.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05, duration: 300.ms, curve: Curves.easeOut),

          const SizedBox(height: AppSpacing.lg),

          // ── Setup checklist ───────────────────────────────────────────
          _SectionHeader(
            title: 'SETUP CHECKLIST',
            trailing: Text(
              '${setup.completedCount}/3',
              style: tt.labelLarge?.copyWith(
                color: setup.isReady
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
            ),
          ).animate(delay: 240.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: AppSpacing.sm),

          AppCard(
            child: Column(
              children: [
                SetupChecklistItem(
                  index: 0,
                  icon: Icons.camera_alt_rounded,
                  title: 'Camera access',
                  subtitle: 'Needed for real-time pose detection',
                  isDone: setup.cameraGranted,
                  actionLabel: 'Allow',
                  onTap: onRequestCamera,
                ),
                const Divider(color: AppColors.divider, height: 1),
                SetupChecklistItem(
                  index: 1,
                  icon: Icons.open_in_full_rounded,
                  title: 'Enough space',
                  subtitle: 'About 2 m of clear floor around you',
                  isDone: setup.spaceConfirmed,
                  actionLabel: 'Confirm',
                  onTap: notifier.confirmSpace,
                ),
                const Divider(color: AppColors.divider, height: 1),
                SetupChecklistItem(
                  index: 2,
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Good lighting',
                  subtitle: 'Face a light source, avoid backlight',
                  isDone: setup.lightingConfirmed,
                  actionLabel: 'Confirm',
                  onTap: notifier.confirmLighting,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Position guide ────────────────────────────────────────────
          const _SectionHeader(title: 'POSITION GUIDE')
              .animate(delay: 520.ms)
              .fadeIn(duration: 300.ms),

          const SizedBox(height: AppSpacing.sm),

          const PositionGuide().animate(delay: 560.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Prop your phone against a wall or stand so the whole of your '
            'body stays inside the frame.',
            style: tt.bodySmall?.copyWith(height: 1.5),
          ).animate(delay: 620.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ── _BeginBar ─────────────────────────────────────────────────────────────────

class _BeginBar extends StatelessWidget {
  const _BeginBar({
    required this.setup,
    required this.isCounting,
    required this.onBegin,
  });

  final PreWorkoutState setup;
  final bool isCounting;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final (String status, Color statusColor) = switch (setup) {
      _ when setup.isReady => ("You're all set", AppColors.accent),
      _ when !setup.cameraGranted => (
          'Camera access is required to start',
          AppColors.warning,
        ),
      _ => ('Confirm the remaining checks to start', AppColors.textSecondary),
    };

    return Container(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(status, style: tt.labelLarge?.copyWith(color: statusColor)),
              const SizedBox(height: AppSpacing.sm),
              AppPrimaryButton(
                label: 'Begin',
                onTap: setup.isReady && !isCounting ? onBegin : null,
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: 100.ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ── Small pieces ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: tt.titleSmall?.copyWith(letterSpacing: 1.2)),
        ?trailing,
      ],
    );
  }
}

class _PlanCell extends StatelessWidget {
  const _PlanCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        children: [
          // Scaled down so a long mode label ("BEGINNER") still fits one line.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: tt.displaySmall, maxLines: 1),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: tt.labelLarge),
        ],
      ),
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        color: AppColors.divider,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      );
}

// ── Async states ──────────────────────────────────────────────────────────────

class _PreWorkoutSkeleton extends StatelessWidget {
  const _PreWorkoutSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard.skeleton(height: 40, width: 40),
            SizedBox(height: AppSpacing.lg),
            AppCard.skeleton(height: 56),
            SizedBox(height: AppSpacing.lg),
            AppCard.skeleton(height: 88),
            SizedBox(height: AppSpacing.lg),
            AppCard.skeleton(height: 180),
          ],
        ),
      );
}

class _PreWorkoutError extends StatelessWidget {
  const _PreWorkoutError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.warning, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text('Could not load exercise', style: tt.titleMedium),
          const SizedBox(height: AppSpacing.md),
          AppGhostButton(label: 'Retry', onTap: onRetry),
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          Text('Exercise not found', style: tt.titleMedium),
          const SizedBox(height: AppSpacing.md),
          AppGhostButton(label: 'Go back', onTap: () => context.pop()),
        ],
      ),
    );
  }
}
