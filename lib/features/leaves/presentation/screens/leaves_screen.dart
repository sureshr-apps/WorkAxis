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
import 'package:workaxis/features/leaves/domain/models/leave_queue.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/presentation/controllers/leaves_controller.dart';
import 'package:workaxis/features/leaves/presentation/screens/widgets/leave_request_card.dart';
import 'package:workaxis/features/leaves/presentation/screens/widgets/leave_request_form_dialog.dart';
import 'package:workaxis/features/leaves/presentation/screens/widgets/leave_review_dialog.dart';
import 'package:workaxis/features/leaves/presentation/screens/widgets/leave_status_filters.dart';

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  late final BranchContextController _branchController;
  String? _observedBranchId;

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
    final controller = context.read<LeavesController>()..clearActionError();
    // A manual refresh also picks up leave types the organization changed.
    if (force) controller.invalidateLeaveTypes();
    await controller.loadLeaveRequests(
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
    final preview = controller.createPreviewController(access: access);
    final bool saved;
    try {
      saved = await showLeaveRequestFormDialog(
        context: context,
        branches: branches,
        initialBranchId: initialBranchId,
        branchLocked: manager,
        request: request,
        loadLeaveTypes: () => controller.loadLeaveTypes(access),
        preview: preview,
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
    } finally {
      preview.dispose();
    }
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
    final activeBranchId = access.user.role == UserRole.branchManager
        ? _currentBranchId
        : null;
    final preview = controller.createPreviewController(
      access: access,
      activeBranchId: activeBranchId,
    );
    final bool saved;
    try {
      saved = await showLeaveReviewDialog(
        context: context,
        request: request,
        decision: decision,
        preview: preview,
        onSubmit: (notes) async {
          controller.clearActionError();
          return controller.reviewLeaveRequest(
            access: access,
            activeBranchId: activeBranchId,
            request: request,
            decision: decision,
            reviewerNotes: notes,
          );
        },
        failureMessage: () => controller.actionErrorMessage,
      );
    } finally {
      preview.dispose();
    }
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

  void _setQueue(UserAccessContext access, LeaveQueue queue) {
    context.read<LeavesController>().setQueue(
      access: access,
      activeBranchId: _currentBranchId,
      queue: queue,
    );
  }

  void _setStatusFilter(UserAccessContext access, LeaveStatus? status) {
    context.read<LeavesController>().setStatusFilter(
      access: access,
      activeBranchId: _currentBranchId,
      status: status,
    );
  }

  void _loadMore(UserAccessContext access) {
    context.read<LeavesController>().loadMore(
      access: access,
      activeBranchId: _currentBranchId,
    );
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
    final items = controller.items;
    final ownQueue = controller.queue != LeaveQueue.branchEmployees;
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
                  child: SegmentedButton<LeaveQueue>(
                    segments: const [
                      ButtonSegment(
                        value: LeaveQueue.mine,
                        label: Text('My requests'),
                        icon: Icon(Icons.person_outline),
                      ),
                      ButtonSegment(
                        value: LeaveQueue.branchEmployees,
                        label: Text('Employee requests'),
                        icon: Icon(Icons.groups_outlined),
                      ),
                    ],
                    selected: {controller.queue ?? LeaveQueue.mine},
                    onSelectionChanged: (selection) =>
                        _setQueue(access, selection.first),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: LeaveStatusFilters(
                  selected: controller.statusFilter,
                  onSelected: (status) => _setStatusFilter(access, status),
                  counts: controller.counts,
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
                  title: _emptyTitle(controller.statusFilter, ownQueue),
                  subtitle: _emptySubtitle(ownQueue),
                  onApply: canApply
                      ? () {
                          _openForm(access);
                        }
                      : null,
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: controller.hasMore ? AppSpacing.md : AppSpacing.xxl,
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
            if (!controller.isLoading &&
                controller.errorMessage == null &&
                items.isNotEmpty &&
                controller.hasMore)
              SliverPadding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: AppButton.outlined(
                      text: 'Load more',
                      isFullWidth: false,
                      isLoading: controller.isLoadingMore,
                      onPressed: () => _loadMore(access),
                    ),
                  ),
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

  String _emptyTitle(LeaveStatus? statusFilter, bool ownQueue) {
    if (statusFilter != null) {
      return 'No ${statusFilter.label.toLowerCase()} requests';
    }
    return ownQueue ? 'No leave requests yet' : 'No employee requests';
  }

  String _emptySubtitle(bool ownQueue) => ownQueue
      ? 'Your leave applications will appear here.'
      : 'Employee leave applications for this branch will appear here.';
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
