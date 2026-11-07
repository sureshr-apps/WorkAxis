import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/discard_changes_dialog.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/edit_organization_header.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_contact_fields.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_form_breadcrumb.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_form_error_banner.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_form_footer.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_form_state.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_profile_fields.dart';

/// Screen allowing Platform Administrators to edit organization details.
///
/// Leaving with unsaved changes (cancel, breadcrumb, system back or browser
/// back) asks for confirmation through a [PopScope] guard.
class EditOrganizationScreen extends StatefulWidget {
  const EditOrganizationScreen({super.key, required this.organizationId});

  final String organizationId;

  @override
  State<EditOrganizationScreen> createState() => _EditOrganizationScreenState();
}

class _EditOrganizationScreenState extends State<EditOrganizationScreen> {
  final OrganizationFormState _form = OrganizationFormState();

  bool _isDirty = false;
  bool _isPopulating = false;
  String? _populatedOrgId;
  bool _awaitingLoad = false;
  OrganizationFormErrors _errors = const OrganizationFormErrors();
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _form.addListener(_markDirty);
    final controller = context.read<PlatformOrganizationsController>();
    _populateIfReady(controller);
    _awaitingLoad = _populatedOrgId == null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.clearActionError();
      if (_populatedOrgId != widget.organizationId) _load(controller);
    });
  }

  @override
  void didUpdateWidget(EditOrganizationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      _isDirty = false;
      _populatedOrgId = null;
      _submissionError = null;
      _errors = const OrganizationFormErrors();
      final controller = context.read<PlatformOrganizationsController>();
      _populateIfReady(controller);
      _awaitingLoad = _populatedOrgId == null;
      if (_awaitingLoad) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _load(controller);
        });
      }
    }
  }

  @override
  void dispose() {
    _form.removeListener(_markDirty);
    _form.dispose();
    super.dispose();
  }

  /// Only the full detail record is used to fill the form: list rows omit
  /// fields such as the tax id and would clear them on save.
  CustomerOrganization? _detailFor(PlatformOrganizationsController controller) {
    final selected = controller.selectedOrganization;
    return selected?.id == widget.organizationId ? selected : null;
  }

  void _populateIfReady(PlatformOrganizationsController controller) {
    final org = _detailFor(controller);
    if (org == null || _populatedOrgId == org.id) return;
    _isPopulating = true;
    _form.populate(org);
    _isPopulating = false;
    _populatedOrgId = org.id;
    _isDirty = false;
  }

  Future<void> _load(PlatformOrganizationsController controller) async {
    if (!_awaitingLoad) setState(() => _awaitingLoad = true);
    final loaded = await controller.loadOrganizationDetails(
      widget.organizationId,
    );
    if (!mounted) return;
    setState(() {
      _awaitingLoad = false;
      if (loaded != null && !_isDirty) _populateIfReady(controller);
    });
  }

  void _markDirty() {
    if (_isPopulating || _isDirty) return;
    setState(() => _isDirty = true);
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

  Future<bool> _confirmDiscard(CustomerOrganization org) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => DiscardChangesDialog(entityName: org.name),
    );
    return discard == true;
  }

  Future<void> _handleCancel(CustomerOrganization org) async {
    if (_isDirty && !await _confirmDiscard(org)) return;
    if (!mounted) return;
    setState(() => _isDirty = false);
    // Let the PopScope observe the cleared flag before popping.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _leave();
    });
  }

  Future<void> _handleSubmit(CustomerOrganization original) async {
    final errors = _form.validate(
      missingNameMessage: 'Organization name is required and cannot be empty.',
    );
    setState(() {
      _errors = errors;
      _submissionError = null;
    });
    if (errors.hasErrors) return;

    if (!_isDirty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No changes to save.')));
      _leave();
      return;
    }

    final controller = context.read<PlatformOrganizationsController>();
    final saved = await controller.updateOrganization(_form.applyTo(original));
    if (!mounted) return;

    if (saved == null) {
      setState(() {
        _submissionError =
            controller.actionErrorMessage ??
            'The organization could not be updated. Please try again.';
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${saved.name} details updated successfully.'),
        backgroundColor: AppColors.statusActive,
      ),
    );
    setState(() => _isDirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _leave();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlatformOrganizationsController>();
    final org = _detailFor(controller);

    if (org == null) {
      return _buildPlaceholder(controller);
    }

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard(org) && mounted) {
          setState(() => _isDirty = false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _leave();
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              context.isCompact ? AppSpacing.md : AppSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OrganizationFormBreadcrumb(
                      currentLabel: 'Edit Organization',
                      onBack: () => _handleCancel(org),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EditOrganizationHeader(
                      organization: org,
                      isDirty: _isDirty,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_submissionError != null) ...[
                      OrganizationFormErrorBanner(
                        title: 'Update Failed',
                        message: _submissionError!,
                        onDismiss: () =>
                            setState(() => _submissionError = null),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    OrganizationProfileFields(
                      form: _form,
                      nameError: _errors.name,
                      onNameChanged: (value) {
                        if (_errors.name != null && value.trim().isNotEmpty) {
                          setState(
                            () => _errors = OrganizationFormErrors(
                              email: _errors.email,
                              phone: _errors.phone,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OrganizationContactFields(
                      form: _form,
                      emailError: _errors.email,
                      phoneError: _errors.phone,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    OrganizationFormFooter(
                      submitLabel: 'Save Changes',
                      submitIcon: Icons.check,
                      isLoading: controller.isActionLoading,
                      onCancel: () => _handleCancel(org),
                      onSubmit: () => _handleSubmit(org),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(PlatformOrganizationsController controller) {
    final Widget body;
    if (_awaitingLoad || controller.isDetailLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (controller.detailErrorMessage != null) {
      body = ErrorState(
        message: controller.detailErrorMessage!,
        onRetry: () => _load(controller),
      );
    } else {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.business_outlined,
              size: 48,
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Organization Not Found'),
            const SizedBox(height: AppSpacing.md),
            AppButton.outlined(
              text: 'Back to Organizations',
              isFullWidth: false,
              onPressed: () => context.go(AppRoutes.platformOrganizations),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: body,
        ),
      ),
    );
  }
}
