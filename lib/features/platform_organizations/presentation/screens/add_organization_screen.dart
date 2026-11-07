import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_contact_fields.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_form_breadcrumb.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_form_error_banner.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_form_footer.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_form_state.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_profile_fields.dart';

/// Form to register and provision a new customer organization tenant.
class AddOrganizationScreen extends StatefulWidget {
  const AddOrganizationScreen({super.key});

  @override
  State<AddOrganizationScreen> createState() => _AddOrganizationScreenState();
}

class _AddOrganizationScreenState extends State<AddOrganizationScreen> {
  final OrganizationFormState _form = OrganizationFormState();

  OrganizationFormErrors _errors = const OrganizationFormErrors();
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    // A previous form's failure must not greet a freshly opened form.
    final controller = context.read<PlatformOrganizationsController>();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.clearActionError(),
    );
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.platformOrganizations);
    }
  }

  Future<void> _handleSubmit() async {
    final errors = _form.validate(
      missingNameMessage:
          'Organization name is required to initialize workspace.',
    );
    setState(() {
      _errors = errors;
      _submissionError = null;
    });
    if (errors.hasErrors) return;

    final controller = context.read<PlatformOrganizationsController>();
    final created = await controller.createOrganization(
      _form.toCreateRequest(),
    );
    if (!mounted) return;

    if (created == null) {
      setState(() {
        _submissionError =
            controller.actionErrorMessage ??
            'The organization could not be registered. Please try again.';
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${created.name} registered successfully.'),
        backgroundColor: AppColors.statusActive,
      ),
    );
    context.go(AppRoutes.platformOrganizationDetailsPath(created.id));
  }

  @override
  Widget build(BuildContext context) {
    final isActionLoading = context
        .select<PlatformOrganizationsController, bool>(
          (c) => c.isActionLoading,
        );

    return Scaffold(
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
                    currentLabel: 'Add Organization',
                    onBack: _goBack,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const AppPageHeader(
                    eyebrow: 'New tenant',
                    title: 'Add Organization',
                    subtitle:
                        'Enter the details to register a new customer '
                        'organization. Once provisioned, regional managers can '
                        'attach operational hubs and staffing rosters.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_submissionError != null) ...[
                    OrganizationFormErrorBanner(
                      title: 'Organization Registration Failed',
                      message: _submissionError!,
                      onDismiss: () => setState(() => _submissionError = null),
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
                    submitLabel: 'Create Organization',
                    submitIcon: Icons.add_circle_outline,
                    isLoading: isActionLoading,
                    onCancel: _goBack,
                    onSubmit: _handleSubmit,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
