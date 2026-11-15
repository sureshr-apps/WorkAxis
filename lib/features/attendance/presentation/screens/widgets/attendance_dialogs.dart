import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

/// Asks the reviewer to confirm a verify/dismiss decision. Resolves true only
/// when confirmed.
Future<bool> confirmAttendanceReview(
  BuildContext context, {
  required AttendanceEntry entry,
  required AttendanceReviewDecision decision,
}) async {
  final isVerify = decision == AttendanceReviewDecision.verify;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _DialogShell(
      title: isVerify ? 'Verify attendance?' : 'Dismiss exception?',
      actions: [
        AppButton.outlined(
          text: 'Cancel',
          isFullWidth: false,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton.primary(
          text: 'Continue',
          isFullWidth: false,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
      children: [
        Text(
          isVerify
              ? 'Confirm the attendance record for ${entry.employeeName}.'
              : 'Mark the exception for ${entry.employeeName} as reviewed without verification.',
          style: AppTypography.bodyMedium,
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Bounded, scrollable dialog frame. A plain [Dialog] is used instead of
/// `AlertDialog` because the latter measures its content and actions
/// intrinsically, which `AppButton` (a `LayoutBuilder`) cannot answer.
class _DialogShell extends StatelessWidget {
  const _DialogShell({
    required this.title,
    required this.children,
    required this.actions,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.md),
              ...children,
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
