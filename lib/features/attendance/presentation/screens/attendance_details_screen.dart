import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/attendance_presentation.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// Read-only page with the details of one attendance record. [onClose] is
/// reported by both the breadcrumb back link and the Close button.
class AttendanceDetailsScreen extends StatelessWidget {
  const AttendanceDetailsScreen({
    super.key,
    required this.entry,
    required this.branchName,
    required this.backLabel,
    required this.onClose,
  });

  final AttendanceEntry entry;
  final String branchName;

  /// Name of the list the page belongs to, shown in the breadcrumb.
  final String backLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
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
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageBreadcrumb(
                    backLabel: backLabel,
                    currentLabel: 'Attendance details',
                    onBack: onClose,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppPageHeader(
                    eyebrow: 'Time & Attendance',
                    title: entry.employeeName,
                    subtitle: 'Read-only attendance record.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DashboardSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Detail(label: 'Branch', value: branchName),
                        _Detail(
                          label: 'Date',
                          value: AppFormatters.formatDate(entry.workDate),
                        ),
                        _Detail(
                          label: 'Check-in',
                          value: AppFormatters.formatTime(
                            entry.checkInAt,
                            placeholder: '—',
                          ),
                        ),
                        _Detail(
                          label: 'Check-out',
                          value: AppFormatters.formatTime(
                            entry.checkOutAt,
                            placeholder: '—',
                          ),
                        ),
                        _Detail(label: 'Status', value: entry.status.label),
                        _Detail(
                          label: 'Source',
                          value: entry.kioskEntry
                              ? 'Kiosk terminal'
                              : 'Mobile app',
                        ),
                        if (entry.note != null)
                          _Detail(label: 'Note', value: entry.note!),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
