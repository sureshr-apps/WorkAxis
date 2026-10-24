import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';

class OrganizationOverviewTab extends StatelessWidget {
  const OrganizationOverviewTab({
    super.key,
    required this.organization,
    required this.license,
    required this.onUpload,
  });

  final CustomerOrganization organization;
  final OrganizationLicenseDetails? license;
  final ValueChanged<String> onUpload;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          final contentWidth = constraints.maxWidth - AppSpacing.lg;
          final profileWidth = contentWidth * 7 / 12;
          final detailsWidth = contentWidth * 5 / 12;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: _OrganizationProfileCard(
                    organization: organization,
                    compactRows: profileWidth < 500,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _OrganizationMetrics(
                        organization: organization,
                        license: license,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _BrandingAndPaymentCard(
                        onUpload: onUpload,
                        narrowAssets: detailsWidth < 360,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final profileWidth = constraints.maxWidth - AppSpacing.lg * 2;
        final detailsWidth = constraints.maxWidth - AppSpacing.md * 2;
        return Column(
          children: [
            _OrganizationProfileCard(
              organization: organization,
              compactRows: profileWidth < 500,
            ),
            const SizedBox(height: AppSpacing.md),
            _OrganizationMetrics(organization: organization, license: license),
            const SizedBox(height: AppSpacing.md),
            _BrandingAndPaymentCard(
              onUpload: onUpload,
              narrowAssets: detailsWidth < 360,
            ),
          ],
        );
      },
    );
  }
}

class _OrganizationProfileCard extends StatelessWidget {
  const _OrganizationProfileCard({
    required this.organization,
    required this.compactRows,
  });

  final CustomerOrganization organization;
  final bool compactRows;

  @override
  Widget build(BuildContext context) {
    return _DetailsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.apartment_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'ORGANIZATION PROFILE',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: const Color(0xFF86EFAC),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 12,
                        color: Color(0xFF15803D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Entity Verified',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileRow(
                  label: 'GSTIN / Tax ID',
                  compact: compactRows,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.outlineSubtle),
                    ),
                    child: Text(
                      (organization.taxIdentification?.trim().isNotEmpty ?? false)
                          ? organization.taxIdentification!.trim()
                          : '—',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
                _ProfileRow(
                  label: 'Primary Contact',
                  compact: compactRows,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        organization.contactName ?? 'Not provided',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.mail_outline,
                              size: 16,
                              color: Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                organization.contactEmail ?? 'No email',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Text(
                              'Platform Contact',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.call_outlined,
                              size: 16,
                              color: Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                organization.contactPhone ?? 'No phone',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Text(
                              'Direct Operations Line',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _ProfileRow(
                  label: 'Headquarters Address',
                  compact: compactRows,
                  isLast: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            organization.address ?? 'Not provided',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0F172A),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.child,
    required this.compact,
    this.isLast = false,
  });

  final String label;
  final Widget child;
  final bool compact;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.outlineSubtle)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileLabel(label: label),
                const SizedBox(height: AppSpacing.sm),
                child,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 200, child: _ProfileLabel(label: label)),
                Expanded(child: child),
              ],
            ),
    );
  }
}

class _ProfileLabel extends StatelessWidget {
  const _ProfileLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
  );
}

class _OrganizationMetrics extends StatelessWidget {
  const _OrganizationMetrics({
    required this.organization,
    required this.license,
  });

  final CustomerOrganization organization;
  final OrganizationLicenseDetails? license;

  @override
  Widget build(BuildContext context) {
    return ResponsiveKpiSection(
      cardHeight: 96,
      cards: [
        AppKpiCard(
          title: 'Stores Active',
          value: '${organization.branchCount}',
          accentColor: const Color(0xFF003366),
          icon: Icons.storefront_outlined,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primaryContainer,
        ),
        AppKpiCard(
          title: 'Tenant Admins',
          value: '${organization.admins.length}',
          accentColor: const Color(0xFF0284C7),
          icon: Icons.people_outline,
          iconColor: const Color(0xFF0284C7),
          iconBgColor: const Color(0xFFE0F2FE),
        ),
      ],
    );
  }
}

class _BrandingAndPaymentCard extends StatelessWidget {
  const _BrandingAndPaymentCard({
    required this.onUpload,
    required this.narrowAssets,
  });

  final ValueChanged<String> onUpload;
  final bool narrowAssets;

  @override
  Widget build(BuildContext context) {
    return _DetailsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: AppColors.outlineSubtle),
              ),
            ),
            child: Text(
              'BRANDING & PAYMENT',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _BrandAssetRow(
                  title: 'Organization Logo',
                  description: 'PNG, JPEG, or WebP up to 2 MB. Used in organization identity and printed receipts.',
                  icon: Icons.image_outlined,
                  narrow: narrowAssets,
                  onUpload: () => onUpload('Organization Logo'),
                ),
                const SizedBox(height: AppSpacing.md),
                _BrandAssetRow(
                  title: 'Payment QR Code',
                  description: 'PNG, JPEG, or WebP up to 1 MB. Printed on customer receipts for scan-and-pay.',
                  icon: Icons.qr_code_2_outlined,
                  narrow: narrowAssets,
                  onUpload: () => onUpload('Payment QR Code'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandAssetRow extends StatelessWidget {
  const _BrandAssetRow({
    required this.title,
    required this.description,
    required this.icon,
    required this.narrow,
    required this.onUpload,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool narrow;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final image = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: AppSpacing.roundedXs,
      ),
      child: Icon(icon, size: 30, color: AppColors.secondary),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 11,
            height: 1.4,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.tonalIcon(
          onPressed: onUpload,
          icon: const Icon(Icons.upload_outlined, size: 16),
          label: const Text('Upload'),
          style: FilledButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppColors.tertiaryContainer,
            minimumSize: const Size(82, 36),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXs),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineSubtle),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image,
                const SizedBox(height: AppSpacing.md),
                details,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image,
                const SizedBox(width: AppSpacing.md),
                Expanded(child: details),
              ],
            ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      border: Border.all(color: AppColors.outlineSubtle),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          offset: Offset(0, 2),
          blurRadius: 8,
        ),
        BoxShadow(
          color: Color(0x04000000),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    ),
    child: child,
  );
}
