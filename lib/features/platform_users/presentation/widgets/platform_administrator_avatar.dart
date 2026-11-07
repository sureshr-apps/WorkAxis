import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// Rounded-square initials avatar for a platform administrator.
class PlatformAdministratorAvatar extends StatelessWidget {
  const PlatformAdministratorAvatar({
    super.key,
    required this.initials,
    this.size = 40,
  });

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: AppSpacing.roundedSm,
          border: Border.all(color: AppColors.outlineSubtle),
        ),
        child: Text(
          initials,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
