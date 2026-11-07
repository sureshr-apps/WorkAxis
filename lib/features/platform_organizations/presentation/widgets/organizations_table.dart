import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';

/// Renders the Stitch-approved structured table for customer organizations on Web and Tablet Landscape.
/// Includes client-side pagination with configurable page size and navigation controls.
class OrganizationsTable extends StatefulWidget {
  final List<CustomerOrganization> organizations;
  final ValueChanged<CustomerOrganization> onSelect;
  final ValueChanged<CustomerOrganization> onEdit;
  final int initialPageSize;
  final List<int> availablePageSizes;

  const OrganizationsTable({
    super.key,
    required this.organizations,
    required this.onSelect,
    required this.onEdit,
    this.initialPageSize = 5,
    this.availablePageSizes = const [5, 10, 25],
  });

  @override
  State<OrganizationsTable> createState() => _OrganizationsTableState();
}

class _OrganizationsTableState extends State<OrganizationsTable> {
  int _currentPage = 0;
  late int _pageSize;

  @override
  void initState() {
    super.initState();
    _pageSize = widget.initialPageSize;
  }

  @override
  void didUpdateWidget(OrganizationsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizations != widget.organizations) {
      final totalPages = widget.organizations.isEmpty
          ? 1
          : (widget.organizations.length / _pageSize).ceil();
      if (_currentPage >= totalPages) {
        _currentPage = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    const minimumTableWidth = 920.0;

    final totalItems = widget.organizations.length;
    final totalPages = totalItems == 0 ? 1 : (totalItems / _pageSize).ceil();
    final safePage = _currentPage.clamp(0, totalPages - 1);
    final startIndex = totalItems == 0 ? 0 : safePage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, totalItems);
    final pagedOrganizations = totalItems == 0
        ? const <CustomerOrganization>[]
        : widget.organizations.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineSubtle, width: 1),
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
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth < minimumTableWidth
              ? minimumTableWidth
              : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Table Header
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.outlineSubtle,
                          width: 1,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'ORGANIZATION',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'CODE',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'STATUS',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'BRANCHES',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'EMPLOYEES',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'ONBOARDED',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'ACTIONS',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Rows
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pagedOrganizations.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.outlineSubtle,
                    ),
                    itemBuilder: (context, index) {
                      final org = pagedOrganizations[index];
                      return _buildTableRow(context, org, dateFormat);
                    },
                  ),

                  // Table Footer with Pagination Controls
                  _buildFooter(
                    context,
                    totalItems: totalItems,
                    startIndex: startIndex,
                    endIndex: endIndex,
                    safePage: safePage,
                    totalPages: totalPages,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context, {
    required int totalItems,
    required int startIndex,
    required int endIndex,
    required int safePage,
    required int totalPages,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: AppColors.outlineSubtle, width: 1),
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Item range summary (Expanded so it adapts cleanly)
          Expanded(
            child: Text(
              totalItems == 0
                  ? 'Showing 0 organizations'
                  : 'Showing ${startIndex + 1}–$endIndex of $totalItems organizations',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.secondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Right: Rows per page + Page Navigation + Platform Fleet
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rows: ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.secondary,
                ),
              ),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.outlineSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _pageSize,
                    isDense: true,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    items: widget.availablePageSizes.map((size) {
                      return DropdownMenuItem<int>(
                        value: size,
                        child: Text('$size'),
                      );
                    }).toList(),
                    onChanged: (newSize) {
                      if (newSize != null && newSize != _pageSize) {
                        setState(() {
                          _pageSize = newSize;
                          _currentPage = 0;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              Text(
                'Page ${safePage + 1} of $totalPages',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 4),

              IconButton(
                icon: const Icon(Icons.first_page, size: 18),
                tooltip: 'First page',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                color: AppColors.onSurfaceVariant,
                disabledColor: AppColors.outlineSubtle,
                onPressed: safePage > 0
                    ? () => setState(() => _currentPage = 0)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                tooltip: 'Previous page',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                color: AppColors.onSurfaceVariant,
                disabledColor: AppColors.outlineSubtle,
                onPressed: safePage > 0
                    ? () => setState(() => _currentPage = safePage - 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                tooltip: 'Next page',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                color: AppColors.onSurfaceVariant,
                disabledColor: AppColors.outlineSubtle,
                onPressed: safePage < totalPages - 1
                    ? () => setState(() => _currentPage = safePage + 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page, size: 18),
                tooltip: 'Last page',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                color: AppColors.onSurfaceVariant,
                disabledColor: AppColors.outlineSubtle,
                onPressed: safePage < totalPages - 1
                    ? () => setState(() => _currentPage = totalPages - 1)
                    : null,
              ),

              Container(
                height: 18,
                width: 1,
                color: AppColors.outlineSubtle,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fleet: ',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.secondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.outlineSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.statusActive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'INDIA',
                          style: GoogleFonts.robotoMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    CustomerOrganization org,
    DateFormat dateFormat,
  ) {
    return InkWell(
      onTap: () => widget.onSelect(org),
      hoverColor: AppColors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Organization Name
            Expanded(
              flex: 3,
              child: Text(
                org.name,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Code
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.outlineSubtle,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    org.code,
                    style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

            // Status
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusChip.fromStatus(org.status.displayName, width: 96),
              ),
            ),

            // Branches
            Expanded(
              flex: 2,
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: '${org.branchCount}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: ' hubs',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Employees
            Expanded(
              flex: 2,
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: '${org.employeeCount}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: ' staff',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Onboarded Date
            Expanded(
              flex: 2,
              child: Text(
                dateFormat.format(org.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),

            // Actions
            SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Details',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
