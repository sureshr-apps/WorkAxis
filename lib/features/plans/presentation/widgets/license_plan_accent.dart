import 'package:flutter/material.dart';

/// Plan colours are not stored; each level has a fixed accent so a plan keeps
/// the same dot colour wherever it is shown. Levels above 4 share violet.
Color licensePlanAccentForLevel(int level) => switch (level) {
  1 => const Color(0xFF0D9488),
  2 => const Color(0xFF16A34A),
  3 => const Color(0xFF2563EB),
  4 => const Color(0xFF9333EA),
  _ => const Color(0xFF6D28D9),
};
