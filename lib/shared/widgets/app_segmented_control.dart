import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppSegmentedControl
// Spec: Pill-shaped, surface bg, accent fill for selected segment.
// Segments share equal width via Expanded inside a Row.
// ─────────────────────────────────────────────────────────────────────────────

class AppSegmentedControl extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.enabled = true,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    Widget control = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.circleAll,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: enabled ? () => onChanged(index) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.transparent,
                  borderRadius: AppRadius.circleAll,
                ),
                child: Center(
                  child: Text(
                    options[index],
                    style: tt.titleSmall?.copyWith(
                      color: isSelected
                          ? AppColors.background
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );

    if (!enabled) {
      return IgnorePointer(
        child: Opacity(opacity: 0.4, child: control),
      );
    }

    return control;
  }
}
