import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_format.dart';
import '../../../shared/models/session_data.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import 'summary_provider.dart';
import 'summary_tip.dart';
import 'widgets/confetti_burst.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutSummaryScreen — the result of one stored session. Reached two ways:
//
//   * straight from a finished session, with no session id: shows the newest
//     session for the workout and celebrates it;
//   * as a replay (`?session=<id>`): shows that session, without confetti.
//
// The session screen has already saved the result before navigating here, so
// this screen only reads.
// ─────────────────────────────────────────────────────────────────────────────

class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.workoutId,
    this.sessionId,
  });

  final String workoutId;

  /// A specific stored session to show. Null means "the one just finished".
  final String? sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(
      summarySessionProvider((workoutId: workoutId, sessionId: sessionId)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: session == null
            ? _EmptyState(workoutId: workoutId)
            : Stack(
                children: [
                  _SummaryBody(
                    session: session,
                    workoutId: workoutId,
                    isPastSession: sessionId != null,
                  ),
                  if (sessionId == null)
                    const Positioned.fill(child: ConfettiBurst()),
                ],
              ),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({
    required this.session,
    required this.workoutId,
    required this.isPastSession,
  });

  final SessionData session;
  final String workoutId;

  /// Opened from History rather than straight after a workout.
  final bool isPastSession;

  @override
  Widget build(BuildContext context) {
    final sections = [
      _Header(session: session),
      _StatsGrid(session: session),
      if (session.exercises.isNotEmpty)
        _ExerciseBreakdown(exercises: session.exercises),
      _TipCard(tip: summaryTipFor(session)),
      // The session's own workout, not the route's: a replay link can name a
      // session from a different workout, and "Do It Again" must repeat what
      // is on screen.
      if (isPastSession)
        const _BackToHistory()
      else
        _Actions(
          workoutId:
              session.workoutId.isNotEmpty ? session.workoutId : workoutId,
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.lg),
            sections[i]
                .animate(delay: (i * 80).ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.05, curve: Curves.easeOut),
          ],
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.session});

  final SessionData session;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _completedLabel {
    final at = session.completedAt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${_months[at.month - 1]} ${at.day} · ${two(at.hour)}:${two(at.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.accentGlow,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.accent,
            size: 40,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'WORKOUT COMPLETE',
          style: tt.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          session.workoutName,
          style: tt.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _completedLabel,
          style: tt.labelMedium?.copyWith(color: AppColors.textSecondary),
        ),
        if (session.avgFormScore > 0) ...[
          const SizedBox(height: AppSpacing.md),
          FormScoreBadge(score: session.avgFormScore),
        ],
      ],
    );
  }
}

// ── Stats grid (2×2) ─────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.session});

  final SessionData session;

  @override
  Widget build(BuildContext context) {
    final score = session.avgFormScore;
    final graded = score > 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.timer_outlined,
                label: 'DURATION',
                value: formatClock(session.durationSeconds),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatTile(
                icon: Icons.repeat_rounded,
                label: 'TOTAL REPS',
                value: '${session.totalReps}',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.accessibility_new_rounded,
                label: 'FORM SCORE',
                // Zero means no rep was graded, not a zero-percent workout.
                // Truncated like FormScoreBadge so both read the same number.
                value: graded ? '${score.toInt()}%' : '--',
                valueColor: graded
                    ? AppColors.formScoreColor(score)
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatTile(
                icon: Icons.local_fire_department_rounded,
                label: 'KCAL',
                value: '${session.estimatedCalories}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  style: tt.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: tt.displaySmall?.copyWith(color: valueColor),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Per-exercise breakdown ───────────────────────────────────────────────────

class _ExerciseBreakdown extends StatelessWidget {
  const _ExerciseBreakdown({required this.exercises});

  final List<ExerciseResult> exercises;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Exercises', style: tt.titleLarge),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < exercises.length; i++) ...[
                if (i > 0)
                  const Divider(
                    color: AppColors.divider,
                    height: AppSpacing.lg,
                  ),
                _ExerciseRow(result: exercises[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.result});

  final ExerciseResult result;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final sets = result.setsCompleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.exerciseName, style: tt.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$sets ${sets == 1 ? 'set' : 'sets'} · '
                    '${result.totalReps} reps',
                    style: tt.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (result.avgFormScore > 0)
              FormScoreBadge(score: result.avgFormScore),
          ],
        ),
        if (result.mostCommonError.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  result.mostCommonError,
                  style: tt.bodySmall?.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Coach tip ────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final SummaryTip tip;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final focus = tip.focus;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'COACH TIP',
                style: tt.labelLarge?.copyWith(color: AppColors.accent),
              ),
            ],
          ),
          if (focus != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Most common: $focus',
              style: tt.bodySmall?.copyWith(color: AppColors.warning),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(tip.message, style: tt.bodyMedium),
        ],
      ),
    );
  }
}

// ── Actions ──────────────────────────────────────────────────────────────────

class _Actions extends StatelessWidget {
  const _Actions({required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPrimaryButton(
          label: 'Next Exercise',
          leadingIcon: Icons.arrow_forward_rounded,
          onTap: () =>
              context.go(RouteNames.exerciseTransitionPath(workoutId)),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSecondaryButton(
          label: 'Do It Again',
          leadingIcon: Icons.replay_rounded,
          onTap: () => context.go(RouteNames.preWorkoutPath(workoutId)),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppGhostButton(
          label: 'Done',
          onTap: () => context.go(RouteNames.home),
        ),
      ],
    );
  }
}

/// A past session has nothing to continue, so its only action leads back.
/// Opened by deep link there is nothing to pop, so it goes to Progress.
class _BackToHistory extends StatelessWidget {
  const _BackToHistory();

  @override
  Widget build(BuildContext context) {
    return AppSecondaryButton(
      label: 'Back to History',
      leadingIcon: Icons.arrow_back_rounded,
      onTap: () =>
          context.canPop() ? context.pop() : context.go(RouteNames.progress),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insights_outlined,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No workout recorded yet',
              style: tt.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Finish a session to see its summary here.',
              style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSecondaryButton(
              label: 'Back to Workout',
              fullWidth: false,
              onTap: () => context.go(RouteNames.workoutDetailPath(workoutId)),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(
            begin: 0.05,
            curve: Curves.easeOut,
          ),
    );
  }
}
