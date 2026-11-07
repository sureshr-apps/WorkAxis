import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';

/// Shows the Organization Admin's (single) organization scope.
///
/// Renders the organization name when the access context provides one and a
/// neutral "SCOPE" label otherwise; no placeholder organization is invented.
class OrgScopeCard extends StatelessWidget {
  const OrgScopeCard({super.key, this.organizationName});

  final String? organizationName;

  @override
  Widget build(BuildContext context) {
    final name = organizationName;
    final hasName = name != null && name.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasName ? name : 'SCOPE',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: hasName ? 12 : 11,
                fontWeight: FontWeight.w600,
                color: hasName ? AppColors.onSurface : AppColors.secondary,
                letterSpacing: hasName ? 0 : 0.5,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.statusActiveContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Text(
              'Single Org',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.statusActiveText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
