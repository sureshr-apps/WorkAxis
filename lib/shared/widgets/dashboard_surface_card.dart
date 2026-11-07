import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';

/// White bordered surface used by dashboard sections (attendance, attention).
class DashboardSurfaceCard extends StatelessWidget {
  const DashboardSurfaceCard({super.key, required this.child, this.padding});

  final Widget child;

  /// Overrides the responsive default padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          padding ??
          EdgeInsets.all(context.isCompact ? AppSpacing.md : AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}
