import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';
import 'onboarding_notifier.dart';
import 'widgets/onboarding_step_dots.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Equipment data model
// ─────────────────────────────────────────────────────────────────────────────

class _EquipmentData {
  const _EquipmentData({
    required this.id,
    required this.emoji,
    required this.label,
    this.sublabel = '',
  });

  final String id;
  final String emoji;
  final String label;
  final String sublabel;
}

const _equipmentOptions = [
  _EquipmentData(
    id: 'no_equipment',
    emoji: '🤸',
    label: 'No Equipment',
    sublabel: 'Bodyweight only',
  ),
  _EquipmentData(id: 'dumbbells', emoji: '🏋️', label: 'Dumbbells'),
  _EquipmentData(id: 'barbell', emoji: '🔩', label: 'Barbell & Plates'),
  _EquipmentData(id: 'resistance_bands', emoji: '🪢', label: 'Resistance Bands'),
  _EquipmentData(id: 'pull_up_bar', emoji: '🏗️', label: 'Pull-up Bar'),
  _EquipmentData(id: 'bench', emoji: '🪑', label: 'Bench'),
  _EquipmentData(id: 'kettlebell', emoji: '⚫', label: 'Kettlebell'),
];

// ─────────────────────────────────────────────────────────────────────────────
// EquipmentScreen
// ─────────────────────────────────────────────────────────────────────────────

class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Back button ───────────────────────────────────────────
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => context.go(RouteNames.fitnessLevel),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),

                  // ── Step dots ─────────────────────────────────────────────
                  const SizedBox(height: AppSpacing.sm),
                  const Center(
                    child: OnboardingStepDots(currentStep: 4, totalSteps: 5),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Title ─────────────────────────────────────────────────
                  Text(
                    "What equipment\ndo you have?",
                    style: tt.headlineLarge?.copyWith(height: 1.15),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(
                        begin: 0.12,
                        end: 0.0,
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Subtitle ──────────────────────────────────────────────
                  Text(
                    "Select all that apply. We'll tailor exercises accordingly.",
                    style:
                        tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  )
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 300.ms),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),

            // ── Chip grid ───────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        ..._equipmentOptions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final opt = entry.value;
                          return _EquipmentChip(
                            data: opt,
                            isSelected: state.equipment.contains(opt.id),
                            onTap: () => notifier.toggleEquipment(opt.id),
                          )
                              .animate(
                                key: ValueKey('equip_anim_${opt.id}'),
                                delay: (index * 40).ms,
                              )
                              .fadeIn(duration: 250.ms)
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1.0, 1.0),
                                duration: 250.ms,
                                curve: Curves.easeOut,
                              );
                        }),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // ── Bottom section ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  // ── Empty-state note ──────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: state.equipment.isEmpty
                        ? Padding(
                            key: const ValueKey(true),
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.md),
                            child: Text(
                              'No equipment selected — workouts will use bodyweight exercises.',
                              style: tt.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey(false)),
                  ),

                  // ── Next button ───────────────────────────────────────────
                  AppPrimaryButton(
                    label: 'Next',
                    onTap: () => context.go(RouteNames.cameraPermission),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EquipmentChip
// ─────────────────────────────────────────────────────────────────────────────

class _EquipmentChip extends StatelessWidget {
  const _EquipmentChip({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _EquipmentData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: AppRadius.circleAll,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              data.label,
              style: tt.titleSmall?.copyWith(
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.check,
                size: 14,
                color: AppColors.accent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
