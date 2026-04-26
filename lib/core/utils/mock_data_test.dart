import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'mock_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MockDataDebugScreen
// Development-only screen to verify the mock data layer loads correctly.
// Route: /mock-data-debug
// REMOVE before Phase 2 feature screens are built.
// ─────────────────────────────────────────────────────────────────────────────

class MockDataDebugScreen extends StatelessWidget {
  const MockDataDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Mock Data Debug',
          style: tt.titleLarge?.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Workouts ─────────────────────────────────────────────────────
            _SectionHeader('Workouts (from workouts.json)'),
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<Workout>>(
              future: MockData.loadWorkouts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text(
                    'Loading...',
                    style: tt.bodyMedium?.copyWith(
                        color: AppColors.textSecondary),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: tt.bodyMedium?.copyWith(color: AppColors.error),
                  );
                }
                final workouts = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusRow(
                      label: 'Total workouts',
                      value: '${workouts.length}',
                      ok: workouts.length == 4,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ...workouts.map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          '• ${w.name} — ${w.instructions.length} steps, '
                          '${w.commonMistakes.length} mistakes',
                          style: tt.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Session history ───────────────────────────────────────────────
            _SectionHeader('Session History (Hive)'),
            const SizedBox(height: AppSpacing.sm),
            Builder(builder: (context) {
              final box = Hive.box(MockData.boxSessionHistory);
              final sessions =
                  box.get('sessions') as List? ?? [];
              final seeded = box.get('seeded') as bool? ?? false;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusRow(
                      label: 'Seeded',
                      value: seeded.toString(),
                      ok: seeded),
                  _StatusRow(
                    label: 'Session count',
                    value: '${sessions.length}',
                    ok: sessions.length >= 18,
                  ),
                ],
              );
            }),

            const SizedBox(height: AppSpacing.xl),

            // ── Body metrics ──────────────────────────────────────────────────
            _SectionHeader('Body Metrics (Hive)'),
            const SizedBox(height: AppSpacing.sm),
            Builder(builder: (context) {
              final box = Hive.box(MockData.boxProgressData);
              final metrics =
                  box.get('body_metrics') as List? ?? [];
              final seeded = box.get('metrics_seeded') as bool? ?? false;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusRow(
                      label: 'Seeded',
                      value: seeded.toString(),
                      ok: seeded),
                  _StatusRow(
                    label: 'Metrics count',
                    value: '${metrics.length}',
                    ok: metrics.length == 8,
                  ),
                ],
              );
            }),

            const SizedBox(height: AppSpacing.xl),

            // ── SharedPreferences keys ────────────────────────────────────────
            _SectionHeader('SharedPreferences Keys'),
            const SizedBox(height: AppSpacing.sm),
            ...[
              MockData.prefOnboardingComplete,
              MockData.prefUnits,
              MockData.prefThemeMode,
              MockData.prefDefaultDifficulty,
              MockData.prefRestDuration,
              MockData.prefAutoAdvance,
              MockData.prefShowSkeleton,
              MockData.prefShowAngles,
              MockData.prefMirrorCamera,
              MockData.prefRepSound,
              MockData.prefFormHaptic,
              MockData.prefWorkoutReminder,
              MockData.prefReminderTime,
            ].map(
              (key) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  '• $key',
                  style: tt.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

// ── Internal helpers ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(color: AppColors.accent),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.ok,
  });

  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            ok ? '✅' : '❌',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
