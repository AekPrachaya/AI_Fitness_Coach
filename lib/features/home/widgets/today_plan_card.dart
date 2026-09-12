import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_card.dart';
import '../home_provider.dart';

// ── Gradient map — card background per muscle group ───────────────────────────
// Acceptable hex exception: gradient pairs are semantically tied to workout type.

const _workoutGradients = <String, List<Color>>{
  'upper_body': [Color(0xFF0D2137), Color(0xFF0A3A2A)],
  'lower_body': [Color(0xFF1A0D37), Color(0xFF2A0A3A)],
  'full_body': [Color(0xFF1A2A0A), Color(0xFF0A1A2A)],
  'core': [Color(0xFF1A0A0A), Color(0xFF2A1A0A)],
};

// ── TodayPlanCard ─────────────────────────────────────────────────────────────

class TodayPlanCard extends ConsumerWidget {
  const TodayPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(todaysPlanProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: planAsync.when(
        loading: () => const _TodayPlanSkeleton(),
        error: (err, stack) => _TodayPlanError(
          onRetry: () => ref.invalidate(todaysPlanProvider),
        ),
        data: (plan) => plan == null
            ? const _TodayPlanEmpty()
            : _TodayPlanContent(plan: plan),
      ),
    )
        .animate(delay: 50.ms)
        .fadeIn(duration: 400.ms)
        .slideY(
          begin: 0.06,
          end: 0.0,
          duration: 400.ms,
          curve: Curves.easeOut,
        )
        .scale(
          begin: const Offset(0.97, 0.97),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }
}

// ── Loading state ─────────────────────────────────────────────────────────────

class _TodayPlanSkeleton extends StatelessWidget {
  const _TodayPlanSkeleton();

  @override
  Widget build(BuildContext context) => const AppCard.skeleton(height: 200);
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _TodayPlanEmpty extends StatelessWidget {
  const _TodayPlanEmpty();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AppCard(
      height: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fitness_center_outlined,
            size: 40,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No workout planned for today',
            style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Head to Browse to start a workout',
            style: tt.bodySmall?.copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _TodayPlanError extends StatelessWidget {
  final VoidCallback onRetry;

  const _TodayPlanError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              "Couldn't load today's plan",
              style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ── Full card content ─────────────────────────────────────────────────────────

class _TodayPlanContent extends StatelessWidget {
  final TodaysPlan plan;

  const _TodayPlanContent({required this.plan});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final gradientColors = _workoutGradients[plan.workout.muscleGroup] ??
        [AppColors.surface, AppColors.surfaceElevated];

    return ClipRRect(
      borderRadius: AppRadius.xlAll,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
            ),

            // Layer 2: subtle grid pattern
            Positioned.fill(
              child: CustomPaint(painter: _GridPatternPainter()),
            ),

            // Layer 3: content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Label row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: AppRadius.circleAll,
                          ),
                          child: Text(
                            "TODAY'S PLAN",
                            style: tt.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (plan.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: AppRadius.circleAll,
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 12,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Done',
                                  style: tt.labelSmall?.copyWith(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // B.
                    const SizedBox(height: AppSpacing.sm),

                    // C. Workout name
                    Text(
                      plan.workout.name.toUpperCase(),
                      style: tt.displaySmall?.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.5,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // D.
                    const SizedBox(height: AppSpacing.xs),

                    // E. Metadata badges
                    Row(
                      children: [
                        _MetaBadge(
                          icon: Icons.timer_outlined,
                          label: '${plan.workout.durationMinutes} min',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _MetaBadge(
                          icon: Icons.repeat_rounded,
                          label: '${plan.sets}×${plan.reps}',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        DifficultyBadge(difficulty: plan.workout.difficulty),
                      ],
                    ),

                    // F.
                    const Spacer(),

                    // G. Progress + CTA
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (plan.progress > 0 && !plan.isCompleted) ...[
                                Text(
                                  '${(plan.progress * 100).toInt()}% complete',
                                  style: tt.labelMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xs),
                              AppProgressBar(
                                value: plan.progress,
                                height: 4,
                                fillColor: plan.isCompleted
                                    ? AppColors.accent
                                    : Colors.white.withValues(alpha: 0.9),
                                trackColor:
                                    Colors.white.withValues(alpha: 0.15),
                                animated: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        _PlanCTAButton(plan: plan),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid pattern painter ──────────────────────────────────────────────────────

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Metadata badge ────────────────────────────────────────────────────────────

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 3),
        Text(
          label,
          style: tt.labelMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

// ── CTA button ────────────────────────────────────────────────────────────────

class _PlanCTAButton extends StatefulWidget {
  final TodaysPlan plan;

  const _PlanCTAButton({required this.plan});

  @override
  State<_PlanCTAButton> createState() => _PlanCTAButtonState();
}

class _PlanCTAButtonState extends State<_PlanCTAButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final plan = widget.plan;

    return GestureDetector(
      onTapDown: plan.isActionable
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: plan.isActionable
          ? (_) {
              setState(() => _isPressed = false);
              context.go(RouteNames.workoutDetailPath(plan.workout.id));
            }
          : null,
      onTapCancel: plan.isActionable
          ? () => setState(() => _isPressed = false)
          : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: plan.isActionable
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: AppRadius.circleAll,
                  boxShadow: AppShadows.glow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 16,
                      color: AppColors.background,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      plan.ctaLabel,
                      style: tt.titleSmall?.copyWith(
                        color: AppColors.background,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: AppRadius.circleAll,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Done Today',
                      style: tt.titleSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
