import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/mock_data.dart';
import '../../../shared/widgets/app_badge.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String _formattedDate() {
  final now = DateTime.now();
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
}

int _getStreakCount() {
  try {
    final box = Hive.box(MockData.boxSessionHistory);
    final sessions = box.get('sessions', defaultValue: []) as List;
    if (sessions.isEmpty) return 0;

    final dates = sessions
        .map((s) => DateTime.parse((s as Map)['completed_at'] as String))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int streak = 0;
    DateTime current = today;

    for (final date in dates) {
      if (date == current ||
          date == current.subtract(const Duration(days: 1))) {
        streak++;
        current = date;
      } else {
        break;
      }
    }
    return streak;
  } catch (_) {
    return 0;
  }
}

// ── HomeHeader ────────────────────────────────────────────────────────────────

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final streakCount = _getStreakCount();
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: greeting + date ─────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting + name + wave
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${_getGreeting()}, ',
                        style: tt.titleLarge?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: '$userName ',
                        style: tt.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const WidgetSpan(
                        child: Text('👋', style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideX(
                      begin: -0.05,
                      end: 0.0,
                      duration: 350.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: AppSpacing.xs),

                // Date + streak badge
                Row(
                  children: [
                    Text(
                      _formattedDate(),
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (streakCount > 0) ...[
                      const SizedBox(width: AppSpacing.sm),
                      StreakBadge(
                        streakCount: streakCount,
                        compact: true,
                      ),
                    ],
                  ],
                )
                    .animate(delay: 80.ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(
                      begin: -0.04,
                      end: 0.0,
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // ── Right: avatar ─────────────────────────────────
          _AvatarWidget(onTap: () => context.go(RouteNames.profile))
              .animate(delay: 120.ms)
              .fadeIn(duration: 300.ms)
              .scale(
                begin: const Offset(0.85, 0.85),
                duration: 300.ms,
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }
}

// ── _AvatarWidget ─────────────────────────────────────────────────────────────

class _AvatarWidget extends StatefulWidget {
  final VoidCallback onTap;

  const _AvatarWidget({required this.onTap});

  @override
  State<_AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<_AvatarWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Layer 1: gradient circle with initial letter
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.8),
                    AppColors.accentBlue.withValues(alpha: 0.8),
                  ],
                ),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Consumer(
                  builder: (ctx, ref, child) {
                    final name = ref.watch(userNameProvider);
                    return Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'A',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.background,
                            fontWeight: FontWeight.w700,
                          ),
                    );
                  },
                ),
              ),
            ),

            // Layer 2: active status dot
            Positioned(
              bottom: 1,
              right: 1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                  border: Border.all(
                    color: AppColors.background,
                    width: 1.5,
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
