import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/features/access_control/presentation/widgets/access_state_view.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

class BranchAssignmentRequiredPage extends StatefulWidget {
  const BranchAssignmentRequiredPage({super.key});

  @override
  State<BranchAssignmentRequiredPage> createState() =>
      _BranchAssignmentRequiredPageState();
}

class _BranchAssignmentRequiredPageState
    extends State<BranchAssignmentRequiredPage> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    final orgController = context.read<OrganizationContextController>();
    await orgController.retryResolution();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgController = context.watch<OrganizationContextController>();
    final state = orgController.state;

    String orgName = 'your organization';
    bool hasMultipleOrgs = false;

    if (state is BranchAssignmentRequiredState) {
      orgName = state.membership.organization.name;
      hasMultipleOrgs = state.allMemberships.length > 1;
    }

    return AccessStateView(
      title: 'Branch Assignment Required',
      description:
          'Your account is active with $orgName, but you do not currently have an assigned branch location. Please contact your organization administrator or manager to assign you to a branch.',
      icon: Icons.store_mall_directory_rounded,
      iconColor: AppColors.statusPending,
      primaryActionText: 'Refresh Status',
      isPrimaryLoading: _isRefreshing,
      onPrimaryAction: _handleRefresh,
      secondaryActionText: hasMultipleOrgs ? 'Switch Organization' : 'Sign Out',
      onSecondaryAction: () async {
        if (hasMultipleOrgs) {
          context.go('/organizations');
        } else {
          await context.read<AuthController>().signOut();
          if (context.mounted) {
            orgController.clear();
            context.go('/welcome');
          }
        }
      },
    );
  }
}
