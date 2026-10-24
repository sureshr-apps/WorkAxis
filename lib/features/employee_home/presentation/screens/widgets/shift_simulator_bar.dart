import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';

/// Interactive shift state simulator bar matching the Stitch demo controls.
class ShiftSimulatorBar extends StatelessWidget {
  final AttendanceStatus currentStatus;
  final ValueChanged<AttendanceStatus> onStatusChanged;

  const ShiftSimulatorBar({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCompact) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Simulation:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            _buildStatePill(
              label: 'Not Checked In',
              status: AttendanceStatus.notCheckedIn,
            ),
            const SizedBox(width: 4),
            _buildStatePill(
              label: 'Checked In (Active)',
              status: AttendanceStatus.checkedIn,
            ),
            const SizedBox(width: 4),
            _buildStatePill(
              label: 'On Break',
              status: AttendanceStatus.onBreak,
            ),
            const SizedBox(width: 4),
            _buildStatePill(
              label: 'Shift Completed',
              status: AttendanceStatus.checkedOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatePill({
    required String label,
    required AttendanceStatus status,
  }) {
    final isSelected = currentStatus == status;

    return InkWell(
      onTap: () => onStatusChanged(status),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x1A003594),
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
