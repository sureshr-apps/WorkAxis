import 'package:flutter/material.dart';

/// Centralized elevation/shadow tokens.
abstract final class AppShadows {
  /// Subtle two-layer shadow used by cards and KPI tiles.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x06000000), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(color: Color(0x04000000), offset: Offset(0, 2), blurRadius: 6),
  ];

  /// Stronger shadow cast by the top console bar over page content.
  static const List<BoxShadow> topBar = [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 3), blurRadius: 6),
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 1), blurRadius: 2),
  ];
}
