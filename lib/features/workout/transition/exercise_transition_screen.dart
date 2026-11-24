import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/exercise_display.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import 'transition_provider.dart';

/// The beat between two exercises: what was just finished, what comes next,
/// and a short countdown that moves on by itself.
///
/// Auto-advance lands on the next exercise's pre-workout screen rather than
/// straight into a session — the camera still has to be set up for the new
/// movement, and that is the screen that does it.
class ExerciseTransitionScreen extends ConsumerStatefulWidget {
  const ExerciseTransitionScreen({super.key, required this.workoutId});

  /// The exercise just finished.
  final String workoutId;

  @override
  ConsumerState<ExerciseTransitionScreen> createState() =>
      _ExerciseTransitionScreenState();
}

class _ExerciseTransitionScreenState
    extends ConsumerState<ExerciseTransitionScreen> {
  static const int _countdownSeconds = 10;

  int _secondsLeft = _countdownSeconds;
  Timer? _ticker;

  /// Set once navigation has been fired, so the countdown and a button press
  /// landing in the same moment cannot both navigate.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    // The timer lives in State, not a provider: it must die with this screen,
    // or it would navigate after the user had already left.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    if (_secondsLeft > 1) {
      setState(() => _secondsLeft--);
      return;
    }
    setState(() => _secondsLeft = 0);
    final next = ref
        .read(exerciseTransitionProvider(widget.workoutId))
        .valueOrNull
        ?.next;
    // Still loading at zero (unlikely: a local asset) — the next tick retries.
    if (next != null) _startNext(next);
  }

  void _startNext(Workout next) => _leave(RouteNames.preWorkoutPath(next.id));

  void _leave(String path) {
    if (_leaving) return;
    _leaving = true;
    _ticker?.cancel();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final transition = ref.watch(exerciseTransitionProvider(widget.workoutId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: transition.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (_, _) => _NothingNext(onHome: () => _leave(RouteNames.home)),
          data: (t) {
            final next = t.next;
            if (next == null) {
              return _NothingNext(onHome: () => _leave(RouteNames.home));
            }
            return _TransitionBody(
              currentName: t.current?.name ?? displayNameFor(widget.workoutId),
              next: next,
              secondsLeft: _secondsLeft,
              totalSeconds: _countdownSeconds,
              onStartNow: () => _startNext(next),
              onNotNow: () => _leave(RouteNames.home),
            );
          },
        ),
      ),
    );
  }
}

class _TransitionBody extends StatelessWidget {
  const _TransitionBody({
    required this.currentName,
    required this.next,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.onStartNow,
    required this.onNotNow,
  });

  final String currentName;
  final Workout next;
  final int secondsLeft;
  final int totalSeconds;
  final VoidCallback onStartNow;
  final VoidCallback onNotNow;

  static const double _ringRadius = 56;
  static const double _ringWidth = 6;
  static const double _arrowSize = 32;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final calm = MediaQuery.disableAnimationsOf(context);

    Widget arrow = const Icon(
      Icons.keyboard_double_arrow_down_rounded,
      color: AppColors.accent,
      size: _arrowSize,
    );
    if (!calm) {
      arrow = arrow
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: -AppSpacing.xs,
            end: AppSpacing.xs,
            duration: 700.ms,
            curve: Curves.easeInOut,
          );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('UP NEXT', style: tt.displaySmall, textAlign: TextAlign.center)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05, curve: Curves.easeOut),
          const SizedBox(height: AppSpacing.lg),
          _DoneCard(name: currentName)
              .animate(delay: 80.ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.08, curve: Curves.easeOut),
          const SizedBox(height: AppSpacing.sm),
          Center(child: arrow),
          const SizedBox(height: AppSpacing.sm),
          _NextCard(workout: next)
              .animate(delay: 240.ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.08, curve: Curves.easeOut),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: CircularPercentIndicator(
              radius: _ringRadius,
              lineWidth: _ringWidth,
              percent: (secondsLeft / totalSeconds).clamp(0.0, 1.0),
              animation: !calm,
              animateFromLastPercent: true,
              animationDuration: 900,
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: AppColors.accent,
              backgroundColor: AppColors.borderSubtle,
              center: Text(
                '$secondsLeft',
                style: tt.displayMedium?.copyWith(color: AppColors.accent),
              ),
            ),
          ).animate(delay: 320.ms).fadeIn(duration: 300.ms),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'STARTING AUTOMATICALLY',
            style: tt.labelMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: 'Start Now',
            leadingIcon: Icons.play_arrow_rounded,
            onTap: onStartNow,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppGhostButton(label: 'Not Now', onTap: onNotNow),
        ],
      ),
    );
  }
}

/// The exercise just finished, dimmed and ticked off.
class _DoneCard extends StatelessWidget {
  const _DoneCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: tt.titleLarge?.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('DONE', style: tt.labelLarge?.copyWith(color: AppColors.accent)),
        ],
      ),
    );
  }
}

/// The exercise coming up, with the targets it will start with.
class _NextCard extends StatelessWidget {
  const _NextCard({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AppCard(
      elevated: true,
      border: Border.all(color: AppColors.accent),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayNameFor(workout.muscleGroup).toUpperCase(),
            style: tt.labelLarge?.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(workout.name, style: tt.displayMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${workout.defaultSets} SETS × ${workout.defaultReps} REPS'
            '  ·  ~${workout.durationMinutes} MIN',
            style: tt.labelLarge,
          ),
        ],
      ),
    );
  }
}

/// Shown when the catalogue has nothing else to move on to.
class _NothingNext extends StatelessWidget {
  const _NothingNext({required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ALL DONE', style: tt.displaySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No other exercise to move on to.',
              style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(label: 'Back to Home', onTap: onHome),
          ],
        ),
      ),
    );
  }
}
