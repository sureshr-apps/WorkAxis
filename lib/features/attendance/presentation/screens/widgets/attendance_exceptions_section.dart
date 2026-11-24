import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/checkout_correction.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_exceptions_repository.dart';
import 'package:workaxis/features/attendance/presentation/controllers/attendance_exceptions_controller.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/correction_review_tile.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/exception_review_dialogs.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/exception_review_list.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/overtime_review_tile.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// Pending check-out corrections and overtime for Org Admins (organization)
/// and Branch Managers ([activeBranchId]). Owns its controller; a change of
/// branch clears the lists and reloads them for the new branch.
class AttendanceExceptionsSection extends StatefulWidget {
  const AttendanceExceptionsSection({
    super.key,
    required this.access,
    this.activeBranchId,
    this.onDecided,
  });

  final UserAccessContext access;

  /// The Branch Manager's active branch; null for Org Admins.
  final String? activeBranchId;

  /// Called after a decision succeeds (e.g. to reload attendance records).
  final VoidCallback? onDecided;

  @override
  State<AttendanceExceptionsSection> createState() =>
      _AttendanceExceptionsSectionState();
}

class _AttendanceExceptionsSectionState
    extends State<AttendanceExceptionsSection> {
  late final AttendanceExceptionsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AttendanceExceptionsController(
      repository: context.read<AttendanceExceptionsRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(covariant AttendanceExceptionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeBranchId != widget.activeBranchId ||
        oldWidget.access.user.id != widget.access.user.id) {
      _controller.reset();
      _load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() => _controller.load(
    access: widget.access,
    activeBranchId: widget.activeBranchId,
  );

  Future<void> _decideCorrection(
    CheckoutCorrection correction,
    CorrectionDecision decision,
  ) async {
    final confirmed = await confirmCorrectionDecision(
      context,
      correction: correction,
      decision: decision,
      onConfirm: (note) {
        _controller.clearActionError();
        return _controller.reviewCorrection(
          access: widget.access,
          correctionId: correction.id,
          decision: decision,
          note: note,
          activeBranchId: widget.activeBranchId,
        );
      },
      failureMessage: () => _controller.actionErrorMessage,
    );
    if (!confirmed) return;
    _afterDecision(
      decision == CorrectionDecision.approve
          ? 'Check-out correction approved.'
          : 'Check-out correction rejected.',
    );
  }

  Future<void> _decideOvertime(
    AttendanceEntry entry,
    OvertimeDecision decision,
  ) async {
    final confirmed = await confirmOvertimeDecision(
      context,
      entry: entry,
      decision: decision,
      onConfirm: (hours) {
        _controller.clearActionError();
        return _controller.reviewOvertime(
          access: widget.access,
          entryId: entry.id,
          decision: decision,
          approvedHours: hours,
          activeBranchId: widget.activeBranchId,
        );
      },
      failureMessage: () => _controller.actionErrorMessage,
    );
    if (!confirmed) return;
    _afterDecision(
      decision == OvertimeDecision.approve
          ? 'Overtime approved.'
          : 'Overtime rejected.',
    );
  }

  void _afterDecision(String message) {
    if (!mounted) return;
    widget.onDecided?.call();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          if (_controller.isLoading && _controller.hasLoaded)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: AppSpacing.md),
          _body(),
        ],
      ),
    ),
  );

  Widget _header() {
    final count = _controller.pendingCount;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exceptions to review',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _controller.hasLoaded
                    ? '$count pending · check-out corrections and overtime'
                    : 'Check-out corrections and overtime awaiting a decision',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh exceptions',
          onPressed: _controller.isLoading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _body() {
    if (!_controller.hasLoaded) {
      final error = _controller.errorMessage;
      if (error != null) return ErrorState(message: error, onRetry: _load);
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final busy = _controller.isSaving || _controller.isLoading;
    // Not awaited: the dialog shows the request's progress, so the tile
    // button must not spin behind it.
    final corrections = ExceptionReviewList(
      title: 'Check-out corrections',
      emptyMessage: 'No check-out corrections waiting.',
      children: [
        for (final c in _controller.corrections)
          CorrectionReviewTile(
            key: ValueKey('correction-${c.id}'),
            correction: c,
            onApprove: busy
                ? null
                : () => unawaited(
                    _decideCorrection(c, CorrectionDecision.approve),
                  ),
            onReject: busy
                ? null
                : () => unawaited(
                    _decideCorrection(c, CorrectionDecision.reject),
                  ),
          ),
      ],
    );
    final overtime = ExceptionReviewList(
      title: 'Overtime approvals',
      emptyMessage: 'No overtime waiting for approval.',
      children: [
        for (final e in _controller.overtime)
          OvertimeReviewTile(
            key: ValueKey('overtime-${e.id}'),
            entry: e,
            onApprove: busy
                ? null
                : () => unawaited(_decideOvertime(e, OvertimeDecision.approve)),
            onReject: busy
                ? null
                : () => unawaited(_decideOvertime(e, OvertimeDecision.reject)),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.wideContent) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              corrections,
              const SizedBox(height: AppSpacing.lg),
              overtime,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: corrections),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: overtime),
          ],
        );
      },
    );
  }
}
