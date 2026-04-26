import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTypography {
  static TextTheme get textTheme => TextTheme(
        // ── Bebas Neue — large display, rep counters, hero numbers ─────────
        displayLarge: GoogleFonts.bebasNeue(
          fontSize: 80,
          letterSpacing: 2.0,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.bebasNeue(
          fontSize: 48,
          letterSpacing: 1.5,
          color: AppColors.textPrimary,
        ),
        displaySmall: GoogleFonts.bebasNeue(
          fontSize: 32,
          letterSpacing: 1.0,
          color: AppColors.textPrimary,
        ),

        // ── DM Sans — headings ─────────────────────────────────────────────
        headlineLarge: GoogleFonts.dmSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        // ── DM Sans — titles ───────────────────────────────────────────────
        titleLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleSmall: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),

        // ── DM Sans — body ─────────────────────────────────────────────────
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),

        // ── JetBrains Mono — metrics, timers, tags ─────────────────────────
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
          color: AppColors.textDisabled,
        ),
      );
}
