import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';

/// Tooltip shown on the disabled suspend action of the only active admin.
const String lastActiveAdminTooltip =
    'The only active administrator cannot be suspended';

/// Shows a missing optional value as an em dash.
String orDash(String value) => value.trim().isEmpty ? '—' : value;

/// White bordered panel used by the administrators tab.
class AdministratorPanel extends StatelessWidget {
  const AdministratorPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      border: Border.all(color: AppColors.outlineSubtle),
      borderRadius: AppSpacing.roundedMd,
      boxShadow: AppShadows.card,
    ),
    child: child,
  );
}

/// Round avatar with the administrator's initials.
class AdministratorAvatar extends StatelessWidget {
  const AdministratorAvatar({super.key, required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
      shape: BoxShape.circle,
      border: Border.all(
        color: AppColors.tertiaryContainer.withValues(alpha: 0.25),
      ),
    ),
    child: Text(
      initials,
      style: AppTypography.labelSmall.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.tertiary,
      ),
    ),
  );
}

/// Active / suspended chip for an administrator.
class AdministratorStatusChip extends StatelessWidget {
  const AdministratorStatusChip({super.key, required this.status});

  final OrganizationAdminStatus status;

  @override
  Widget build(BuildContext context) => StatusChip(
    label: status.label.toUpperCase(),
    type: status == OrganizationAdminStatus.active
        ? StatusType.active
        : StatusType.urgent,
  );
}

/// Name and username stacked in the first table column / card header.
class AdministratorIdentity extends StatelessWidget {
  const AdministratorIdentity({super.key, required this.administrator});

  final OrganizationAdminUser administrator;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      AdministratorAvatar(initials: administrator.initials),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              administrator.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              administrator.displayUsername,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
