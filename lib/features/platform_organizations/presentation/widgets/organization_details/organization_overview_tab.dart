import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/attachment_image.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';

class OrganizationOverviewTab extends StatelessWidget {
  const OrganizationOverviewTab({
    super.key,
    required this.organization,
    required this.onUpload,
  });

  final CustomerOrganization organization;
  final FutureOr<void> Function() onUpload;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          final contentWidth = constraints.maxWidth - AppSpacing.lg;
          final profileWidth = contentWidth * 7 / 12;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    _OrganizationMetrics(organization: organization),
                    const SizedBox(height: AppSpacing.md),
                    _BrandingCard(
                      logoUrl: organization.logoUrl,
                      onUpload: onUpload,
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final profileWidth = constraints.maxWidth - AppSpacing.lg * 2;
        return Column(
          children: [
            _OrganizationProfileCard(
              organization: organization,
              compactRows: profileWidth < 500,
            ),
            const SizedBox(height: AppSpacing.md),
            _OrganizationMetrics(organization: organization),
            const SizedBox(height: AppSpacing.md),
            _BrandingCard(logoUrl: organization.logoUrl, onUpload: onUpload),
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
              border: Border(bottom: BorderSide(color: AppColors.kpiBorder)),
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
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusChip(
                  label: organization.status.displayName.toUpperCase(),
                  type: organization.isActive
                      ? StatusType.active
                      : StatusType.urgent,
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
                      (organization.taxIdentification?.trim().isNotEmpty ??
                              false)
                          ? organization.taxIdentification!.trim()
                          : '—',
                      style: AppTypography.labelMono.copyWith(
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
                        style: AppTypography.bodyMedium.copyWith(
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
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.kpiBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.mail_outline,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(
                                organization.contactEmail ?? 'No email',
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kpiValue,
                                ),
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
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.kpiBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.call_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(
                                organization.contactPhone ?? 'No phone',
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kpiValue,
                                ),
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
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.kpiBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            organization.address ?? 'Not provided',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.kpiValue,
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
    style: AppTypography.labelMedium.copyWith(color: AppColors.secondary),
  );
}

class _OrganizationMetrics extends StatelessWidget {
  const _OrganizationMetrics({required this.organization});

  final CustomerOrganization organization;

  @override
  Widget build(BuildContext context) {
    return ResponsiveKpiSection(
      cardHeight: 96,
      cards: [
        AppKpiCard(
          title: 'Stores Active',
          value: organization.branchCount?.toString() ?? '—',
          accentColor: AppColors.primaryDark,
          icon: Icons.storefront_outlined,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primaryContainer,
        ),
        AppKpiCard(
          title: 'Tenant Admins',
          value: '${organization.admins.length}',
          accentColor: AppColors.primary,
          icon: Icons.people_outline,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primaryContainer,
        ),
      ],
    );
  }
}

class _BrandingCard extends StatelessWidget {
  const _BrandingCard({required this.logoUrl, required this.onUpload});

  final String? logoUrl;
  final FutureOr<void> Function() onUpload;

  @override
  Widget build(BuildContext context) {
    return _DetailsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BrandingHeader(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LogoUploadCard(logoUrl: logoUrl, onUpload: onUpload),
                const SizedBox(height: AppSpacing.md),
                const _PrinterNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandingHeader extends StatelessWidget {
  const _BrandingHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: AppColors.outlineSubtle)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.palette_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'BRANDING & IDENTITY',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoUploadCard extends StatelessWidget {
  const _LogoUploadCard({required this.logoUrl, required this.onUpload});

  final String? logoUrl;
  final FutureOr<void> Function() onUpload;

  @override
  Widget build(BuildContext context) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PNG or JPG',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Up to 2 MB • Recommended 512×512px',
          style: AppTypography.labelSmall.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton.primary(
              text: 'Upload',
              iconData: Icons.file_upload_outlined,
              isFullWidth: false,
              onPressed: onUpload,
            ),
          ],
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineSubtle),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: 4,
            children: [
              Text(
                'Organization Logo',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const _RequiredBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Used for digital invoices, store receipts, and invoice headers.',
            style: AppTypography.labelMedium.copyWith(
              height: 1.4,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LogoPreview(logoUrl: logoUrl),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: details),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequiredBadge extends StatelessWidget {
  const _RequiredBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.statusPendingContainer,
        border: Border.all(color: AppColors.statusPendingBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Required',
        style: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.statusPendingText,
        ),
      ),
    );
  }
}

/// Organization logo preview, with a placeholder before the first upload.
class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.logoUrl});

  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final reference = logoUrl?.trim();
    if (reference != null && reference.isNotEmpty) {
      return Container(
        width: 104,
        height: 104,
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: AttachmentImage(reference: reference, fit: BoxFit.contain),
      );
    }

    return CustomPaint(
      painter: const _DashedRoundedRectPainter(
        color: AppColors.outlineVariant,
        radius: 10,
      ),
      child: SizedBox(
        width: 104,
        height: 104,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              size: 26,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 6),
            Text(
              'Preview',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 6.0;
    const gap = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _PrinterNote extends StatelessWidget {
  const _PrinterNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.8),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Logos will automatically adapt to monochrome thermal printers '
              '(80mm & 58mm).',
              style: AppTypography.labelMedium.copyWith(
                height: 1.4,
                color: AppColors.secondary,
              ),
            ),
          ),
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
      boxShadow: AppShadows.card,
    ),
    child: child,
  );
}
