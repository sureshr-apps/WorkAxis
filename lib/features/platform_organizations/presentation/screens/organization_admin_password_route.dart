import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/core/widgets/record_not_found_page.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_admin_password_page.dart';

/// Routed entry for resetting an administrator's password. Loads the
/// organization and the administrator, saves through
/// [PlatformOrganizationsController], then returns to the organization.
class OrganizationAdminPasswordRoute extends StatefulWidget {
  const OrganizationAdminPasswordRoute({
    super.key,
    required this.organizationId,
    required this.administratorId,
  });

  final String organizationId;
  final String administratorId;

  @override
  State<OrganizationAdminPasswordRoute> createState() =>
      _OrganizationAdminPasswordRouteState();
}

class _OrganizationAdminPasswordRouteState
    extends State<OrganizationAdminPasswordRoute> {
  CustomerOrganization? _organization;
  OrganizationAdminUser? _administrator;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final controller = context.read<PlatformOrganizationsController>()
      ..clearActionError();
    final selected = controller.selectedOrganization;
    final organization = selected?.id == widget.organizationId
        ? selected
        : await controller.loadOrganizationDetails(widget.organizationId);
    if (!mounted) return;
    setState(() {
      _organization = organization;
      _administrator = organization?.admins
          .where((admin) => admin.id == widget.administratorId)
          .firstOrNull;
      _loading = false;
    });
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        AppRoutes.platformOrganizationDetailsPath(widget.organizationId),
      );
    }
  }

  Future<String?> _submit(String newPassword) async {
    final controller = context.read<PlatformOrganizationsController>();
    final ok = await controller.resetAdministratorPassword(
      widget.organizationId,
      widget.administratorId,
      newPassword,
    );
    return ok
        ? null
        : controller.actionErrorMessage ?? 'The password could not be reset.';
  }

  void _saved() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password reset for ${_administrator?.name}.')),
    );
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final organization = _organization;
    final administrator = _administrator;
    if (organization == null || administrator == null) {
      return RecordNotFoundPage(
        backLabel: 'Organizations',
        currentLabel: 'Administrator',
        onBack: _leave,
        message: organization == null
            ? 'This organization could not be found.'
            : 'This administrator could not be found.',
        onRetry: _load,
      );
    }
    return OrganizationAdminPasswordPage(
      backLabel: organization.name,
      administrator: administrator,
      onSubmit: _submit,
      onClose: _leave,
      onSaved: _saved,
    );
  }
}
