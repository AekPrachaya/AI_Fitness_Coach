import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppShadows {
  // 0px 2px 8px rgba(0,0,0,0.4)
  static const List<BoxShadow> low = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // 0px 8px 24px rgba(0,0,0,0.6)
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x99000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  // 0px 16px 48px rgba(0,0,0,0.8)
  static const List<BoxShadow> high = [
    BoxShadow(
      color: Color(0xCC000000),
      blurRadius: 48,
      offset: Offset(0, 16),
    ),
  ];

  // 0px 0px 20px rgba(0,245,160,0.3) — accent glow for brand elements
  static const List<BoxShadow> glow = [
    BoxShadow(
      color: AppColors.accentGlow,
      blurRadius: 20,
    ),
  ];
}
