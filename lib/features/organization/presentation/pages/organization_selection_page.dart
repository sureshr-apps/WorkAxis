import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/access_control/domain/entities/organization_membership.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';
import 'package:workaxis/features/organization/presentation/widgets/organization_card.dart';

class OrganizationSelectionPage extends StatefulWidget {
  const OrganizationSelectionPage({super.key});

  @override
  State<OrganizationSelectionPage> createState() =>
      _OrganizationSelectionPageState();
}

class _OrganizationSelectionPageState extends State<OrganizationSelectionPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orgController = context.watch<OrganizationContextController>();
    final state = orgController.state;

    List<OrganizationMembership> memberships = [];
    if (state is OrganizationSelectionRequiredState) {
      memberships = state.memberships;
    } else if (state is AccessGrantedState) {
      memberships = state.allMemberships;
    } else if (state is BranchAssignmentRequiredState) {
      memberships = state.allMemberships;
    }

    final filteredMemberships = memberships.where((m) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final orgMatch = m.organization.name.toLowerCase().contains(q);
      final roleMatch = m.role.displayName.toLowerCase().contains(q);
      final branchMatch = m.branchName?.toLowerCase().contains(q) ?? false;
      return orgMatch || roleMatch || branchMatch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Select Organization'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.onSurfaceVariant),
            tooltip: 'Sign Out',
            onPressed: () async {
              await context.read<AuthController>().signOut();
              if (context.mounted) {
                context.read<OrganizationContextController>().clear();
                context.go('/welcome');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= AppBreakpoints.mediumMin;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 960 : 600,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet
                        ? AppSpacing.marginMedium
                        : AppSpacing.marginCompact,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Organizations',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Choose a workspace to continue with your assigned role and branch.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Search Input
                      AppTextField(
                        hintText: 'Search organizations, branches, or roles...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.onSurfaceVariant),
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Organization List or Grid
                      Expanded(
                        child: filteredMemberships.isEmpty
                            ? Center(
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'No organizations found.'
                                      : 'No organizations match "$_searchQuery".',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : isTablet
                                ? GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisExtent: 110,
                                      crossAxisSpacing: AppSpacing.md,
                                      mainAxisSpacing: AppSpacing.md,
                                    ),
                                    itemCount: filteredMemberships.length,
                                    itemBuilder: (context, index) {
                                      final membership =
                                          filteredMemberships[index];
                                      return OrganizationCard(
                                        membership: membership,
                                        isActive: orgController.activeMembership
                                                ?.organizationId ==
                                            membership.organizationId,
                                        onTap: () {
                                          orgController
                                              .selectOrganization(membership);
                                        },
                                      );
                                    },
                                  )
                                : ListView.separated(
                                    itemCount: filteredMemberships.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: AppSpacing.sm),
                                    itemBuilder: (context, index) {
                                      final membership =
                                          filteredMemberships[index];
                                      return OrganizationCard(
                                        membership: membership,
                                        isActive: orgController.activeMembership
                                                ?.organizationId ==
                                            membership.organizationId,
                                        onTap: () {
                                          orgController
                                              .selectOrganization(membership);
                                        },
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
