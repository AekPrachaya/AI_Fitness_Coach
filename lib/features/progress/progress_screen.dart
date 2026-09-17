import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/activity_heatmap.dart';
import 'widgets/coming_soon_tab.dart';
import 'widgets/exercise_stats_section.dart';
import 'widgets/form_progress_chart.dart';
import 'widgets/streak_card.dart';
import 'widgets/this_week_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProgressScreen — Overview | History | Body Metrics.
// Only Overview is built (Tasks 5.1/5.2); the other two arrive in 5.3/5.4.
// ─────────────────────────────────────────────────────────────────────────────

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.lg,
        title: Text('Progress', style: tt.headlineMedium),
        bottom: _ProgressTabBar(controller: _tabController),
      ),
      // A TabBarView rather than the detail screen's AnimatedSwitcher: these are
      // top-level tabs, so each keeps its own scroll position and swipes.
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OverviewTab(),
          ComingSoonTab(
            icon: Icons.history_rounded,
            title: 'Workout History',
            message: 'Your session-by-session log will live here.',
          ),
          ComingSoonTab(
            icon: Icons.monitor_weight_outlined,
            title: 'Body Metrics',
            message: 'Weight and BMI tracking will live here.',
          ),
        ],
      ),
    );
  }
}

// ── Tab bar ──────────────────────────────────────────────────────────────────

class _ProgressTabBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProgressTabBar({required this.controller});

  final TabController controller;

  static const double _height = 48.0;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      color: AppColors.background,
      child: TabBar(
        controller: controller,
        indicatorColor: AppColors.accent,
        indicatorWeight: 2,
        dividerHeight: 0,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: tt.titleSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: tt.titleSmall,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'History'),
          Tab(text: 'Body Metrics'),
        ],
      ),
    );
  }
}

// ── Overview ─────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    const cards = [
      ActivityHeatmap(),
      ThisWeekCard(),
      StreakCard(),
      FormProgressChart(),
      ExerciseStatsSection(),
    ];

    return SingleChildScrollView(
      // Bottom padding clears the shell's nav bar.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            cards[i]
                .animate(delay: (i * 80).ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.05, end: 0.0, curve: Curves.easeOut),
          ],
        ],
      ),
    );
  }
}
