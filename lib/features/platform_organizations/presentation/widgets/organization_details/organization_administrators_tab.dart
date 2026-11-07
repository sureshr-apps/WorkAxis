import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrator_action_buttons.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrator_card.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrator_parts.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrators_table.dart';

/// Administrators of one organization: search, add, and per-admin actions.
///
/// The tab only renders and reports intent; account changes are performed by
/// the controller through the screen.
class OrganizationAdministratorsTab extends StatefulWidget {
  const OrganizationAdministratorsTab({
    super.key,
    required this.organizationName,
    required this.administrators,
    required this.onAddAdministrator,
    required this.onAdministratorAction,
    required this.canSuspend,
    this.enabled = true,
  });

  final String organizationName;
  final List<OrganizationAdminUser> administrators;
  final VoidCallback onAddAdministrator;
  final AdministratorActionCallback onAdministratorAction;

  /// Whether an administrator may be suspended (false for the last active).
  final bool Function(OrganizationAdminUser administrator) canSuspend;

  /// False while an account change is in flight.
  final bool enabled;

  @override
  State<OrganizationAdministratorsTab> createState() =>
      _OrganizationAdministratorsTabState();
}

class _OrganizationAdministratorsTabState
    extends State<OrganizationAdministratorsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late List<OrganizationAdminUser> _visible = widget.administrators;

  @override
  void didUpdateWidget(covariant OrganizationAdministratorsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.administrators, widget.administrators)) {
      _visible = _filter(widget.administrators, _query);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static List<OrganizationAdminUser> _filter(
    List<OrganizationAdminUser> all,
    String rawQuery,
  ) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return all;
    return all
        .where(
          (a) =>
              a.name.toLowerCase().contains(query) ||
              a.displayUsername.toLowerCase().contains(query) ||
              a.email.toLowerCase().contains(query) ||
              a.phone.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  void _setQuery(String value) => setState(() {
    _query = value;
    _visible = _filter(widget.administrators, value);
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AdministratorsIntro(
          organizationName: widget.organizationName,
          onAddAdministrator: widget.enabled ? widget.onAddAdministrator : null,
        ),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AppTextField.search(
            controller: _searchController,
            hintText:
                'Search administrators by name, username, email, or phone',
            onChanged: _setQuery,
            onClear: () {
              _searchController.clear();
              _setQuery('');
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_visible.isEmpty)
          AdministratorPanel(
            child: EmptyState(
              icon: Icons.people_outline,
              title: _query.isEmpty
                  ? 'No administrators assigned'
                  : 'No matching administrators',
              message: _query.isEmpty
                  ? 'No organization administrators have been provisioned '
                        'for this organization.'
                  : 'Try another name, username, email, or phone number.',
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) => _buildList(constraints.maxWidth),
          ),
      ],
    );
  }

  Widget _buildList(double width) {
    if (width >= AppBreakpoints.wideContent) {
      return AdministratorsTable(
        administrators: _visible,
        onAction: widget.onAdministratorAction,
        canSuspend: widget.canSuspend,
        enabled: widget.enabled,
      );
    }
    final columns = width >= AppBreakpoints.mediumMin ? 2 : 1;
    final cardWidth = (width - AppSpacing.md * (columns - 1)) / columns;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final admin in _visible)
          SizedBox(
            width: cardWidth,
            child: AdministratorCard(
              administrator: admin,
              onAction: widget.onAdministratorAction,
              canSuspend: widget.canSuspend(admin),
              enabled: widget.enabled,
            ),
          ),
      ],
    );
  }
}

class _AdministratorsIntro extends StatelessWidget {
  const _AdministratorsIntro({
    required this.organizationName,
    required this.onAddAdministrator,
  });

  final String organizationName;
  final VoidCallback? onAddAdministrator;

  @override
  Widget build(BuildContext context) {
    return AdministratorPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < AppBreakpoints.formSplit;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tenant Administrators',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Personnel authorized to manage operations for '
                '$organizationName',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          );
          final addButton = AppButton.responsive(
            text: 'Add Administrator',
            iconData: Icons.add,
            onPressed: onAddAdministrator,
          );
          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: AppSpacing.md),
                addButton,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: AppSpacing.md),
              addButton,
            ],
          );
        },
      ),
    );
  }
}
