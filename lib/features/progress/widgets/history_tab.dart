import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/session_history_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_format.dart';
import '../../../shared/models/session_data.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../history_grouping.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HistoryTab — every session, newest first, under a header per local day.
// The demo year alone is hundreds of rows, so the list is built lazily from
// the flat header/session list that [buildHistoryItems] produces.
// ─────────────────────────────────────────────────────────────────────────────

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  /// Only the first screenful animates in, and only right after the tab opens:
  /// a lazy list rebuilds rows as they scroll back into view, and replaying the
  /// entry animation then would read as flicker.
  static const int _animatedItems = 8;
  static const Duration _entryWindow = Duration(milliseconds: 800);

  final DateTime _openedAt = DateTime.now();

  bool get _withinEntryWindow =>
      DateTime.now().difference(_openedAt) < _entryWindow;

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionHistoryProvider);
    final isDemo = ref.watch(showDemoHistoryProvider);

    if (sessions.isEmpty) return const _EmptyHistory();

    final items = buildHistoryItems(sessions, now: DateTime.now());
    final animate = !MediaQuery.disableAnimationsOf(context);
    // The sample-data note, when shown, sits above the first day header.
    final offset = isDemo ? 1 : 0;

    return ListView.builder(
      // Bottom padding clears the shell's nav bar.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: items.length + offset,
      itemBuilder: (context, index) {
        final Widget child;
        if (index < offset) {
          child = const _SampleDataNote();
        } else {
          final item = items[index - offset];
          child = switch (item) {
            HistoryDayHeader() => _DayHeader(
              label: item.label,
              isFirst: index == offset,
            ),
            HistorySessionItem() => _SessionRow(session: item.session),
          };
        }

        if (!animate || index >= _animatedItems || !_withinEntryWindow) {
          return child;
        }
        return child
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.05, curve: Curves.easeOut);
      },
    );
  }
}

// ── Day header ───────────────────────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.isFirst});

  final String label;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 0 : AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Text(label, style: tt.labelLarge),
    );
  }
}

// ── Session row ──────────────────────────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final SessionData session;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(session.completedAt.toLocal()),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final name = session.workoutName.isNotEmpty
        ? session.workoutName
        : 'Workout';
    final reps =
        '${session.totalReps} '
        '${session.totalReps == 1 ? 'rep' : 'reps'}';
    final stats =
        '$reps · ${formatClock(session.durationSeconds)} · '
        '${session.estimatedCalories} kcal';

    final score = session.avgFormScore;
    final hasScore = score > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => context.push(
          RouteNames.workoutSummaryPath(
            session.workoutId,
            sessionId: session.id,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: tt.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(time, style: tt.labelMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    stats,
                    style: tt.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasScore ? '${score.round()}%' : '--',
                  style: tt.displaySmall?.copyWith(
                    color: hasScore
                        ? AppColors.formScoreColor(score)
                        : AppColors.textDisabled,
                  ),
                ),
                Text('FORM', style: tt.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sample-data note ─────────────────────────────────────────────────────────

class _SampleDataNote extends StatelessWidget {
  const _SampleDataNote();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Includes sample data from Demo mode.',
              style: tt.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final content = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 48,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No workouts yet',
              style: tt.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Finish a workout and it will show up here. Turn on Demo mode '
              'in Profile to explore sample data.',
              style: tt.bodySmall?.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSecondaryButton(
              label: 'Open Profile',
              fullWidth: false,
              onTap: () => context.go(RouteNames.profile),
            ),
          ],
        ),
      ),
    );

    if (MediaQuery.disableAnimationsOf(context)) return content;
    return content
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, curve: Curves.easeOut);
  }
}
