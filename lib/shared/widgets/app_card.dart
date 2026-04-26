import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_shadows.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppCard
// Spec: Surface color bg, 12px radius, padding 16px, subtle border
// ─────────────────────────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.child,
    this.padding,
    this.onTap,
    this.isLoading = false,
    this.height,
    this.width,
    this.backgroundColor,
    this.elevated = false,
    this.border,
  });

  /// Convenience constructor for shimmer loading placeholders.
  const AppCard.skeleton({
    super.key,
    this.height = 120,
    this.width,
  })  : child = null,
        padding = null,
        onTap = null,
        isLoading = true,
        backgroundColor = null,
        elevated = false,
        border = null;

  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final bool elevated;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: AppColors.surface,
        highlightColor: AppColors.surfaceElevated,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
          ),
        ),
      );
    }

    final resolvedBg = backgroundColor ??
        (elevated ? AppColors.surfaceElevated : AppColors.surface);
    final resolvedBorder =
        border ?? Border.all(color: AppColors.borderSubtle, width: 1);
    final resolvedPadding =
        padding ?? const EdgeInsets.all(AppSpacing.md);
    final resolvedShadow =
        onTap != null ? AppShadows.medium : AppShadows.low;

    if (onTap != null) {
      return ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: Material(
          color: resolvedBg,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.accent.withValues(alpha: 0.08),
            highlightColor: AppColors.accent.withValues(alpha: 0.04),
            child: Container(
              height: height,
              width: width,
              decoration: BoxDecoration(
                borderRadius: AppRadius.mdAll,
                border: resolvedBorder,
                boxShadow: resolvedShadow,
              ),
              padding: resolvedPadding,
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: AppRadius.mdAll,
        border: resolvedBorder,
        boxShadow: resolvedShadow,
      ),
      padding: resolvedPadding,
      child: child,
    );
  }
}
