import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/core/widgets/record_not_found_page.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_draft.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_admin_form_page.dart';

/// Routed entry for adding an administrator ([administratorId] null) or
/// editing one. Loads the organization and the administrator being edited,
/// saves through [PlatformOrganizationsController], then returns to the
/// organization.
class OrganizationAdminFormRoute extends StatefulWidget {
  const OrganizationAdminFormRoute({
    super.key,
    required this.organizationId,
    this.administratorId,
  });

  final String organizationId;
  final String? administratorId;

  @override
  State<OrganizationAdminFormRoute> createState() =>
      _OrganizationAdminFormRouteState();
}

class _OrganizationAdminFormRouteState
    extends State<OrganizationAdminFormRoute> {
  CustomerOrganization? _organization;
  OrganizationAdminUser? _administrator;
  bool _loading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _notFound = false;
    });
    final controller = context.read<PlatformOrganizationsController>()
      ..clearActionError();
    final selected = controller.selectedOrganization;
    final organization = selected?.id == widget.organizationId
        ? selected
        : await controller.loadOrganizationDetails(widget.organizationId);
    if (!mounted) return;
    final administratorId = widget.administratorId;
    final administrator = administratorId == null
        ? null
        : organization?.admins
              .where((admin) => admin.id == administratorId)
              .firstOrNull;
    setState(() {
      _organization = organization;
      _administrator = administrator;
      _notFound =
          organization == null ||
          (administratorId != null && administrator == null);
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

  Future<String?> _submit(OrganizationAdminDraft draft) async {
    final controller = context.read<PlatformOrganizationsController>();
    final administrator = _administrator;
    final organizationId = widget.organizationId;
    if (administrator == null) {
      final ok = await controller.createAdministrator(organizationId, draft);
      return ok
          ? null
          : controller.actionErrorMessage ??
                'The administrator could not be added.';
    }
    final ok = await controller.updateAdministrator(
      organizationId,
      administrator.copyWith(
        name: draft.name,
        email: draft.email,
        phone: draft.phone,
      ),
    );
    return ok
        ? null
        : controller.actionErrorMessage ??
              'The administrator could not be updated.';
  }

  void _saved() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _administrator == null
              ? 'Administrator added.'
              : 'Administrator details updated.',
        ),
      ),
    );
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final organization = _organization;
    if (_notFound || organization == null) {
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
    return OrganizationAdminFormPage(
      backLabel: organization.name,
      existingAdministrator: _administrator,
      onSubmit: _submit,
      onClose: _leave,
      onSaved: _saved,
    );
  }
}
