import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppToggle
// Spec: Custom toggle — accent green when on, grey when off.
// Built with GestureDetector + AnimatedContainer to match exact visual spec
// on all platforms (Flutter's Switch diverges on iOS thumb/track colors).
// ─────────────────────────────────────────────────────────────────────────────

class AppToggle extends StatefulWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final bool enabled;

  // Track dimensions
  static const double _trackWidth = 44;
  static const double _trackHeight = 24;
  // Thumb
  static const double _thumbSize = 18;
  static const double _thumbPadding = 3;

  @override
  State<AppToggle> createState() => _AppToggleState();
}

class _AppToggleState extends State<AppToggle> {
  // Thumb left offset: 3px when OFF, (44 - 18 - 3) = 23px when ON
  double get _thumbOffset => widget.value
      ? AppToggle._trackWidth - AppToggle._thumbSize - AppToggle._thumbPadding
      : AppToggle._thumbPadding;

  @override
  Widget build(BuildContext context) {
    final toggle = GestureDetector(
      onTap: widget.enabled ? () => widget.onChanged(!widget.value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: AppToggle._trackWidth,
        height: AppToggle._trackHeight,
        decoration: BoxDecoration(
          color: widget.value ? AppColors.accent : AppColors.surfaceElevated,
          borderRadius: AppRadius.circleAll,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: _thumbOffset,
              top: AppToggle._thumbPadding,
              child: Container(
                width: AppToggle._thumbSize,
                height: AppToggle._thumbSize,
                decoration: BoxDecoration(
                  color: widget.value
                      ? AppColors.background
                      : AppColors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final content = widget.label != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              toggle,
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: widget.enabled
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                    ),
              ),
            ],
          )
        : toggle;

    if (!widget.enabled) {
      return Opacity(opacity: 0.4, child: content);
    }

    return content;
  }
}
