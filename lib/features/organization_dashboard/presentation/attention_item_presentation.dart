import 'package:flutter/material.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';

/// Maps the pure domain [AttentionItem] to Flutter visuals and navigation.
extension AttentionItemPresentation on AttentionItem {
  StatusType get statusType => switch (severity) {
    AttentionSeverity.urgent => StatusType.urgent,
    AttentionSeverity.pending => StatusType.pending,
    AttentionSeverity.neutral => StatusType.neutral,
    AttentionSeverity.info => StatusType.active,
  };

  IconData get itemIcon => switch (kind) {
    AttentionKind.pendingReturns => Icons.assignment_return_outlined,
    AttentionKind.branchOffline => Icons.domain_disabled,
    AttentionKind.lateArrivals => Icons.schedule,
    AttentionKind.geofenceException => Icons.location_off_outlined,
    AttentionKind.missingCheckOut => Icons.timer_off,
    AttentionKind.shiftTransfers => Icons.swap_horiz,
    AttentionKind.other => Icons.info_outline,
  };

  IconData get actionIcon => switch (kind) {
    AttentionKind.pendingReturns => Icons.arrow_forward,
    AttentionKind.missingCheckOut => Icons.done_all,
    AttentionKind.branchOffline => Icons.build,
    AttentionKind.shiftTransfers => Icons.rule,
    _ => Icons.arrow_forward,
  };

  /// Whether the item's action is the primary follow-up (returns review).
  bool get isPrimaryAction => kind == AttentionKind.pendingReturns;

  Color get iconBackground => switch (statusType) {
    StatusType.urgent => AppColors.statusUrgentContainer,
    StatusType.pending => AppColors.statusPendingContainer,
    StatusType.neutral => AppColors.surfaceContainerHigh,
    StatusType.active => AppColors.primaryContainer,
  };

  Color get iconForeground => switch (statusType) {
    StatusType.urgent => AppColors.statusUrgentText,
    StatusType.pending => AppColors.statusPendingText,
    StatusType.neutral => AppColors.onSurfaceVariant,
    StatusType.active => AppColors.onPrimaryContainer,
  };

  Color get badgeColor => switch (statusType) {
    StatusType.urgent => AppColors.error,
    StatusType.pending => AppColors.statusPendingText,
    StatusType.neutral => AppColors.secondary,
    StatusType.active => AppColors.primary,
  };

  /// Route that resolves this item, or null when no destination exists yet.
  String? routeFor({required bool branchScope}) => switch (kind) {
    AttentionKind.pendingReturns =>
      branchScope ? AppRoutes.branchManagerReturns : AppRoutes.orgAdminReturns,
    AttentionKind.lateArrivals ||
    AttentionKind.geofenceException ||
    AttentionKind.missingCheckOut =>
      branchScope
          ? AppRoutes.branchManagerAttendance
          : AppRoutes.orgAdminAttendance,
    AttentionKind.branchOffline =>
      branchScope ? null : AppRoutes.orgAdminBranches,
    AttentionKind.shiftTransfers || AttentionKind.other => null,
  };
}
