import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppTextField
// Spec: Dark fill (#1C1C27), accent border on focus, 8px radius
// Uses TextFormField for Form/validation compatibility.
// AppTextField is stateless — show/hide state for passwords lives in the caller.
// ─────────────────────────────────────────────────────────────────────────────

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.controller,
    this.focusNode,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onTap,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
  });

  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;

  static const EdgeInsetsGeometry _contentPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: 14,
  );

  OutlineInputBorder _border(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: AppRadius.smAll,
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return TextFormField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onTap: onTap,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      enabled: enabled,
      style: tt.bodyMedium?.copyWith(color: AppColors.textPrimary),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        helperText: helperText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        // Fill
        filled: true,
        fillColor: AppColors.surfaceElevated,
        // Content padding
        contentPadding: _contentPadding,
        // Borders
        enabledBorder: _border(AppColors.borderSubtle, 1),
        focusedBorder: _border(AppColors.accent, 2),
        errorBorder: _border(AppColors.error, 1.5),
        focusedErrorBorder: _border(AppColors.error, 1.5),
        disabledBorder: _border(
          AppColors.borderSubtle.withValues(alpha: 0.4),
          1,
        ),
        // Label
        labelStyle: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle:
            tt.bodySmall?.copyWith(color: AppColors.textSecondary),
        // Hint
        hintStyle: tt.bodyMedium?.copyWith(color: AppColors.textDisabled),
        // Error
        errorStyle: tt.bodySmall?.copyWith(color: AppColors.error),
        // Helper
        helperStyle: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
        // Counter (when maxLength set)
        counterStyle: tt.bodySmall?.copyWith(color: AppColors.textDisabled),
      ),
    );
  }
}
