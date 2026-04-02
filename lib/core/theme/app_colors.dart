import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background      = Color(0xFF0A0A0F);
  static const Color surface         = Color(0xFF13131A);
  static const Color surfaceElevated = Color(0xFF1C1C27);

  // ── Accents ───────────────────────────────────────────────────────────────
  static const Color accent     = Color(0xFF00F5A0); // electric mint green — primary brand
  static const Color accentBlue = Color(0xFF00C9FF); // electric blue — secondary
  static const Color accentGlow = Color(0x4D00F5A0); // accent at 30% opacity

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color error   = Color(0xFFFF4D4D);
  static const Color warning = Color(0xFFFFB800);
  static const Color success = Color(0xFF00F5A0); // same as accent

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A8A9A);
  static const Color textDisabled  = Color(0xFF3D3D52);

  // ── Borders & Dividers ────────────────────────────────────────────────────
  static const Color divider      = Color(0xFF1E1E2E);
  static const Color borderSubtle = Color(0x1AFFFFFF); // white 10%
  static const Color borderMedium = Color(0x33FFFFFF); // white 20%

  // ── Form score ────────────────────────────────────────────────────────────
  static const Color scoreGood = Color(0xFF00F5A0); // >= 85%
  static const Color scoreOk   = Color(0xFFFFB800); // 70–84%
  static const Color scorePoor = Color(0xFFFF4D4D); // < 70%

  // ── Difficulty ────────────────────────────────────────────────────────────
  static const Color diffBeginner     = Color(0xFF00C896);
  static const Color diffIntermediate = Color(0xFF00C9FF);
  static const Color diffAdvanced     = Color(0xFFFF8C00);

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Color formScoreColor(double score) {
    if (score >= 85) return scoreGood;
    if (score >= 70) return scoreOk;
    return scorePoor;
  }

  static Color difficultyColor(String difficulty) =>
      switch (difficulty.toLowerCase()) {
        'beginner'     => diffBeginner,
        'intermediate' => diffIntermediate,
        'advanced'     => diffAdvanced,
        _              => textSecondary,
      };
}
