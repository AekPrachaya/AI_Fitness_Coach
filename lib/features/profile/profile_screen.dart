import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/session_history_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/user_profile.dart';
import '../auth/auth_notifier.dart';
import '../workout/data/workout_repository.dart';
import 'data/profile_repository.dart';
import 'profile_logic.dart';
import 'profile_options.dart';
import 'widgets/profile_editors.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_rows.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Profile tab: identity, lifetime stats, the demo-data switch, editable
// personal / training data and log out.
//
// Stats come from `sessionHistoryProvider`, the same source as Home and
// Progress, so the three screens always agree. Edits go to the user_profile
// box via ProfileRepository, then `userProfileProvider` is invalidated —
// the session screen reads weight from it for calories.
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final profile = ref.watch(userProfileProvider);
    final stats = profileStats(ref.watch(sessionHistoryProvider));
    final demoOn = ref.watch(showDemoHistoryProvider);
    final calm = MediaQuery.disableAnimationsOf(context);

    Widget enter(Widget child, int delayMs) => calm
        ? child
        : child
              .animate(delay: delayMs.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05, curve: Curves.easeOut);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            enter(Text('Profile', style: tt.headlineMedium), 0),
            const SizedBox(height: AppSpacing.lg),
            enter(ProfileHeader(profile: profile), 60),
            const SizedBox(height: AppSpacing.lg),
            enter(ProfileStatsRow(stats: stats), 120),
            const SizedBox(height: AppSpacing.lg),
            enter(_DataSection(demoOn: demoOn), 180),
            const SizedBox(height: AppSpacing.lg),
            enter(_PersonalSection(profile: profile), 240),
            const SizedBox(height: AppSpacing.lg),
            enter(_TrainingSection(profile: profile), 300),
            const SizedBox(height: AppSpacing.lg),
            enter(const _AccountSection(), 360),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

/// Runs [write] against the profile box, then refreshes every reader.
Future<void> _saveProfile(
  WidgetRef ref,
  Future<void> Function(ProfileRepository repo) write,
) async {
  await write(ref.read(profileRepositoryProvider));
  ref.invalidate(userProfileProvider);
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Color confirmColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final tt = Theme.of(dialogContext).textTheme;
      return AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: Text(title, style: tt.titleLarge),
        content: Text(
          message,
          style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: tt.labelLarge?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              confirmLabel,
              style: tt.labelLarge?.copyWith(color: confirmColor),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
      ),
      backgroundColor: AppColors.surfaceElevated,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
    ),
  );
}

// ── DATA ─────────────────────────────────────────────────────────────────────

class _DataSection extends ConsumerWidget {
  const _DataSection({required this.demoOn});
  final bool demoOn;

