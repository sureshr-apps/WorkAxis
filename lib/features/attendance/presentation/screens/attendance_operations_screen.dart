import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_card_item.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_table.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

class AttendanceOperationsScreen extends StatefulWidget {
  const AttendanceOperationsScreen({super.key});

  @override
  State<AttendanceOperationsScreen> createState() =>
      _AttendanceOperationsScreenState();
}

class _AttendanceOperationsScreenState
    extends State<AttendanceOperationsScreen> {
  UserAccessContext? get _access =>
      context.read<AccessController>().accessContext;
  String? get _branchId =>
      context.read<BranchContextController>().activeBranch?.branchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({DateTime? date}) async {
    final access = _access;
    if (access == null) return;
    await context.read<AttendanceController>().loadAttendance(
      access: access,
      activeBranchId: _branchId,
      date: date,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AttendanceController>();
    final access = context.watch<AccessController>().accessContext;
    final branchContext = context.watch<BranchContextController>().activeBranch;
    final role = access?.user.role;
    final isEmployee = role == UserRole.employee;
    final isManager = role == UserRole.branchManager;
    final canReview =
        role == UserRole.orgAdmin || role == UserRole.branchManager;
    final title = isEmployee
        ? 'My Attendance'
        : isManager
        ? 'Branch Attendance'
        : 'Organization Attendance';
    final entries = controller.entries;
    final onTime = entries
        .where((entry) => entry.status == AttendanceStatus.present)
        .length;
    final late = entries
        .where((entry) => entry.status == AttendanceStatus.late)
        .length;
    final exceptions = controller.needsReviewCount;
    final branchName = isManager ? branchContext?.branchName : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ResponsivePageContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    AppPageHeader(
                      eyebrow: isEmployee
                          ? 'Self Service'
                          : 'Time & Attendance',
                      title: title,
                      subtitle: isEmployee
                          ? 'Review your check-in history and shift records.'
                          : isManager
                          ? 'Verify attendance and resolve exceptions for $branchName.'
                          : 'Verify check-ins and resolve organization attendance exceptions.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DateSelector(
                      date: controller.selectedDate,
                      onSelected: (date) => _load(date: date),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ResponsiveKpiSection(
                      cardHeight: 96,
                      cards: [
                        AppKpiCard(
                          title: 'On time',
                          value: '$onTime',
                          accentColor: AppColors.statusActive,
                          icon: Icons.check_circle_outline,
                          iconColor: AppColors.statusActiveText,
                          iconBgColor: AppColors.statusActiveContainer,
                        ),
                        AppKpiCard(
                          title: 'Late arrivals',
                          value: '$late',
                          icon: Icons.schedule_outlined,
                          accentColor: late == 0 ? null : AppColors.statusPending,
                          iconColor: late == 0
                              ? AppColors.secondary
                              : AppColors.statusPendingText,
                          iconBgColor: late == 0
                              ? const Color(0xFFF1F5F9)
                              : AppColors.statusPendingContainer,
                          valueColor: late == 0
                              ? null
                              : AppColors.statusPendingText,
                        ),
                        AppKpiCard(
                          title: 'Needs review',
                          value: '$exceptions',
                          icon: Icons.rule_outlined,
                          accentColor: exceptions == 0 ? null : AppColors.statusUrgent,
                          iconColor: exceptions == 0
                              ? AppColors.secondary
                              : AppColors.statusUrgentText,
                          iconBgColor: exceptions == 0
                              ? const Color(0xFFF1F5F9)
                              : AppColors.statusUrgentContainer,
                          valueColor: exceptions == 0
                              ? null
                              : AppColors.statusUrgentText,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEmployee
                                ? 'My shift records'
                                : 'Attendance records',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${entries.length} records',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (isManager && branchContext == null)
                      const _AttendanceMessage(
                        icon: Icons.store_outlined,
                        title: 'Select an active branch',
                        detail: 'Choose one of your assigned branches before reviewing attendance.',
                      )
                    else if (controller.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (controller.errorMessage != null)
                      _AttendanceMessage(
                        icon: Icons.cloud_off_outlined,
                        title: 'Attendance is unavailable',
                        detail: controller.errorMessage!,
                        action: TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      )
                    else if (entries.isEmpty)
                      const _AttendanceMessage(
                        icon: Icons.event_available_outlined,
                        title: 'No attendance records',
                        detail: 'No check-ins or shift records were found for this date.',
                      )
                    else if (!context.isCompact && !context.isMedium)
                      AttendanceTable(
                        entries: entries,
                        getBranchName: (id) => _branchName(id, access),
                        canReview: canReview,
                        isSaving: controller.isSaving,
                        onReview: canReview
                            ? (entry, decision) =>
                                  _review(entry, access!, decision)
                            : null,
                        onDetails: (entry) => _showDetails(
                          entry,
                          _branchName(entry.branchId, access),
                        ),
                      )
                    else if (context.isMedium)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth =
                              (constraints.maxWidth - AppSpacing.md) / 2;
                          return Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            children: entries.map((entry) {
                              return SizedBox(
                                width: cardWidth,
                                child: AttendanceCardItem(
                                  entry: entry,
                                  branchName: _branchName(entry.branchId, access),
                                  canReview: canReview,
                                  isSaving: controller.isSaving,
                                  onReview: canReview
                                      ? (e, d) => _review(e, access!, d)
                                      : null,
                                  onDetails: () => _showDetails(
                                    entry,
                                    _branchName(entry.branchId, access),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      )
                    else
                      Column(
                        children: [
                          for (final entry in entries) ...[
                            AttendanceCardItem(
                              entry: entry,
                              branchName: _branchName(entry.branchId, access),
                              canReview: canReview,
                              isSaving: controller.isSaving,
                              onReview: canReview
                                  ? (e, d) => _review(e, access!, d)
                                  : null,
                              onDetails: () => _showDetails(
                                entry,
                                _branchName(entry.branchId, access),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
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

  String _branchName(String id, UserAccessContext? access) {
    for (final branch in access?.assignedBranches ?? const []) {
      if (branch.id == id) return branch.name;
    }
    return 'Branch';
  }

  Future<void> _review(
    AttendanceEntry entry,
    UserAccessContext access,
    AttendanceReviewDecision decision,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          decision == AttendanceReviewDecision.verify
              ? 'Verify attendance?'
              : 'Dismiss exception?',
        ),
        content: Text(
          decision == AttendanceReviewDecision.verify
              ? 'Confirm the attendance record for ${entry.employeeName}.'
              : 'Mark the exception for ${entry.employeeName} as reviewed without verification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AttendanceController>().reviewException(
      access: access,
      entryId: entry.id,
      activeBranchId: entry.branchId,
      decision: decision,
    );
  }

  Future<void> _showDetails(AttendanceEntry entry, String branchName) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.employeeName),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Detail(label: 'Branch', value: branchName),
              _Detail(label: 'Date', value: _formatDate(entry.workDate)),
              _Detail(label: 'Check-in', value: _formatTime(entry.checkInAt)),
              _Detail(label: 'Check-out', value: _formatTime(entry.checkOutAt)),
              _Detail(label: 'Status', value: _statusLabel(entry.status)),
              _Detail(
                label: 'Source',
                value: entry.kioskEntry ? 'Kiosk terminal' : 'Mobile app',
              ),
              if (entry.note != null)
                _Detail(label: 'Note', value: entry.note!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.date, required this.onSelected});
  final DateTime date;
  final ValueChanged<DateTime> onSelected;
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isYesterday =
        date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ChoiceChip(
          label: const Text(
            'Today',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          selected: isToday,
          selectedColor: AppColors.primary.withValues(alpha: 0.12),
          side: BorderSide(
            color: isToday ? AppColors.primary : const Color(0xFFCBD5E1),
          ),
          onSelected: (_) => onSelected(today),
        ),
        ChoiceChip(
          label: const Text(
            'Yesterday',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          selected: isYesterday,
          selectedColor: AppColors.primary.withValues(alpha: 0.12),
          side: BorderSide(
            color: isYesterday ? AppColors.primary : const Color(0xFFCBD5E1),
          ),
          onSelected: (_) => onSelected(yesterday),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(date),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendanceMessage extends StatelessWidget {
  const _AttendanceMessage({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });
  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(color: AppColors.outlineSubtle),
    ),
    child: Column(
      children: [
        Icon(icon, size: 32, color: AppColors.secondary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.onSurfaceVariant),
        ),
        if (action != null) ...[const SizedBox(height: AppSpacing.sm), action!],
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

String _statusLabel(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => 'Present',
  AttendanceStatus.late => 'Late',
  AttendanceStatus.absent => 'Absent',
  AttendanceStatus.incomplete => 'Incomplete',
};

String _formatTime(DateTime? time) => time == null
    ? '—'
    : '${time.hour > 12
          ? time.hour - 12
          : time.hour == 0
          ? 12
          : time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';

String _formatDate(DateTime date) =>
    '${_month(date.month)} ${date.day}, ${date.year}';
String _month(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];
