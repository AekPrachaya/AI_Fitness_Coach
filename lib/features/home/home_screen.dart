import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/achievements_section.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_stats_row.dart';
import 'widgets/recommended_section.dart';
import 'widgets/today_plan_card.dart';
import 'widgets/weekly_activity_chart.dart';

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

            // ── Section 3: Weekly Activity Chart ─────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: WeeklyActivityChart(),
              ),
            ),

            // ── Section 4: Quick Stats Row ────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: QuickStatsRow(),
              ),
            ),

            // ── Section 5: Recommended for You ───────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.lg),
                child: RecommendedSection(),
              ),
            ),

            // ── Section 6: Achievements ───────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                    top: AppSpacing.lg, bottom: AppSpacing.xxl),
                child: AchievementsSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
