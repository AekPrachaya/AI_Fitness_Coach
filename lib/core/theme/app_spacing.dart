import 'package:flutter/material.dart';

abstract class AppSpacing {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
  static const double xxxl = 64.0;
}

abstract class AppRadius {
  static const double sm     = 8.0;
  static const double md     = 12.0;
  static const double lg     = 20.0;
  static const double xl     = 32.0;
  static const double circle = 999.0;

  static BorderRadius get smAll     => BorderRadius.circular(sm);
  static BorderRadius get mdAll     => BorderRadius.circular(md);
  static BorderRadius get lgAll     => BorderRadius.circular(lg);
  static BorderRadius get xlAll     => BorderRadius.circular(xl);
  static BorderRadius get circleAll => BorderRadius.circular(circle);
}
