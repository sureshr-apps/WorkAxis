import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/shell/widgets/shell_labels.dart';
import 'package:workaxis/app/shell/widgets/user_profile_menu.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/features/access/domain/models/organization_summary.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Full-width console bar of the expanded layout.
///
/// Brand block (aligned with the sidebar), role badge or organization context,
/// and the user profile menu. All identity text comes from the access context;
/// nothing is shown until it is available.
class TopConsoleBar extends StatelessWidget {
  const TopConsoleBar({
    super.key,
    required this.onSignOut,
    this.role,
    this.organization,
    this.userName,
  });

  final UserRole? role;
  final OrganizationSummary? organization;
  final String? userName;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppBreakpoints.topBarHeight,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: AppColors.kpiBorder, width: 1.0),
        ),
        boxShadow: AppShadows.topBar,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _BrandBlock(role: role, organizationName: organization?.name),
          const _SectionDivider(),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: role == UserRole.orgAdmin
                ? _OrganizationContext(organization: organization)
                : _ConsoleTitle(role: role),
          ),
          const SizedBox(width: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xl),
            child: UserProfileMenu(
              userName: userName,
              roleLabel: role?.displayName,
              showNameAndRole: true,
              onSignOut: onSignOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({required this.role, required this.organizationName});

  final UserRole? role;
  final String? organizationName;

  @override
  Widget build(BuildContext context) {
    final isOrgAdmin = role == UserRole.orgAdmin;
    final subLabel = isOrgAdmin
        ? organizationName?.toUpperCase()
        : 'MANAGEMENT';

    return SizedBox(
      width: AppBreakpoints.sidebarWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppSpacing.roundedSm,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.hub_outlined,
                color: AppColors.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ops Hub',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.2,
                      color: AppColors.onSurface,
                    ),
                  ),
                  if (subLabel != null && subLabel.isNotEmpty)
                    Text(
                      subLabel,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isOrgAdmin
                            ? AppColors.secondary
                            : AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      decoration: const BoxDecoration(
        color: AppColors.outlineSubtle,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(1.5, 0),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0.5, 0),
            blurRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _OrganizationContext extends StatelessWidget {
  const _OrganizationContext({required this.organization});

  final OrganizationSummary? organization;

  @override
  Widget build(BuildContext context) {
    final name = organization?.name;
    final code = organization?.code;
    if (name == null || name.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.corporate_fare, color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (code != null && code.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.xs),
          const Text(
            '•',
            style: TextStyle(color: AppColors.outline, fontSize: 14),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: AppSpacing.roundedXs,
            ),
            child: Text(
              code,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ConsoleTitle extends StatelessWidget {
  const _ConsoleTitle({required this.role});

  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            'Operations Hub',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.consoleBadgeBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Text(
            consoleBadgeTextFor(role),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.consoleBadgeForeground,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
