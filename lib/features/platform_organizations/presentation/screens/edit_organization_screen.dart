import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/discard_changes_dialog.dart';

/// Screen allowing Platform Administrators to edit customer organization details.
class EditOrganizationScreen extends StatefulWidget {
  final String organizationId;

  const EditOrganizationScreen({super.key, required this.organizationId});

  @override
  State<EditOrganizationScreen> createState() => _EditOrganizationScreenState();
}

class _EditOrganizationScreenState extends State<EditOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _descController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactPhoneController;

  bool _isDirty = false;
  bool _isPopulating = false;
  String? _initializedOrgId;
  String? _nameError;
  String? _emailError;
  String? _submissionError;
  int _descLength = 0;
  int _nameLength = 0;

  CustomerOrganization? _getMatchingOrg(
    PlatformOrganizationsController controller,
  ) {
    if (controller.selectedOrganization?.id == widget.organizationId) {
      return controller.selectedOrganization;
    }
    return controller.organizations
        .where((o) => o.id == widget.organizationId)
        .firstOrNull;
  }

  void _populateControllers(
    CustomerOrganization org, {
    bool updateState = true,
  }) {
    _isPopulating = true;
    _nameController.text = org.name;
    _addressController.text = org.address ?? '';
    _descController.text = org.description ?? '';
    _contactNameController.text = org.contactName ?? '';
    _contactEmailController.text = org.contactEmail ?? '';
    _contactPhoneController.text = org.contactPhone ?? '';
    _nameLength = _nameController.text.length;
    _descLength = _descController.text.length;
    _isPopulating = false;
    _isDirty = false;
    _initializedOrgId = org.id;
    if (updateState && mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _descController = TextEditingController();
    _contactNameController = TextEditingController();
    _contactEmailController = TextEditingController();
    _contactPhoneController = TextEditingController();

    _nameController.addListener(_markDirty);
    _addressController.addListener(_markDirty);
    _descController.addListener(_markDirty);
    _contactNameController.addListener(_markDirty);
    _contactEmailController.addListener(_markDirty);
    _contactPhoneController.addListener(_markDirty);

    final controller = context.read<PlatformOrganizationsController>();
    final org = _getMatchingOrg(controller);

    if (org != null) {
      _populateControllers(org, updateState: false);
    }

    if (controller.selectedOrganization?.id != widget.organizationId) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final loaded = await context
            .read<PlatformOrganizationsController>()
            .loadOrganizationDetails(widget.organizationId);
        if (mounted && loaded != null && !_isDirty) {
          _populateControllers(loaded);
        }
      });
    }
  }

  @override
  void didUpdateWidget(EditOrganizationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      _isDirty = false;
      _submissionError = null;
      _nameError = null;
      _emailError = null;
      _initializedOrgId = null;

      final controller = context.read<PlatformOrganizationsController>();
      final org = _getMatchingOrg(controller);
      if (org != null) {
        _populateControllers(org, updateState: false);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final loaded = await context
            .read<PlatformOrganizationsController>()
            .loadOrganizationDetails(widget.organizationId);
        if (mounted && loaded != null && !_isDirty) {
          _populateControllers(loaded);
        }
      });
    }
  }

  void _markDirty() {
    if (_isPopulating) return;
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
    setState(() {
      _nameLength = _nameController.text.length;
      _descLength = _descController.text.length;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        _nameError = 'Organization name is required and cannot be empty.';
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

  Future<void> _handleSubmit(CustomerOrganization original) async {
    if (!_validateForm()) return;

    final controller = context.read<PlatformOrganizationsController>();

    final updated = original.copyWith(
      name: _nameController.text.trim(),
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

    final res = await controller.updateOrganization(updated);

    if (!mounted) return;

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${res.name} details updated successfully.'),
          backgroundColor: AppColors.statusActive,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.platformOrganizationDetailsPath(res.id));
      }
    } else {
      setState(() {
        _submissionError =
            controller.actionErrorMessage ??
            'Failed to update organization. Please check values.';
      });
    }
  }

  Future<void> _handleCancel(CustomerOrganization org) async {
    if (!_isDirty) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(
          AppRoutes.platformOrganizationDetailsPath(widget.organizationId),
        );
      }
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => DiscardChangesDialog(entityName: org.name),
    );

    if (discard == true && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(
          AppRoutes.platformOrganizationDetailsPath(widget.organizationId),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlatformOrganizationsController>();
    final isCompact = context.isCompact;
    final org = _getMatchingOrg(controller);

    if (org != null && _initializedOrgId != org.id && !_isDirty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDirty && _initializedOrgId != org.id) {
          _populateControllers(org);
        }
      });
    }

    if (controller.isLoading && org == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (org == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.business_outlined,
                    size: 48,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Organization Not Found',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.platformOrganizations);
                      }
                    },
                    child: const Text('Back to Organizations'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                    _buildBreadcrumb(context, org),
                    const SizedBox(height: AppSpacing.md),

                    // Header
                    _buildHeader(context, org),
                    const SizedBox(height: AppSpacing.lg),

                    // Submission Error Alert (if any)
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
                    _buildFooterToolbar(
                      context,
                      org,
                      controller.isActionLoading,
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

  Widget _buildBreadcrumb(BuildContext context, CustomerOrganization org) {
    return Row(
      children: [
        InkWell(
          onTap: () => _handleCancel(org),
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
          'Edit Organization',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, CustomerOrganization org) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: 4,
          children: [
            Text(
              'Edit Organization',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '# ${org.code}',
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            StatusChip.fromStatus(
              org.status.displayName,
              width: 96,
            ),
            if (_isDirty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.change_circle_outlined,
                      size: 13,
                      color: Color(0xFFE65100),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Unsaved Changes',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Update the details for this customer organization. Changes are logged to the platform audit registry.',
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
                  'Update Blocked: Form Validation Errors',
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
                // Organization Name with Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Organization Name *',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '$_nameLength / 100',
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                AppTextField(
                  controller: _nameController,
                  hintText: 'e.g. Acme Corporation',
                  errorText: _nameError,
                  maxLength: 100,
                  counterText: '',
                  onChanged: (val) {
                    if (_nameError != null && val.trim().isNotEmpty) {
                      setState(() => _nameError = null);
                    }
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

                // Organization Scope & Summary with Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        hintText: 'operations@acmecorp.com',
                        errorText: _emailError,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _contactPhoneController,
                        label: 'Contact Phone Number',
                        hintText: '+1 (555) 234-8900',
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
                        hintText: 'operations@acmecorp.com',
                        errorText: _emailError,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        controller: _contactPhoneController,
                        label: 'Contact Phone Number',
                        hintText: '+1 (555) 234-8900',
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

  Widget _buildFooterToolbar(
    BuildContext context,
    CustomerOrganization org,
    bool isLoading,
  ) {
    final isNarrow = MediaQuery.sizeOf(context).width < 650;
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
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : () => _handleCancel(org),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onSurface,
                          side: const BorderSide(
                            color: AppColors.outlineSubtle,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : () => _handleSubmit(org),
                        icon: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: const Text('Save Changes'),
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
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: AppColors.statusActive,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'End-to-end tenant database encryption enabled',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
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
                      onPressed: isLoading ? null : () => _handleCancel(org),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        side: const BorderSide(color: AppColors.outlineSubtle),
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
                      onPressed: isLoading ? null : () => _handleSubmit(org),
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: const Text('Save Changes'),
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
  }
}
