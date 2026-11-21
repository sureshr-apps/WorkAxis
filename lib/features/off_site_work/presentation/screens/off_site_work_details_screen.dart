import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/responsive/responsive_sliver_page.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/off_site_work/domain/models/off_site_work_assignment.dart';
import 'package:workaxis/features/off_site_work/presentation/controllers/off_site_work_controller.dart';
import 'package:workaxis/features/off_site_work/presentation/widgets/off_site_work_event_card.dart';
import 'package:workaxis/features/off_site_work/presentation/widgets/off_site_work_delete_dialog.dart';
import 'package:workaxis/features/off_site_work/presentation/widgets/off_site_work_milestone_dialog.dart';
import 'package:workaxis/features/off_site_work/presentation/widgets/off_site_work_directions.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

class OffSiteWorkDetailsScreen extends StatefulWidget {
  const OffSiteWorkDetailsScreen({
    super.key,
    required this.assignmentId,
    required this.listRoute,
  });

  final String assignmentId;
  final String listRoute;

  @override
  State<OffSiteWorkDetailsScreen> createState() =>
      _OffSiteWorkDetailsScreenState();
}

class _OffSiteWorkDetailsScreenState extends State<OffSiteWorkDetailsScreen> {
  late final BranchContextController _branchController;
  OffSiteWorkAssignment? _assignment;
  String? _observedBranchId;
  String? _loadError;
  bool _loading = true;
  int _loadGeneration = 0;

  String? get _activeBranchId =>
      _branchController.activeBranch?.branchId ??
      context.read<AccessController>().accessContext?.activeBranch?.branchId;

