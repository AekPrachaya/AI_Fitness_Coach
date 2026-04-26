import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_shadows.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppPrimaryButton
// Spec: Filled, accent bg, dark text, full width, 56px height, 12px radius
// ─────────────────────────────────────────────────────────────────────────────

class AppPrimaryButton extends StatefulWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.fullWidth = true,
    this.leadingIcon,
    this.height = 56.0,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool fullWidth;
  final IconData? leadingIcon;
  final double height;

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onTap != null && !widget.isLoading;
    final bgColor = isEnabled
        ? AppColors.accent
        : AppColors.accent.withValues(alpha: 0.4);

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel:
          isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: (_isPressed && isEnabled) ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.mdAll,
            boxShadow: isEnabled ? AppShadows.glow : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.background,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        Icon(
                          widget.leadingIcon,
                          size: 18,
                          color: AppColors.background,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        widget.label,
                        style: context.textTheme.titleLarge?.copyWith(
                          color: AppColors.background,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSecondaryButton
// Spec: Outline, accent border, accent text, full width
// ─────────────────────────────────────────────────────────────────────────────

class AppSecondaryButton extends StatefulWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.fullWidth = true,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool fullWidth;
  final IconData? leadingIcon;

  @override
  State<AppSecondaryButton> createState() => _AppSecondaryButtonState();
}

class _AppSecondaryButtonState extends State<AppSecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onTap != null && !widget.isLoading;
    final accentColor = isEnabled
        ? AppColors.accent
        : AppColors.accent.withValues(alpha: 0.4);

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel:
          isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: (_isPressed && isEnabled) ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.transparent,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: accentColor, width: 1.5),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        Icon(widget.leadingIcon, size: 18, color: accentColor),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        widget.label,
                        style: context.textTheme.titleLarge
                            ?.copyWith(color: accentColor),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppGhostButton
// Spec: No border, accent text
// ─────────────────────────────────────────────────────────────────────────────

class AppGhostButton extends StatefulWidget {
  const AppGhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? leadingIcon;

  @override
  State<AppGhostButton> createState() => _AppGhostButtonState();
}

class _AppGhostButtonState extends State<AppGhostButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onTap != null && !widget.isLoading;
    final textColor =
        isEnabled ? AppColors.accent : AppColors.textDisabled;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel:
          isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: (_isPressed && isEnabled) ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          height: 44,
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          color: AppColors.transparent,
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        Icon(widget.leadingIcon, size: 16, color: textColor),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        widget.label,
                        style: context.textTheme.titleMedium
                            ?.copyWith(color: textColor),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppIconButton
// Spec: Circular, 48px, surface elevated bg
// ─────────────────────────────────────────────────────────────────────────────

class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 48.0,
    this.iconColor,
    this.backgroundColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? tooltip;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onTap != null;

    Widget button = GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel:
          isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: (_isPressed && isEnabled) ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderSubtle, width: 1),
          ),
          child: Icon(
            widget.icon,
            size: 22,
            color: widget.iconColor ?? AppColors.textPrimary,
          ),
        ),
      ),
    );

    if (!isEnabled) {
      button = Opacity(opacity: 0.4, child: button);
    }

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppFAB
// Spec: Circular 56px, accent bg, shadow + glow
// ─────────────────────────────────────────────────────────────────────────────

class AppFAB extends StatefulWidget {
  const AppFAB({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.size = 56.0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final double size;

  @override
  State<AppFAB> createState() => _AppFABState();
}

class _AppFABState extends State<AppFAB> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasLabel = widget.label != null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          height: widget.size,
          width: hasLabel ? null : widget.size,
          padding: hasLabel
              ? const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                )
              : null,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: AppRadius.circleAll,
            boxShadow: [
              ...AppShadows.glow,
              ...AppShadows.medium,
            ],
          ),
          child: Center(
            child: hasLabel
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        size: 24,
                        color: AppColors.background,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        widget.label!,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: AppColors.background,
                        ),
                      ),
                    ],
                  )
                : Icon(
                    widget.icon,
                    size: 24,
                    color: AppColors.background,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extension for convenient textTheme access
// ─────────────────────────────────────────────────────────────────────────────

extension _TextThemeX on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
}
