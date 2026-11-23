import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/core/responsive/responsive_sliver_page.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/presentation/controllers/leaves_controller.dart';
import 'package:workaxis/features/leaves/presentation/screens/widgets/leave_request_card.dart';
import 'package:workaxis/features/leaves/presentation/screens/widgets/leave_request_form_dialog.dart';
import 'package:workaxis/features/leaves/presentation/screens/widgets/leave_review_dialog.dart';

enum _LeaveQueue { mine, team }

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  late final BranchContextController _branchController;
  String? _observedBranchId;
  LeaveStatus? _statusFilter;
  _LeaveQueue _queue = _LeaveQueue.mine;

  @override
  void initState() {
    super.initState();
    _branchController = context.read<BranchContextController>();
    _observedBranchId = _currentBranchId;
    _branchController.addListener(_onBranchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _branchController.removeListener(_onBranchChanged);
    super.dispose();
  }

  String? get _currentBranchId =>
      _branchController.activeBranch?.branchId ??
      context.read<AccessController>().accessContext?.activeBranch?.branchId;

  void _onBranchChanged() {
    final branchId = _currentBranchId;
    if (branchId == _observedBranchId) return;
    _observedBranchId = branchId;
    _load();
  }

  Future<void> _load({bool force = false}) async {
    final accessController = context.read<AccessController>();
    await accessController.refreshAccess(force: force);
    if (!mounted) return;
    final access = accessController.accessContext;
    if (access == null) return;
    context.read<LeavesController>().clearActionError();
    await context.read<LeavesController>().loadLeaveRequests(
      access: access,
      activeBranchId: _currentBranchId,
    );
  }

  Future<void> _openForm(
    UserAccessContext access, {
    LeaveRequest? request,
  }) async {
    final role = access.user.role;
    final manager = role == UserRole.branchManager;
    final branches = manager
        ? access.activeAssignedBranches
              .where((branch) => branch.id == _currentBranchId)
              .toList(growable: false)
        : access.activeAssignedBranches;
    final initialBranchId =
        request?.branchId ??
        (manager
            ? _currentBranchId
            : access.activeAssignedBranches.firstOrNull?.id ??
                  access.activeBranch?.branchId);
    final controller = context.read<LeavesController>()..clearActionError();
    final saved = await showLeaveRequestFormDialog(
      context: context,
      branches: branches,
      initialBranchId: initialBranchId,
      branchLocked: manager,
      request: request,
      onSubmit: (result) async {
        controller.clearActionError();
        return request == null
            ? controller.submitLeaveRequest(
                access: access,
                branchId: result.branchId,
                activeBranchId: manager ? _currentBranchId : null,
                draft: result.draft,
              )
            : controller.updatePendingLeaveRequest(
                access: access,
                activeBranchId: manager ? _currentBranchId : null,
                request: request,
                draft: result.draft,
              );
      },
      failureMessage: () => controller.actionErrorMessage,
    );
    if (!mounted || !saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          request == null
              ? 'Leave request submitted for review.'
              : 'Pending leave request updated.',
        ),
      ),
    );
  }

  Future<void> _review(
    UserAccessContext access,
    LeaveRequest request,
    LeaveStatus decision,
  ) async {
    final controller = context.read<LeavesController>()..clearActionError();
    final saved = await showLeaveReviewDialog(
      context: context,
      request: request,
      decision: decision,
      onSubmit: (notes) async {
        controller.clearActionError();
        return controller.reviewLeaveRequest(
          access: access,
          activeBranchId: access.user.role == UserRole.branchManager
              ? _currentBranchId
              : null,
          request: request,
          decision: decision,
          reviewerNotes: notes,
        );
      },
      failureMessage: () => controller.actionErrorMessage,
    );
    if (!mounted || !saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          decision == LeaveStatus.approved
              ? 'Leave request approved.'
              : 'Leave request rejected.',
        ),
      ),
    );
  }

  List<LeaveRequest> _queueRequests(
    LeavesController controller,
    UserAccessContext access,
  ) {
    Iterable<LeaveRequest> requests = controller.items;
    if (access.user.role == UserRole.employee) {
      requests = requests.where((item) => item.applicantUid == access.user.id);
    } else if (access.user.role == UserRole.branchManager) {
      requests = _queue == _LeaveQueue.mine
          ? requests.where((item) => item.applicantUid == access.user.id)
          : requests.where(
              (item) =>
                  item.applicantRole == UserRole.employee &&
                  item.branchId == _currentBranchId,
            );
    }
    return requests.toList(growable: false);
  }

  List<LeaveRequest> _visibleRequests(List<LeaveRequest> queueRequests) {
    Iterable<LeaveRequest> requests = queueRequests;
    if (_statusFilter != null) {
      requests = requests.where((item) => item.status == _statusFilter);
    }
    return requests.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LeavesController>();
    final access = context.watch<AccessController>().accessContext;
    if (access == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final role = access.user.role;
    final isEmployee = role == UserRole.employee;
    final isManager = role == UserRole.branchManager;
    final canApply = isEmployee || isManager;
    final queueRequests = _queueRequests(controller, access);
    final items = _visibleRequests(queueRequests);
    final activeBranchName = _branchController.activeBranch?.branchName;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ResponsiveSliverPage(
          onRefresh: () => _load(force: true),
          slivers: [
            SliverToBoxAdapter(
              child: AppPageHeader(
                eyebrow: isEmployee
                    ? 'Self Service'
                    : isManager
                    ? 'Branch Operations'
                    : 'Workforce Management',
                title: isEmployee ? 'My Leave' : 'Leaves',
                subtitle: isEmployee
                    ? 'Apply for leave and follow each request through review.'
                    : isManager
                    ? 'Review employee leave for ${activeBranchName ?? 'the active branch'} and track your own applications.'
                    : 'Review and track leave requests across your organization.',
                action: canApply
                    ? AppButton.responsive(
                        text: 'Apply for leave',
                        iconData: Icons.add,
                        onPressed: controller.isSaving
                            ? null
                            : () {
                                _openForm(access);
                              },
                      )
                    : null,
              ),
            ),
            if (isManager)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: SegmentedButton<_LeaveQueue>(
                    segments: const [
                      ButtonSegment(
                        value: _LeaveQueue.mine,
                        label: Text('My requests'),
                        icon: Icon(Icons.person_outline),
                      ),
                      ButtonSegment(
                        value: _LeaveQueue.team,
                        label: Text('Employee requests'),
                        icon: Icon(Icons.groups_outlined),
                      ),
                    ],
                    selected: {_queue},
                    onSelectionChanged: (selection) =>
                        setState(() => _queue = selection.first),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: _StatusFilters(
                  selected: _statusFilter,
                  onSelected: (status) =>
                      setState(() => _statusFilter = status),
                  requests: queueRequests,
                ),
              ),
            ),
            if (controller.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (controller.errorMessage != null)
              SliverToBoxAdapter(
                child: ErrorState(
                  message: controller.errorMessage!,
                  onRetry: () => _load(force: true),
                ),
              )
            else if (items.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyLeavesState(
                  title: _emptyTitle(isEmployee, isManager),
                  subtitle: _emptySubtitle(isEmployee, isManager),
                  onApply: canApply
                      ? () {
                          _openForm(access);
                        }
                      : null,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.xxl,
                ),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final request = items[index];
                    final ownPending =
                        request.applicantUid == access.user.id &&
                        request.status == LeaveStatus.pending;
                    final canReview =
                        request.status == LeaveStatus.pending &&
                        (role == UserRole.orgAdmin ||
                            (isManager &&
                                request.applicantRole == UserRole.employee));
                    return LeaveRequestCard(
                      request: request,
                      showApplicant: !isEmployee,
                      isSaving: controller.isSaving,
                      onEdit:
                          ownPending &&
                              (!isManager ||
                                  request.branchId == _currentBranchId)
                          ? () {
                              _openForm(access, request: request);
                            }
                          : null,
                      showBranch:
                          role == UserRole.orgAdmin ||
                          (isManager && request.applicantUid == access.user.id),
                      onReview: canReview
                          ? (decision) {
                              _review(access, request, decision);
                            }
                          : null,
                    );
                  },
                ),
              ),
            if (controller.actionErrorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    controller.actionErrorMessage!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.statusUrgent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _emptyTitle(bool isEmployee, bool isManager) {
    if (_statusFilter != null) {
      return 'No ${_statusFilter!.label.toLowerCase()} requests';
    }
    if (isEmployee || (isManager && _queue == _LeaveQueue.mine)) {
      return 'No leave requests yet';
    }
    return 'No employee requests';
  }

  String _emptySubtitle(bool isEmployee, bool isManager) {
    if (isEmployee || (isManager && _queue == _LeaveQueue.mine)) {
      return 'Your leave applications will appear here.';
    }
    return 'Employee leave applications for this branch will appear here.';
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({
    required this.selected,
    required this.onSelected,
    required this.requests,
  });

  final LeaveStatus? selected;
  final ValueChanged<LeaveStatus?> onSelected;
  final List<LeaveRequest> requests;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.xs,
    children: [
      FilterChip(
        label: Text('All (${requests.length})'),
        selected: selected == null,
        onSelected: (_) => onSelected(null),
      ),
      for (final status in LeaveStatus.values)
        FilterChip(
          label: Text(
            '${status.label} (${requests.where((request) => request.status == status).length})',
          ),
          selected: selected == status,
          onSelected: (_) => onSelected(status),
        ),
    ],
  );
}

class _EmptyLeavesState extends StatelessWidget {
  const _EmptyLeavesState({
    required this.title,
    required this.subtitle,
    required this.onApply,
  });

  final String title;
  final String subtitle;
  final FutureOr<void> Function()? onApply;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 40,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (onApply != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton.secondary(
                text: 'Apply for leave',
                iconData: Icons.add,
                onPressed: onApply,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
