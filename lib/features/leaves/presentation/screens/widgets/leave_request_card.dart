import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';

class LeaveRequestCard extends StatelessWidget {
  const LeaveRequestCard({
    super.key,
    required this.request,
    this.showApplicant = false,
    this.showBranch = false,
    this.onEdit,
    this.onReview,
    this.isSaving = false,
  });

  final LeaveRequest request;
  final bool showApplicant;
  final bool showBranch;
  final FutureOr<void> Function()? onEdit;
  final FutureOr<void> Function(LeaveStatus)? onReview;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final start = localizations.formatMediumDate(request.startDate);
    final end = localizations.formatMediumDate(request.endDate);
    final statusType = switch (request.status) {
      LeaveStatus.pending => StatusType.pending,
      LeaveStatus.approved => StatusType.active,
      LeaveStatus.rejected => StatusType.urgent,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showApplicant
                          ? request.applicantName
                          : request.leaveType.label,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (showApplicant)
                      Text(
                        '${request.applicantRole.displayName} · ${request.leaveType.label}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              StatusChip(label: request.status.label, type: statusType),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _InfoLine(
                icon: Icons.calendar_month_outlined,
                text: start == end ? start : '$start – $end',
              ),
              _InfoLine(
                icon: Icons.timelapse_outlined,
                text:
                    '${request.inclusiveDays} ${request.inclusiveDays == 1 ? 'day' : 'days'}',
              ),
              if (showBranch)
                _InfoLine(icon: Icons.store_outlined, text: request.branchName),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(request.reason, style: AppTypography.bodyMedium),
          if (request.reviewerName != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${request.status == LeaveStatus.approved ? 'Approved' : 'Reviewed'} by ${request.reviewerName}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          if (request.reviewerNotes?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              request.reviewerNotes!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          if (onEdit != null || onReview != null) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: onEdit != null
                  ? WrapAlignment.end
                  : WrapAlignment.start,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (onEdit != null)
                  AppButton.outlined(
                    text: 'Edit pending request',
                    iconData: Icons.edit_outlined,
                    isFullWidth: false,
                    onPressed: isSaving ? null : onEdit,
                  ),
                if (onReview != null)
                  AppButton.secondary(
                    text: 'Approve',
                    iconData: Icons.check_rounded,
                    isFullWidth: false,
                    onPressed: isSaving
                        ? null
                        : () => onReview!(LeaveStatus.approved),
                    isLoading: isSaving,
                  ),
                if (onReview != null)
                  AppButton.outlined(
                    text: 'Reject',
                    iconData: Icons.close_rounded,
                    isFullWidth: false,
                    onPressed: isSaving
                        ? null
                        : () => onReview!(LeaveStatus.rejected),
                    isLoading: isSaving,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
      const SizedBox(width: AppSpacing.xs),
      Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );
}
