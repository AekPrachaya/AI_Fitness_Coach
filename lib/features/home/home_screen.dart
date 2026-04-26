import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/home_header.dart';
import 'widgets/today_plan_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Section 1: Header ────────────────────────────
            const SliverToBoxAdapter(
              child: HomeHeader(),
            ),

            // ── Section 2: Today's Plan Card ──────────────────
            const SliverToBoxAdapter(
              child: TodayPlanCard(),
            ),

            // ── Sections 3–6: Placeholders ───────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.lg),
                  _PlaceholderSection('Weekly Activity Chart — Task 3.4'),
                  const SizedBox(height: AppSpacing.lg),
                  _PlaceholderSection('Quick Stats — Task 3.5'),
                  const SizedBox(height: AppSpacing.lg),
                  _PlaceholderSection('Recommended — Task 3.5'),
                  const SizedBox(height: AppSpacing.xxxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _PlaceholderSection ───────────────────────────────────────────────────────

class _PlaceholderSection extends StatelessWidget {
  final String label;

  const _PlaceholderSection(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 0.5,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textDisabled,
              ),
        ),
      ),
    );
  }
}
