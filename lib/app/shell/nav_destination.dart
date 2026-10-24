import 'package:flutter/material.dart';

/// Represents a navigation destination in the adaptive shell.
class AppNavDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const AppNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}
