import 'package:flutter/material.dart';

/// Centralized spacing and shape constants based on the 8dp grid standard.
abstract final class AppSpacing {
  /// 2dp micro spacing.
  static const double xxs = 2.0;

  /// 4dp sub-grid spacing.
  static const double xs = 4.0;

  /// 8dp baseline spacing.
  static const double sm = 8.0;

  /// 12dp spacing.
  static const double md = 12.0;

  /// 16dp spacing (standard margin for mobile).
  static const double lg = 16.0;

  /// 24dp spacing (standard margin for tablet).
  static const double xl = 24.0;

  /// 32dp spacing (desktop web spacing).
  static const double xxl = 32.0;

  /// 48dp touch target dimension.
  static const double minTouchTarget = 48.0;

  /// 64dp standard button minimum width.
  static const double minButtonWidth = 64.0;

  // Corner Radii
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusPill = 9999.0;
  static const double radiusFull = 9999.0;

  // BorderRadius helpers
  static final BorderRadius roundedXs = BorderRadius.circular(radiusXs);
  static final BorderRadius roundedSm = BorderRadius.circular(radiusSm);
  static final BorderRadius roundedMd = BorderRadius.circular(radiusMd);
  static final BorderRadius roundedLg = BorderRadius.circular(radiusLg);
  static final BorderRadius roundedPill = BorderRadius.circular(radiusPill);
}