  Future<void> _setDemo(WidgetRef ref, bool value) async {
    await ref.read(workoutRepositoryProvider).setShowDemoHistory(value);
    ref.invalidate(showDemoHistoryProvider);
    ref.invalidate(sessionHistoryProvider);
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      title: 'Clear workout history?',
      message:
          'Every workout you have recorded will be deleted. '
          'This cannot be undone. Sample data is not affected.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.error,
    );
    if (!ok) return;
    final n = await ref.read(workoutRepositoryProvider).clearRecordedSessions();
    ref.invalidate(sessionHistoryProvider);
    if (!context.mounted) return;
    _showSnack(context, 'Deleted $n ${n == 1 ? 'workout' : 'workouts'}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionHeader('DATA'),
        ProfileListCard(
          children: [
            ProfileToggleRow(
              title: 'Demo mode',
              subtitle: 'Show a year of sample workouts',
              value: demoOn,
              onChanged: (v) => _setDemo(ref, v),
            ),
            const ProfileRowDivider(),
            ProfileActionRow(
              icon: Icons.delete_outline_rounded,
              title: 'Clear workout history',
              color: AppColors.error,
              onTap: () => _clearHistory(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

// ── PERSONAL ─────────────────────────────────────────────────────────────────

class _PersonalSection extends ConsumerWidget {
  const _PersonalSection({required this.profile});
  final UserProfile profile;

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final name = await showNameEditor(context, profile.name);
    if (name == null) return;
    await _saveProfile(ref, (r) => r.setName(name));
  }

  Future<void> _editNumber(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required NumberRule rule,
    required double current,
    required Future<void> Function(ProfileRepository r, double v) write,
  }) async {
    final value = await showNumberEditor(
      context,
      title: title,
      rule: rule,
      current: current,
    );
    if (value == null) return;
    await _saveProfile(ref, (r) => write(r, value));
  }

  Future<void> _editGender(BuildContext context, WidgetRef ref) async {
    final id = await showChoiceEditor(
      context,
      title: 'Gender',
      options: genderOptions,
      current: profile.gender,
    );
    if (id == null) return;
    await _saveProfile(ref, (r) => r.setGender(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final bmi = profile.bmi;
    final category = bmiCategory(bmi);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionHeader('PERSONAL'),
        ProfileListCard(
          children: [
            ProfileValueRow(
              label: 'Name',
              value: profile.name,
              onTap: () => _editName(context, ref),
            ),
            const ProfileRowDivider(),
            ProfileValueRow(
              label: 'Age',
              value: '${profile.age}',
              onTap: () => _editNumber(
                context,
                ref,
                title: 'Age',
                rule: NumberRule.age,
                current: profile.age.toDouble(),
                write: (r, v) => r.setAge(v.round()),
              ),
            ),
            const ProfileRowDivider(),
            ProfileValueRow(
              label: 'Gender',
              value: optionLabel(genderOptions, profile.gender),
              onTap: () => _editGender(context, ref),
            ),
            const ProfileRowDivider(),
            ProfileValueRow(
              label: 'Height',
              value: '${profile.heightCm.round()} cm',
              onTap: () => _editNumber(
                context,
                ref,
                title: 'Height',
                rule: NumberRule.heightCm,
                current: profile.heightCm.roundToDouble(),
                write: (r, v) => r.setHeightCm(v),
              ),
            ),
            const ProfileRowDivider(),
            ProfileValueRow(
              label: 'Weight',
              value: '${profile.weightKg.toStringAsFixed(1)} kg',
              onTap: () => _editNumber(
                context,
                ref,
                title: 'Weight',
                rule: NumberRule.weightKg,
                current: profile.weightKg,
                write: (r, v) => r.setWeightKg(v),
              ),
            ),
            const ProfileRowDivider(),
            // Read-only: derived from height and weight.
            MergeSemantics(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(child: Text('BMI', style: tt.titleMedium)),
                    Text(
                      bmi.toStringAsFixed(1),
                      style: tt.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ProfilePill(text: category.label, color: category.color),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── TRAINING ─────────────────────────────────────────────────────────────────

class _TrainingSection extends ConsumerWidget {
  const _TrainingSection({required this.profile});
  final UserProfile profile;

  Future<void> _editChoice(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<ProfileOption> options,
    required String current,
    required Future<void> Function(ProfileRepository r, String id) write,
  }) async {
    final id = await showChoiceEditor(
      context,
      title: title,
      options: options,
      current: current,
    );
    if (id == null) return;
    await _saveProfile(ref, (r) => write(r, id));
  }

  Future<void> _editEquipment(BuildContext context, WidgetRef ref) async {
    final ids = await showEquipmentEditor(context, profile.equipment);
    if (ids == null) return;
    await _saveProfile(ref, (r) => r.setEquipment(ids));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionHeader('TRAINING'),
        ProfileListCard(
          children: [
            ProfileValueRow(
              label: 'Goal',
              value: optionLabel(goalOptions, profile.fitnessGoal),
              onTap: () => _editChoice(
                context,
                ref,
                title: 'Goal',
                options: goalOptions,
                current: profile.fitnessGoal,
                write: (r, id) => r.setFitnessGoal(id),
              ),
            ),
            const ProfileRowDivider(),
            ProfileValueRow(
              label: 'Level',
              value: optionLabel(levelOptions, profile.fitnessLevel),
              onTap: () => _editChoice(
                context,
                ref,
                title: 'Level',
                options: levelOptions,
                current: profile.fitnessLevel,
                write: (r, id) => r.setFitnessLevel(id),
              ),
            ),
            const ProfileRowDivider(),
            ProfileValueRow(
              label: 'Equipment',
              value: equipmentSummary(profile.equipment),
              onTap: () => _editEquipment(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

// ── ACCOUNT ──────────────────────────────────────────────────────────────────

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      title: 'Log out?',
      message: 'Your profile and workout history stay on this device.',
      confirmLabel: 'Log out',
      confirmColor: AppColors.error,
    );
    if (!ok) return;
    await ref.read(authNotifierProvider.notifier).logout();
    if (!context.mounted) return;
    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionHeader('ACCOUNT'),
        ProfileListCard(
          children: [
            ProfileActionRow(
              icon: Icons.logout_rounded,
              title: 'Log out',
              color: AppColors.textPrimary,
              onTap: () => _logout(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}
