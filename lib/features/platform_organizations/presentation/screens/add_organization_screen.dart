import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';

/// Screen providing the form to register and provision a new customer organization tenant.
class AddOrganizationScreen extends StatefulWidget {
  const AddOrganizationScreen({super.key});

  @override
  State<AddOrganizationScreen> createState() => _AddOrganizationScreenState();
}

class _AddOrganizationScreenState extends State<AddOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _taxIdentificationController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _submissionError;
  int _descLength = 0;

  @override
  void initState() {
    super.initState();
    _descController.addListener(() {
      setState(() {
        _descLength = _descController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdentificationController.dispose();
    _addressController.dispose();
    _descController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _emailError = null;
      _submissionError = null;

      final name = _nameController.text.trim();
      if (name.isEmpty) {
        _nameError = 'Organization name is required to initialize workspace.';
        valid = false;
      }

      final email = _contactEmailController.text.trim();
      if (email.isNotEmpty) {
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
        if (!emailRegex.hasMatch(email)) {
          _emailError = 'Please enter a valid corporate email address.';
          valid = false;
        }
      }
    });

    return valid;
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;

    final controller = context.read<PlatformOrganizationsController>();

    final newOrganization = CreateOrganizationRequest(
      name: _nameController.text.trim(),
      taxIdentification: _taxIdentificationController.text.trim().isEmpty
          ? null
          : _taxIdentificationController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      contactName: _contactNameController.text.trim().isEmpty
          ? null
          : _contactNameController.text.trim(),
      contactEmail: _contactEmailController.text.trim().isEmpty
          ? null
          : _contactEmailController.text.trim(),
      contactPhone: _contactPhoneController.text.trim().isEmpty
          ? null
          : _contactPhoneController.text.trim(),
    );

    final created = await controller.createOrganization(newOrganization);

    if (!mounted) return;

    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${created.name} registered successfully.'),
          backgroundColor: AppColors.statusActive,
        ),
      );
      context.go(AppRoutes.platformOrganizationDetailsPath(created.id));
    } else {
      setState(() {
        _submissionError =
            controller.actionErrorMessage ??
            'Failed to register organization. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlatformOrganizationsController>();
    final isCompact = context.isCompact;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Breadcrumb
                    _buildBreadcrumb(context),
                    const SizedBox(height: AppSpacing.md),

                    // Header
                    _buildHeader(context),
                    const SizedBox(height: AppSpacing.lg),

                    // Submission Error Alert (if collision or server error)
                    if (_submissionError != null) ...[
                      _buildErrorBanner(_submissionError!),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Section 1: Organization Profile
                    _buildOrganizationProfileSection(),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 2: Operational Contact
                    _buildOperationalContactSection(),
                    const SizedBox(height: AppSpacing.xl),

                    // Persistent Action Toolbar
                    _buildFooterToolbar(context, controller.isActionLoading),
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

  Widget _buildBreadcrumb(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        InkWell(
          onTap: () => context.go(AppRoutes.platformOrganizations),
          borderRadius: BorderRadius.circular(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Organizations',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          '/',
          style: TextStyle(color: AppColors.outlineVariant, fontSize: 13),
        ),
        const SizedBox(width: 6),
        Text(
          'Add Organization',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              'Add Organization',
              style: GoogleFonts.inter(
                fontSize: context.isCompact ? 24 : 26,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'NEW TENANT',
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the details to register a new customer organization. Once provisioned, regional managers can attach operational hubs and staffing rosters.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusUrgentContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.statusUrgentBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.report_problem_outlined,
            color: AppColors.statusUrgent,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organization Registration Failed',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusUrgentText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.statusUrgentText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 18,
              color: AppColors.statusUrgentText,
            ),
            onPressed: () => setState(() => _submissionError = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationProfileSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineSubtle),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusMd),
                topRight: Radius.circular(AppSpacing.radiusMd),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.outlineSubtle),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.business_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Organization Profile',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'Core identification identifiers for platform-wide operations',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildOrganizationIdentifiers(
                      isCompact:
                          constraints.maxWidth < AppBreakpoints.mediumMin,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Headquarters Address
                AppTextField(
                  controller: _addressController,
                  label: 'Headquarters Address',
                  hintText: 'e.g. 742 Evergreen Logistics Blvd, Suite 400, Chicago, IL 60611',
                  helperText:
                      'Primary operational center or corporate headquarters.',
                ),
                const SizedBox(height: AppSpacing.md),

                // Organization Scope & Summary
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Text(
                      'Organization Scope & Summary (Optional)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '$_descLength / 300',
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                AppTextField(
                  controller: _descController,
                  hintText: 'Brief summary of company operational scope, regional coverage, or primary freight corridors...',
                  maxLines: 3,
                  maxLength: 300,
                  counterText: '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationIdentifiers({required bool isCompact}) {
    final nameField = AppTextField(
      controller: _nameController,
      label: 'Organization Name *',
      hintText: 'e.g. Apex Global Logistics',
      errorText: _nameError,
      maxLength: 100,
      counterText: '',
      onChanged: (value) {
        if (_nameError != null && value.trim().isNotEmpty) {
          setState(() => _nameError = null);
        }
      },
    );
    final taxIdentificationField = AppTextField(
      controller: _taxIdentificationController,
      label: 'Tax Identification (Optional)',
      hintText: 'e.g. EIN, GSTIN, or VAT number',
      helperText: 'Optional tax registration identifier (such as EIN, GSTIN, or VAT number) for invoicing and legal compliance.',
      maxLength: 100,
      counterText: '',
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          nameField,
          const SizedBox(height: AppSpacing.md),
          taxIdentificationField,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: nameField),
        const SizedBox(width: AppSpacing.md),
        Expanded(flex: 2, child: taxIdentificationField),
      ],
    );
  }

  Widget _buildOperationalContactSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineSubtle),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusMd),
                topRight: Radius.circular(AppSpacing.radiusMd),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.outlineSubtle),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.contact_mail_outlined,
                    size: 20,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. Operational Contact',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'Designated point of contact for platform notices and dispatch coordination',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                if (isNarrow) {
                  return Column(
                    children: [
                      AppTextField(
                        controller: _contactNameController,
                        label: 'Contact Person Name',
                        hintText: 'e.g. Marcus Sterling',
                        helperText: 'Regional Director or Ops Lead',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _contactEmailController,
                        label: 'Contact Email',
                        hintText: 'operations@apexlogistics.com',
                        errorText: _emailError,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _contactPhoneController,
                        label: 'Contact Phone Number',
                        hintText: '+1 (555) 019-2834',
                        helperText: 'Include country and area code',
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _contactNameController,
                        label: 'Contact Person Name',
                        hintText: 'e.g. Marcus Sterling',
                        helperText: 'Regional Director or Ops Lead',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        controller: _contactEmailController,
                        label: 'Contact Email',
                        hintText: 'operations@apexlogistics.com',
                        errorText: _emailError,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        controller: _contactPhoneController,
                        label: 'Contact Phone Number',
                        hintText: '+1 (555) 019-2834',
                        helperText: 'Include country and area code',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterToolbar(BuildContext context, bool isLoading) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.outlineSubtle),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: AppColors.statusActive,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'End-to-end tenant database encryption enabled',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(AppRoutes.platformOrganizations);
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        side: const BorderSide(color: AppColors.outlineSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _handleSubmit,
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Create Organization'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: AppColors.statusActive,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'End-to-end tenant database encryption enabled',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.secondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(AppRoutes.platformOrganizations);
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.onSurface,
                            side: const BorderSide(
                              color: AppColors.outlineSubtle,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _handleSubmit,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Create Organization'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}
