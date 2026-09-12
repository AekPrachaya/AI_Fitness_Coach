import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../home_provider.dart';

// ── QuickStatsRow ─────────────────────────────────────────────────────────────

class QuickStatsRow extends ConsumerWidget {
  const QuickStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(weekStatsProvider);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.fitness_center_rounded,
            value: '${stats.totalWorkouts}',
            label: 'Workouts',
            suffix: 'this week',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.timer_outlined,
            value: stats.minutesDisplay,
            label: 'Active',
            suffix: 'this week',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_outlined,
            value: '${stats.estimatedCalories}',
            label: 'kcal',
            suffix: 'burned',
          ),
        ),
      ],
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.05, end: 0.0, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ── _StatCard ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String suffix;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon in accent-tinted circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 16, color: AppColors.accent),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Count-up stat number
          _CountUpValue(value: value),

          const SizedBox(height: AppSpacing.xs),

          // Label
          Text(
            label,
            style: tt.labelLarge?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),

          // Suffix
          Text(
            suffix,
            style: tt.labelSmall?.copyWith(color: AppColors.textDisabled),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── _CountUpValue ─────────────────────────────────────────────────────────────
// Animates from 0 to the target value over 800ms on first render.
// Works for numeric strings ("120") and formatted strings ("1h 45m").

class _CountUpValue extends StatefulWidget {
  final String value;
  const _CountUpValue({required this.value});

  @override
  State<_CountUpValue> createState() => _CountUpValueState();
}

class _CountUpValueState extends State<_CountUpValue>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  int get _targetInt {
    final match = RegExp(r'\d+').firstMatch(widget.value);
    return int.tryParse(match?.group(0) ?? '0') ?? 0;
  }

  bool get _isNumeric => RegExp(r'^\d+$').hasMatch(widget.value);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) {
        final displayed = _isNumeric
            ? '${(_targetInt * _anim.value).round()}'
            : _anim.value >= 1.0
                ? widget.value
                : '${(_targetInt * _anim.value).round()}';

        return Text(
          displayed,
          style: tt.headlineSmall?.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}