  @override
  void initState() {
    super.initState();
    _branchController = context.read<BranchContextController>();
    _observedBranchId = _activeBranchId;
    _branchController.addListener(_onBranchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _branchController.removeListener(_onBranchChanged);
    super.dispose();
  }

  void _onBranchChanged() {
    final id = _activeBranchId;
    if (id == _observedBranchId) return;
    _observedBranchId = id;
    _loadGeneration++;
    setState(() {
      _assignment = null;
      _loadError = null;
      _loading = true;
    });
    _load();
  }

  Future<void> _load({bool force = false}) async {
    final generation = ++_loadGeneration;
    final accessController = context.read<AccessController>();
    if (force) await accessController.refreshAccess(force: true);
    if (!mounted || generation != _loadGeneration) return;
    final access = accessController.accessContext;
    if (access == null) {
      setState(() {
        _assignment = null;
        _loadError =
            'Your access could not be verified. Refresh and try again.';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final controller = context.read<OffSiteWorkController>()
      ..clearActionError();
    final assignment = await controller.getAssignment(
      access: access,
      assignmentId: widget.assignmentId,
      activeBranchId: access.user.role == UserRole.branchManager
          ? _activeBranchId
          : null,
    );
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _assignment = assignment;
      _loadError = assignment == null ? controller.actionErrorMessage : null;
      _loading = false;
    });
  }

  Future<bool> _record(
    UserRole role,
    OffSiteWorkMilestone milestone, {
    String? note,
    List<String> photoPaths = const [],
  }) async {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return false;
    final controller = context.read<OffSiteWorkController>()
      ..clearActionError();
    final saved = await controller.recordMilestone(
      access: access,
      activeBranchId: role == UserRole.branchManager ? _activeBranchId : null,
      assignmentId: widget.assignmentId,
      milestone: milestone,
      note: note,
      evidenceLocalPaths: photoPaths,
    );
    if (saved) await _load();
    return saved;
  }

  Future<void> _recordDirect(
    UserRole role,
    OffSiteWorkMilestone milestone,
  ) async {
    final saved = await _record(role, milestone);
    if (!mounted) return;
    if (saved) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_milestoneLabel(milestone))));
    } else {
      final message = context.read<OffSiteWorkController>().actionErrorMessage;
      if (message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _recordWithEvidence(
    UserRole role,
    OffSiteWorkMilestone milestone,
  ) async {
    final assignment = _assignment;
    if (assignment == null) return;
    final isFailure = milestone == OffSiteWorkMilestone.unableToComplete;
    final saved = await showOffSiteMilestoneDialog(
      context: context,
      milestone: milestone,
      title: isFailure ? 'Unable to complete' : 'Complete assignment',
      prompt: isFailure
          ? 'Tell your manager why this assignment could not be completed.'
          : 'Record the completion details and any requested evidence.',
      requiresReason: isFailure,
      requiredEvidenceDescription: assignment.requiredEvidenceDescription,
      onSubmit: (note, paths) =>
          _record(role, milestone, note: note, photoPaths: paths),
      failureMessage: () =>
          context.read<OffSiteWorkController>().actionErrorMessage,
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFailure ? 'Failure recorded.' : 'Assignment completed.',
        ),
      ),
    );
  }

  String _milestoneLabel(OffSiteWorkMilestone milestone) => switch (milestone) {
    OffSiteWorkMilestone.start => 'Assignment started.',
    OffSiteWorkMilestone.arrival => 'Arrival recorded.',
    OffSiteWorkMilestone.completion => 'Assignment completed.',
    OffSiteWorkMilestone.unableToComplete => 'Unable to complete recorded.',
    OffSiteWorkMilestone.returnToBranch => 'Return to branch recorded.',
  };

  Future<void> _openDirections(OffSiteWorkAssignment assignment) async {
    final opened = await launchOffSiteWorkDirections(
      destination: assignment.destination,
      latitude: assignment.destinationLatitude,
      longitude: assignment.destinationLongitude,
    );
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open directions. Try again.')),
    );
  }

  Future<void> _delete(OffSiteWorkAssignment assignment) async {
    if (!mounted) return;
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    final controller = context.read<OffSiteWorkController>()
      ..clearActionError();
    final deleted = await showOffSiteWorkDeleteDialog(
      context: context,
      onDelete: () => controller.deleteAssignment(
        access: access,
        activeBranchId: access.user.role == UserRole.branchManager
            ? _activeBranchId
            : null,
        assignmentId: assignment.id,
      ),
      failureMessage: () => controller.actionErrorMessage,
    );
    if (!mounted || deleted != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Off-site work deleted.')));
    context.go(widget.listRoute);
  }

  Widget _employeeActions(
    BuildContext context,
    UserRole role,
    OffSiteWorkAssignment assignment,
    bool isSaving,
  ) {
    final action = switch (assignment.status) {
      OffSiteWorkStatus.assigned => (
        'Start assignment',
        Icons.play_arrow,
        OffSiteWorkMilestone.start,
      ),
      OffSiteWorkStatus.inProgress => (
        'Record arrival',
        Icons.place_outlined,
        OffSiteWorkMilestone.arrival,
      ),
      OffSiteWorkStatus.completed || OffSiteWorkStatus.unableToComplete => (
        'Returned to branch',
        Icons.keyboard_return,
        OffSiteWorkMilestone.returnToBranch,
      ),
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (context.read<OffSiteWorkController>().actionErrorMessage !=
            null) ...[
          Text(
            context.read<OffSiteWorkController>().actionErrorMessage!,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (action != null)
          AppButton.primary(
            text: action.$1,
            iconData: action.$2,
            isLoading: isSaving,
            onPressed: isSaving ? null : () => _recordDirect(role, action.$3),
          ),
        if (assignment.status == OffSiteWorkStatus.arrived) ...[
          AppButton.primary(
            text: 'Complete assignment',
            iconData: Icons.task_alt,
            isLoading: isSaving,
            onPressed: isSaving
                ? null
                : () => _recordWithEvidence(
                    role,
                    OffSiteWorkMilestone.completion,
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.outlined(
            text: 'Unable to complete',
            iconData: Icons.error_outline,
            onPressed: isSaving
                ? null
                : () => _recordWithEvidence(
                    role,
                    OffSiteWorkMilestone.unableToComplete,
                  ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final access = context.watch<AccessController>().accessContext;
    final controller = context.watch<OffSiteWorkController>();
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final assignment = _assignment;
    if (assignment == null) {
      return Scaffold(
        body: SafeArea(
          child: ErrorState(
            message: _loadError ?? 'This assignment could not be loaded.',
            onRetry: () => _load(force: true),
          ),
        ),
      );
    }
    final role = access?.user.role;
    final canUpdate =
        (role == UserRole.employee || role == UserRole.branchManager) &&
        assignment.employeeUid == access?.user.id &&
        assignment.status != OffSiteWorkStatus.returned;
    final canDelete =
        (role == UserRole.orgAdmin || role == UserRole.branchManager) &&
        assignment.status == OffSiteWorkStatus.assigned;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveSliverPage(
          onRefresh: () => _load(force: true),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: PageBreadcrumb(
                  backLabel: 'Off-site Work',
                  currentLabel: assignment.title,
                  onBack: () => context.go(widget.listRoute),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AppPageHeader(
                eyebrow: 'Off-site Work',
                title: assignment.title,
                subtitle:
                    '${assignment.status.label} · ${assignment.branchName}',
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(
              child: DashboardSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailLine(
                      label: 'Selected location',
                      value: assignment.destination,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton.link(
                      text: 'Directions',
                      iconData: Icons.directions_outlined,
                      onPressed: () => _openDirections(assignment),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DetailLine(label: 'Branch', value: assignment.branchName),
                    _DetailLine(
                      label: 'Assigned to',
                      value: assignment.employeeName,
                    ),
                    _DetailLine(
                      label: 'Assigned by',
                      value: assignment.assignedByName,
                    ),
                    _DetailLine(
                      label: 'Assigned at',
                      value: AppFormatters.formatDateTime(assignment.createdAt),
                    ),
                    if (assignment.dueAt != null)
                      _DetailLine(
                        label: 'Due',
                        value: AppFormatters.formatDateTime(assignment.dueAt),
                      ),
                    if (assignment.reference?.isNotEmpty == true)
                      _DetailLine(
                        label: 'Reference',
                        value: assignment.reference!,
                      ),
                    if (assignment.instructions?.isNotEmpty == true)
                      _DetailLine(
                        label: 'Instructions',
                        value: assignment.instructions!,
                      ),
                    if (assignment.requiredEvidenceDescription?.isNotEmpty ==
                        true)
                      _DetailLine(
                        label: 'Requested evidence',
                        value: assignment.requiredEvidenceDescription!,
                      ),
                    if (assignment.latestLocation case final location?) ...[
                      const Divider(height: AppSpacing.xl),
                      Text(
                        'Latest recorded location',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)} · accuracy ${location.accuracyMeters.toStringAsFixed(0)} m',
                        style: AppTypography.bodyMedium,
                      ),
                      if (location.occurredAt != null)
                        Text(
                          AppFormatters.formatDateTime(location.occurredAt),
                          style: AppTypography.bodySmall,
                        ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    if (canUpdate)
                      _employeeActions(
                        context,
                        role!,
                        assignment,
                        controller.isSaving,
                      ),
                    if (canDelete) ...[
                      if (canUpdate) const SizedBox(height: AppSpacing.sm),
                      AppButton.destructive(
                        text: 'Delete assignment',
                        iconData: Icons.delete_outline,
                        isLoading: controller.isSaving,
                        onPressed: controller.isSaving
                            ? null
                            : () => _delete(assignment),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Location is recorded at milestones only. WorkAxis does not track your route, and these actions do not change attendance.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Event history',
                  style: AppTypography.headlineMedium,
                ),
              ),
            ),
            if (assignment.events.isEmpty)
              const SliverToBoxAdapter(
                child: Text('No milestone events recorded.'),
              )
            else
              SliverList.separated(
                itemCount: assignment.events.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) =>
                    OffSiteWorkEventCard(event: assignment.events[index]),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
