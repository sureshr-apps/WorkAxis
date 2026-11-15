import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/core/widgets/form_action_row.dart';
import 'package:workaxis/features/plans/domain/license_plan_policy.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_draft.dart';
import 'package:workaxis/features/plans/presentation/controllers/license_plans_controller.dart';
import 'package:workaxis/features/plans/presentation/widgets/license_plan_level_stepper.dart';

/// Add or edit a license plan. [planId] null means add.
class LicensePlanFormScreen extends StatefulWidget {
  const LicensePlanFormScreen({super.key, this.planId});

  final String? planId;

  @override
  State<LicensePlanFormScreen> createState() => _LicensePlanFormScreenState();
}

class _LicensePlanFormScreenState extends State<LicensePlanFormScreen> {
  @override
  void initState() {
    super.initState();
    final controller = context.read<LicensePlansController>();
    // A failure from an earlier action must not greet a freshly opened form.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.clearActionError();
      // Edit opened directly (deep link): the plan may not be loaded yet.
      if (widget.planId != null &&
          controller.findPlan(widget.planId!) == null) {
        controller.loadPlans();
      }
    });
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.platformPlans);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LicensePlansController>();
    final planId = widget.planId;
    final isEditing = planId != null;
    final suggestedLevel = controller.availableLevels.isEmpty
        ? 1
        : controller.availableLevels.last + 1;

    final Widget body;
    if (!isEditing) {
      body = _LicensePlanForm(
        key: const ValueKey('new-license-plan'),
        suggestedLevel: suggestedLevel,
        onCancel: _goBack,
      );
    } else {
      final plan = controller.findPlan(planId);
      if (plan != null) {
        body = _LicensePlanForm(
          key: ValueKey('license-plan-${plan.id}'),
          plan: plan,
          suggestedLevel: suggestedLevel,
          onCancel: _goBack,
        );
      } else if (controller.isListLoading) {
        body = const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        );
      } else {
        body = ErrorState(
          message:
              controller.listErrorMessage ??
              'This plan could not be found. It may have been deleted.',
          onRetry: controller.loadPlans,
        );
      }
    }

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
                maxWidth: AppBreakpoints.maxFormCardWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppPageHeader(
                    eyebrow: 'Platform Licensing',
                    title: isEditing ? 'Edit Plan' : 'Add Plan',
                    subtitle: isEditing
                        ? 'Change the name, level, description or limits. '
                              'Status is changed from the plan list.'
                        : 'Define a plan organizations can be licensed on. '
                              'New plans start active.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  body,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The editable form. Its state is created once per plan so the fields are
/// seeded from [plan] and keep the user's edits while the screen is open.
class _LicensePlanForm extends StatefulWidget {
  const _LicensePlanForm({
    super.key,
    this.plan,
    required this.suggestedLevel,
    required this.onCancel,
  });

  final LicensePlan? plan;
  final int suggestedLevel;
  final VoidCallback onCancel;

  @override
  State<_LicensePlanForm> createState() => _LicensePlanFormState();
}

class _LicensePlanFormState extends State<_LicensePlanForm> {
  static const String _defaultMaxStores = '5';
  static const String _defaultMaxUsers = '25';

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _maxStores;
  late final TextEditingController _maxUsers;
  late int _level;

  Map<LicensePlanField, String> _errors = const {};
  String? _submissionError;

  bool get _isEditing => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _name = TextEditingController(text: plan?.name ?? '');
    _description = TextEditingController(text: plan?.description ?? '');
    _maxStores = TextEditingController(
      text: plan?.maxStores.toString() ?? _defaultMaxStores,
    );
    _maxUsers = TextEditingController(
      text: plan?.maxUsers.toString() ?? _defaultMaxUsers,
    );
    _level = plan?.level ?? widget.suggestedLevel;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _maxStores.dispose();
    _maxUsers.dispose();
    super.dispose();
  }

  /// Text that is not a whole number reads as 0, which the policy rejects with
  /// the same message as any other non-positive value.
  static int _parseWhole(String text) => int.tryParse(text.trim()) ?? 0;

  /// Clears one field's error as soon as the user edits it.
  void _clearError(LicensePlanField field) {
    if (!_errors.containsKey(field)) return;
    setState(() => _errors = {..._errors}..remove(field));
  }

  LicensePlanDraftFields _readDraft() => _FormValues(
    name: _name.text.trim(),
    description: _description.text.trim(),
    level: _level,
    maxStores: _parseWhole(_maxStores.text),
    maxUsers: _parseWhole(_maxUsers.text),
  );

  Future<void> _submit() async {
    final controller = context.read<LicensePlansController>();
    final draft = _readDraft();
    final errors = LicensePlanPolicy.validate(draft);
    setState(() {
      _errors = errors;
      _submissionError = null;
    });
    if (errors.isNotEmpty) return;

    final plan = widget.plan;
    final String savedName;
    if (plan == null) {
      final created = await controller.createPlan(
        CreateLicensePlanDraft(
          name: draft.name,
          description: draft.description,
          level: draft.level,
          maxStores: draft.maxStores,
          maxUsers: draft.maxUsers,
        ),
      );
      if (!mounted) return;
      if (created == null) {
        _showSubmissionError(controller, 'The plan could not be created.');
        return;
      }
      savedName = created.name;
    } else {
      final saved = await controller.updatePlan(
        plan.id,
        UpdateLicensePlanDraft(
          name: draft.name,
          description: draft.description,
          level: draft.level,
          maxStores: draft.maxStores,
          maxUsers: draft.maxUsers,
        ),
      );
      if (!mounted) return;
      if (!saved) {
        _showSubmissionError(controller, 'The plan could not be saved.');
        return;
      }
      savedName = draft.name;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Plan "$savedName" updated successfully.'
              : 'Plan "$savedName" created and added to the catalogue.',
        ),
        backgroundColor: AppColors.statusActive,
      ),
    );
    context.go(AppRoutes.platformPlans);
  }

  void _showSubmissionError(
    LicensePlansController controller,
    String fallback,
  ) {
    setState(() {
      _submissionError = controller.actionErrorMessage ?? fallback;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<LicensePlansController, bool>(
      (c) => c.isActionLoading,
    );
    final fields = _buildFields(isBusy);

    return Container(
      padding: EdgeInsets.all(
        context.isCompact ? AppSpacing.md : AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_submissionError != null) ...[
            ErrorBanner(
              message: _submissionError!,
              onDismiss: () => setState(() => _submissionError = null),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          ...fields,
          const SizedBox(height: AppSpacing.xl),
          FormActionRow(
            submitLabel: _isEditing ? 'Save Changes' : 'Create Plan',
            submitIcon: _isEditing ? Icons.check : Icons.add_circle_outline,
            onCancel: widget.onCancel,
            onSubmit: isBusy ? null : _submit,
            isBusy: isBusy,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFields(bool isBusy) {
    return [
      AppTextField(
        controller: _name,
        label: 'Plan Name *',
        hintText: 'e.g., Professional',
        errorText: _errors[LicensePlanField.name],
        enabled: !isBusy,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        onChanged: (_) => _clearError(LicensePlanField.name),
      ),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(
        controller: _description,
        label: 'Description',
        hintText: 'Who this plan is for and the capacity it gives.',
        helperText:
            'Optional. Up to ${LicensePlanPolicy.maxDescriptionLength} characters.',
        errorText: _errors[LicensePlanField.description],
        enabled: !isBusy,
        minLines: 2,
        maxLines: 3,
        textInputAction: TextInputAction.newline,
        onChanged: (_) => _clearError(LicensePlanField.description),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text('Plan Level *', style: AppTypography.labelLarge),
      const SizedBox(height: AppSpacing.xs),
      LicensePlanLevelStepper(
        value: _level,
        enabled: !isBusy,
        errorText: _errors[LicensePlanField.level],
        onChanged: (next) {
          setState(() => _level = next);
          _clearError(LicensePlanField.level);
        },
      ),
      const SizedBox(height: AppSpacing.lg),
      LayoutBuilder(
        builder: (context, constraints) {
          final stores = _wholeNumberField(
            controller: _maxStores,
            label: 'Maximum Stores *',
            field: LicensePlanField.maxStores,
            isBusy: isBusy,
          );
          final users = _wholeNumberField(
            controller: _maxUsers,
            label: 'Maximum Users *',
            field: LicensePlanField.maxUsers,
            isBusy: isBusy,
          );
          if (constraints.maxWidth < AppBreakpoints.mediumMin) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                stores,
                const SizedBox(height: AppSpacing.lg),
                users,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: stores),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: users),
            ],
          );
        },
      ),
    ];
  }

  Widget _wholeNumberField({
    required TextEditingController controller,
    required String label,
    required LicensePlanField field,
    required bool isBusy,
  }) {
    return AppTextField(
      controller: controller,
      label: label,
      hintText: 'Whole number, 1 or more',
      errorText: _errors[field],
      enabled: !isBusy,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => _clearError(field),
    );
  }
}

/// Read-only snapshot of the form, used to validate before submitting.
class _FormValues implements LicensePlanDraftFields {
  const _FormValues({
    required this.name,
    required this.description,
    required this.level,
    required this.maxStores,
    required this.maxUsers,
  });

  @override
  final String name;
  @override
  final String description;
  @override
  final int level;
  @override
  final int maxStores;
  @override
  final int maxUsers;
}
