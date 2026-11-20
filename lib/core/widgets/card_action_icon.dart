import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/app_icon_button.dart';

/// Compact icon action in a list tile's footer, with a full 48dp touch target.
/// The tooltip doubles as the accessible label, so it names the record.
class CardActionIcon extends StatelessWidget {
  const CardActionIcon({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final FutureOr<void> Function() onPressed;

  static const BoxConstraints _touchTarget = BoxConstraints(
    minWidth: AppSpacing.minTouchTarget,
    minHeight: AppSpacing.minTouchTarget,
  );

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      tooltip: tooltip,
      icon: icon,
      color: color,
      constraints: _touchTarget,
      onPressed: onPressed,
    );
  }
}
