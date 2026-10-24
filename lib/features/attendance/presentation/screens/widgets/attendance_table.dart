import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

/// Clean, high-fidelity table representation of attendance records for desktop and tablet.
class AttendanceTable extends StatelessWidget {
  final List<AttendanceEntry> entries;
  final String Function(String branchId) getBranchName;
  final bool canReview;
  final bool isSaving;
  final void Function(AttendanceEntry entry, AttendanceReviewDecision decision)?
  onReview;
  final ValueChanged<AttendanceEntry> onDetails;

  const AttendanceTable({
    super.key,
    required this.entries,
    required this.getBranchName,
    required this.canReview,
    required this.isSaving,
    required this.onReview,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    const minimumTableWidth = 1150.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0x04000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
                    .clamp(minimumTableWidth, double.infinity)
                    .toDouble()
              : minimumTableWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Table Header
                  _buildHeader(),

                  // Table Rows
                  for (var index = 0; index < entries.length; index++) ...[
                    if (index > 0)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF1F5F9),
                      ),
                    _buildRow(entries[index]),
                  ],

                  // Table Footer
                  _buildFooter(entries.length),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        children: const [
          Expanded(flex: 4, child: _HeaderLabel('EMPLOYEE')),
          Expanded(flex: 3, child: _HeaderLabel('BRANCH / HUB')),
          Expanded(flex: 2, child: _HeaderLabel('CHECK IN')),
          Expanded(flex: 2, child: _HeaderLabel('CHECK OUT')),
          Expanded(flex: 3, child: _HeaderLabel('METHOD')),
          Expanded(flex: 3, child: _HeaderLabel('STATUS')),
          Expanded(flex: 4, child: _HeaderLabel('EXCEPTION & REVIEW')),
          SizedBox(width: 176, child: _HeaderLabel('ACTIONS', alignEnd: true)),
        ],
      ),
    );
  }

  Widget _buildRow(AttendanceEntry entry) {
    final branchName = getBranchName(entry.branchId);
    final initials = _getInitials(entry.employeeName);
    final isNeedsReview =
        entry.reviewStatus == AttendanceReviewStatus.needsReview;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDetails(entry),
        hoverColor: const Color(0xFFF8FAFC),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Employee
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _avatarBgColor(initials),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _avatarTextColor(initials),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.employeeName,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.employeeId,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Branch / Hub
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        branchName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Check In
              Expanded(
                flex: 2,
                child: Text(
                  _formatTime(entry.checkInAt),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12.5,
                    fontWeight: entry.checkInAt != null
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: entry.checkInAt != null
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),

              // 4. Check Out
              Expanded(
                flex: 2,
                child: Text(
                  _formatTime(entry.checkOutAt),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12.5,
                    fontWeight: entry.checkOutAt != null
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: entry.checkOutAt != null
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),

              // 5. Method
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: entry.kioskEntry
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: entry.kioskEntry
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFFDBEAFE),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          entry.kioskEntry
                              ? Icons.tablet_android_outlined
                              : Icons.phone_android_outlined,
                          size: 13,
                          color: entry.kioskEntry
                              ? const Color(0xFF475569)
                              : const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            entry.kioskEntry ? 'Kiosk' : 'Mobile',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: entry.kioskEntry
                                  ? const Color(0xFF475569)
                                  : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 6. Status
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatusPill(entry.status),
                ),
              ),

              // 7. Exception & Review
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReviewPill(entry.reviewStatus),
                    if (entry.note != null && entry.note!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 8. Actions
              SizedBox(
                width: 176,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canReview && isNeedsReview) ...[
                          // Quick Verify Button
                          IconButton(
                            icon: const Icon(Icons.check_circle_rounded, size: 20),
                            color: const Color(0xFF16A34A),
                            tooltip: 'Verify attendance',
                            onPressed: isSaving
                                ? null
                                : () => onReview?.call(
                                      entry,
                                      AttendanceReviewDecision.verify,
                                    ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Quick Dismiss Button
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, size: 20),
                            color: const Color(0xFF64748B),
                            tooltip: 'Dismiss exception',
                            onPressed: isSaving
                                ? null
                                : () => onReview?.call(
                                      entry,
                                      AttendanceReviewDecision.dismiss,
                                    ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        // Details Action Pill
                        InkWell(
                          onTap: () => onDetails(entry),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Details',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(AttendanceStatus status) {
    Color bg;
    Color dot;
    Color text;
    String label;

    switch (status) {
      case AttendanceStatus.present:
        bg = const Color(0xFFDCFCE7);
        dot = const Color(0xFF16A34A);
        text = const Color(0xFF15803D);
        label = 'Present';
        break;
      case AttendanceStatus.late:
        bg = const Color(0xFFFEF3C7);
        dot = const Color(0xFFD97706);
        text = const Color(0xFFB45309);
        label = 'Late';
        break;
      case AttendanceStatus.absent:
        bg = const Color(0xFFFEE2E2);
        dot = const Color(0xFFDC2626);
        text = const Color(0xFFB91C1C);
        label = 'Absent';
        break;
      case AttendanceStatus.incomplete:
        bg = const Color(0xFFFEE2E2);
        dot = const Color(0xFFEA580C);
        text = const Color(0xFFC2410C);
        label = 'Incomplete';
        break;
    }

    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPill(AttendanceReviewStatus review) {
    switch (review) {
      case AttendanceReviewStatus.needsReview:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 12,
                color: Color(0xFFB45309),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Needs review',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
        );
      case AttendanceReviewStatus.verified:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_rounded,
                size: 12,
                color: Color(0xFF15803D),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Verified',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
        );
      case AttendanceReviewStatus.dismissed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'Reviewed',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        );
      case AttendanceReviewStatus.none:
        return Text(
          '—',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF94A3B8),
          ),
        );
    }
  }

  Widget _buildFooter(int count) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $count attendance records',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Platform Fleet: ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.statusActive,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'INDIA',
                      style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, math.min(2, parts[0].length)).toUpperCase();
    }
    return 'EM';
  }

  static Color _avatarBgColor(String initials) {
    final hash = initials.codeUnits.fold(0, (acc, val) => acc + val);
    const colors = [
      Color(0xFFDBEAFE), // Blue
      Color(0xFFE0E7FF), // Indigo
      Color(0xFFEDE9FE), // Purple
      Color(0xFFDCFCE7), // Green
      Color(0xFFFEF3C7), // Amber
      Color(0xFFCCFBF1), // Teal
    ];
    return colors[hash % colors.length];
  }

  static Color _avatarTextColor(String initials) {
    final hash = initials.codeUnits.fold(0, (acc, val) => acc + val);
    const colors = [
      Color(0xFF1D4ED8),
      Color(0xFF4338CA),
      Color(0xFF6D28D9),
      Color(0xFF15803D),
      Color(0xFFB45309),
      Color(0xFF0F766E),
    ];
    return colors[hash % colors.length];
  }

  static String _formatTime(DateTime? time) => time == null
      ? '—'
      : '${time.hour > 12
            ? time.hour - 12
            : time.hour == 0
            ? 12
            : time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
}

class _HeaderLabel extends StatelessWidget {
  final String text;
  final bool alignEnd;

  const _HeaderLabel(this.text, {this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }
}
