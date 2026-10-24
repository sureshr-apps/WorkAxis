import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';

class OrganizationAdministratorsTab extends StatefulWidget {
  const OrganizationAdministratorsTab({
    super.key,
    required this.organizationName,
    required this.administrators,
    required this.onAddAdministrator,
    required this.onAdministratorAction,
  });

  final String organizationName;
  final List<OrganizationAdminUser> administrators;
  final VoidCallback onAddAdministrator;
  final void Function(OrganizationAdminUser administrator, String action)
  onAdministratorAction;

  @override
  State<OrganizationAdministratorsTab> createState() =>
      _OrganizationAdministratorsTabState();
}

class _OrganizationAdministratorsTabState
    extends State<OrganizationAdministratorsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final administrators = widget.administrators.where((admin) {
      if (query.isEmpty) return true;
      return admin.name.toLowerCase().contains(query) ||
          admin.displayUsername.toLowerCase().contains(query) ||
          admin.email.toLowerCase().contains(query) ||
          admin.phone.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AdministratorsIntro(
          organizationName: widget.organizationName,
          onAddAdministrator: widget.onAddAdministrator,
        ),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AppTextField.search(
            controller: _searchController,
            hintText:
                'Search administrators by name, username, email, or phone',
            onChanged: (value) => setState(() => _query = value),
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (administrators.isEmpty)
          _EmptyAdministratorsState(query: _query)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return _AdministratorsTable(
                  administrators: administrators,
                  onAction: widget.onAdministratorAction,
                );
              }
              if (context.isMedium) {
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: administrators.map((admin) {
                    final cardWidth =
                        (constraints.maxWidth - AppSpacing.md) / 2;
                    return SizedBox(
                      width: cardWidth,
                      child: _AdministratorCard(
                        administrator: admin,
                        onAction: (action) =>
                            widget.onAdministratorAction(admin, action),
                      ),
                    );
                  }).toList(),
                );
              }
              return Column(
                children: administrators
                    .map(
                      (admin) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _AdministratorCard(
                          administrator: admin,
                          onAction: (action) =>
                              widget.onAdministratorAction(admin, action),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
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
  final VoidCallback onAddAdministrator;

  @override
  Widget build(BuildContext context) {
    return _WhitePanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 660;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tenant Administrators',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Personnel authorized to manage store operations, catalog configurations, and registers for $organizationName',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          );
          final addButton = FilledButton.icon(
            onPressed: onAddAdministrator,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Administrator'),
            style: FilledButton.styleFrom(
              minimumSize: Size(
                isCompact ? double.infinity : 152,
                AppSpacing.minTouchTarget,
              ),
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
            ),
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

class _AdministratorsTable extends StatelessWidget {
  const _AdministratorsTable({
    required this.administrators,
    required this.onAction,
  });

  final List<OrganizationAdminUser> administrators;
  final void Function(OrganizationAdminUser administrator, String action)
  onAction;

  @override
  Widget build(BuildContext context) {
    return _WhitePanel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppSpacing.roundedMd,
        child: Column(
          children: [
            const _TableHeader(),
            for (var index = 0; index < administrators.length; index++) ...[
              if (index > 0)
                const Divider(height: 1, color: AppColors.outlineSubtle),
              _AdministratorRow(
                administrator: administrators[index],
                onAction: (action) => onAction(administrators[index], action),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      child: Row(
        children: [
          _HeaderCell('ADMINISTRATOR', flex: 20),
          _HeaderCell('USERNAME', flex: 14),
          _HeaderCell('CONTACT DETAILS', flex: 22),
          _HeaderCell('STATUS', flex: 12),
          _HeaderCell('LAST LOGIN', flex: 13),
          _HeaderCell('ACTIONS', flex: 18, alignment: Alignment.centerRight),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex, this.alignment});

  final String label;
  final int flex;
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment ?? Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.secondary,
          ),
        ),
      ),
    );
  }
}

class _AdministratorRow extends StatelessWidget {
  const _AdministratorRow({
    required this.administrator,
    required this.onAction,
  });

  final OrganizationAdminUser administrator;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 9,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 20,
            child: Row(
              children: [
                _InitialAvatar(initials: administrator.initials),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        administrator.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        administrator.displayUsername,
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _UsernameBadge(username: administrator.displayUsername),
            ),
          ),
          Expanded(
            flex: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  administrator.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  administrator.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(
                label: administrator.status.toUpperCase(),
                type: administrator.status.toLowerCase() == 'active'
                    ? StatusType.active
                    : StatusType.urgent,
                width: 96,
              ),
            ),
          ),
          Expanded(
            flex: 13,
            child: Text(
              administrator.lastLogin ?? '—',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Align(
              alignment: Alignment.centerRight,
              child: _AdminActions(onAction: onAction),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdministratorCard extends StatelessWidget {
  const _AdministratorCard({
    required this.administrator,
    required this.onAction,
  });

  final OrganizationAdminUser administrator;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return _WhitePanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _InitialAvatar(initials: administrator.initials),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      administrator.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      administrator.displayUsername,
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: administrator.status.toUpperCase(),
                type: administrator.status.toLowerCase() == 'active'
                    ? StatusType.active
                    : StatusType.urgent,
                width: 96,
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg * 2),
          _MobileContactRow(
            icon: Icons.mail_outline,
            value: administrator.email,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MobileContactRow(
            icon: Icons.call_outlined,
            value: administrator.phone,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MobileContactRow(
            icon: Icons.schedule_outlined,
            value: 'Last login: ${administrator.lastLogin ?? '—'}',
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _AdminActions(onAction: onAction),
          ),
        ],
      ),
    );
  }
}

class _MobileContactRow extends StatelessWidget {
  const _MobileContactRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.secondary),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}

class _AdminActions extends StatelessWidget {
  const _AdminActions({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    const actions = <(String, IconData, String)>[
      ('edit', Icons.edit_outlined, 'Edit administrator'),
      ('reset', Icons.key_outlined, 'Reset password'),
      ('suspend', Icons.person_off_outlined, 'Suspend administrator'),
      ('remove', Icons.delete_outline, 'Remove administrator'),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (action, icon, tooltip) in actions)
          IconButton(
            tooltip: tooltip,
            onPressed: () => onAction(action),
            icon: Icon(icon, size: 17, color: AppColors.secondary),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initials});

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
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.tertiary,
      ),
    ),
  );
}

class _UsernameBadge extends StatelessWidget {
  const _UsernameBadge({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      border: Border.all(color: AppColors.outlineVariant),
      borderRadius: AppSpacing.roundedXs,
    ),
    child: Text(
      username,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.robotoMono(fontSize: 10, color: AppColors.primaryDark),
    ),
  );
}

class _EmptyAdministratorsState extends StatelessWidget {
  const _EmptyAdministratorsState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) => _WhitePanel(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Column(
      children: [
        const Icon(Icons.people_outline, size: 36, color: AppColors.secondary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          query.isEmpty
              ? 'No administrators assigned'
              : 'No matching administrators',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          query.isEmpty
              ? 'No active organization administrators have been provisioned for this organization.'
              : 'Try another name, username, email, or phone number.',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _WhitePanel extends StatelessWidget {
  const _WhitePanel({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
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
