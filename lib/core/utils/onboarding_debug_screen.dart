import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../features/auth/auth_notifier.dart';
import '../../features/onboarding/onboarding_notifier.dart';

/// Development-only screen that displays the full state of all onboarding,
/// auth, and user-profile providers for integration verification.
class OnboardingDebugScreen extends ConsumerWidget {
  const OnboardingDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final ob = ref.watch(onboardingNotifierProvider);
    final auth = ref.watch(authNotifierProvider);
    final profile = ref.watch(userProfileProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Onboarding Debug', style: textTheme.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accent),
            tooltip: 'Reload from Hive',
            onPressed: () {
              ref
                  .read(onboardingNotifierProvider.notifier)
                  .loadFromHive();
              ref.invalidate(userProfileProvider);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Section 1: Onboarding State ──────────────────────────────
          _SectionHeader(title: 'Onboarding State', textTheme: textTheme),
          _StatusRow(label: 'age', value: '${ob.age}'),
          _StatusRow(label: 'gender', value: '${ob.gender}'),
          _StatusRow(label: 'heightCm', value: '${ob.heightCm}'),
          _StatusRow(label: 'weightKg', value: '${ob.weightKg}'),
          _StatusRow(label: 'heightInFeet', value: '${ob.heightInFeet}'),
          _StatusRow(label: 'weightInLbs', value: '${ob.weightInLbs}'),
          _StatusRow(label: 'fitnessGoal', value: '${ob.fitnessGoal}'),
          _StatusRow(label: 'fitnessLevel', value: '${ob.fitnessLevel}'),
          _StatusRow(
            label: 'equipment',
            value: ob.equipment.isEmpty ? '[]' : ob.equipment.join(', '),
          ),
          _StatusRow(
            label: 'cameraGranted',
            value: '${ob.cameraGranted}',
          ),
          const Divider(color: AppColors.divider),
          _StatusRow(
            label: 'BMI',
            value: ob.bmi?.toStringAsFixed(1) ?? 'N/A',
          ),
          _StatusRow(
            label: 'BMI Category',
            value: ob.bmiCategory ?? 'N/A',
          ),
          _StatusRow(
            label: 'step1Complete',
            value: '${ob.step1Complete}',
            isPass: ob.step1Complete,
          ),
          _StatusRow(
            label: 'step2Complete',
            value: '${ob.step2Complete}',
            isPass: ob.step2Complete,
          ),
          _StatusRow(
            label: 'step3Complete',
            value: '${ob.step3Complete}',
            isPass: ob.step3Complete,
          ),
          _StatusRow(
            label: 'step4Complete',
            value: '${ob.step4Complete}',
            isPass: ob.step4Complete,
          ),
          _StatusRow(
            label: 'step5Complete',
            value: '${ob.step5Complete}',
            isPass: ob.step5Complete,
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Section 2: Auth State ────────────────────────────────────
          _SectionHeader(title: 'Auth State', textTheme: textTheme),
          _StatusRow(
            label: 'isLoggedIn',
            value: '${auth.isLoggedIn}',
            isPass: auth.isLoggedIn,
          ),
          _StatusRow(
            label: 'isGuest',
            value: '${authNotifier.isGuest}',
          ),
          _StatusRow(
            label: 'userName',
            value: auth.userName ?? 'null',
          ),
          _StatusRow(
            label: 'userEmail',
            value: auth.userEmail ?? 'null',
          ),
          _StatusRow(label: 'isLoading', value: '${auth.isLoading}'),
          _StatusRow(
            label: 'errorMessage',
            value: auth.errorMessage ?? 'null',
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Section 3: UserProfile Provider ──────────────────────────
          _SectionHeader(
            title: 'UserProfile Provider',
            textTheme: textTheme,
          ),
          _StatusRow(label: 'name', value: profile.name),
          _StatusRow(label: 'email', value: profile.email),
          _StatusRow(label: 'age', value: '${profile.age}'),
          _StatusRow(label: 'gender', value: profile.gender),
          _StatusRow(
            label: 'heightCm',
            value: profile.heightCm.toStringAsFixed(1),
          ),
          _StatusRow(
            label: 'weightKg',
            value: profile.weightKg.toStringAsFixed(1),
          ),
          _StatusRow(label: 'fitnessGoal', value: profile.fitnessGoal),
          _StatusRow(label: 'fitnessLevel', value: profile.fitnessLevel),
          _StatusRow(
            label: 'equipment',
            value: profile.equipment.isEmpty
                ? '[]'
                : profile.equipment.join(', '),
          ),
          _StatusRow(
            label: 'joinedAt',
            value: profile.joinedAt.toIso8601String(),
          ),
          _StatusRow(
            label: 'BMI',
            value: profile.bmi.toStringAsFixed(1),
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.textTheme});

  final String title;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(color: AppColors.accent),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    this.isPass,
  });

  final String label;
  final String value;
  final bool? isPass;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Color valueColor = AppColors.textPrimary;
    if (isPass != null) {
      valueColor = isPass! ? AppColors.accent : AppColors.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: textTheme.bodySmall?.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
