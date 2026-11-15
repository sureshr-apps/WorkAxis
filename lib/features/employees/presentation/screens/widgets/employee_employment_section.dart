import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/utils/date_range_clamp.dart';
import 'package:workaxis/core/widgets/app_date_picker_field.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/employees/domain/models/member_field.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/member_form_feedback.dart';

/// Form section managing employment terms and asset allocations:
/// - Designation (e.g., Billing Executive, Cashier, Store Associate)
/// - Monthly Salary (INR)
/// - Joining Date (DatePicker)
/// - Relieving Date (Optional DatePicker)
/// - Issued Asset Details
class EmployeeEmploymentSection extends StatelessWidget {
  const EmployeeEmploymentSection({
    super.key,
    required this.designationController,
    required this.salaryController,
    required this.joiningDate,
    required this.onJoiningDateChanged,
    required this.relievingDate,
    required this.onRelievingDateChanged,
    required this.assetsController,
    this.feedback = MemberFormFeedback.none,
  });

  final TextEditingController designationController;
  final TextEditingController salaryController;
  final DateTime? joiningDate;
  final ValueChanged<DateTime?> onJoiningDateChanged;
  final DateTime? relievingDate;
  final ValueChanged<DateTime?> onRelievingDateChanged;
  final TextEditingController assetsController;
  final MemberFormFeedback feedback;

  static final _dateFormat = DateFormat('dd MMM yyyy');

  Future<void> _pickJoiningDate(BuildContext context) async {
    final now = DateTime.now();
    final existing = joiningDate ?? now;
    final firstDate = earlierOf(DateTime(2015), existing);
    final lastDate = DateTime(now.year + 2);
    final picked = await showDatePicker(
      context: context,
      initialDate: clampDate(existing, firstDate, lastDate),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'SELECT JOINING DATE',
    );
    if (picked != null) {
      onJoiningDateChanged(picked);
    }
  }

  Future<void> _pickRelievingDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = joiningDate ?? DateTime(2015);
    final lastDate = DateTime(now.year + 5);
    final picked = await showDatePicker(
      context: context,
      initialDate: clampDate(
        relievingDate ?? joiningDate ?? now,
        firstDate,
        lastDate,
      ),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'SELECT RELIEVING DATE',
    );
    if (picked != null) {
      onRelievingDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Employment & Compensation',
          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Role designation, service tenure dates, salary and issued company assets.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Designation & Monthly Salary
        Row(
          children: [
            Expanded(
              child: feedback.anchor(
                MemberField.designation,
                AppTextField(
                  controller: designationController,
                  label: feedback.label('Designation', MemberField.designation),
                  errorText: feedback.errorFor(MemberField.designation),
                  hintText: 'e.g. Store Associate',
                  prefixIcon: const Icon(Icons.work_outline_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: feedback.anchor(
                MemberField.salary,
                AppTextField(
                  controller: salaryController,
                  label: feedback.label('Monthly Salary', MemberField.salary),
                  errorText: feedback.errorFor(MemberField.salary),
                  hintText: 'e.g. 25000',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: const Icon(
                    Icons.currency_rupee_rounded,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Tenure Dates: Joining Date & Relieving Date (Matched sizing & styling)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppDatePickerField(
                label: feedback.label('Joining Date', MemberField.joiningDate),
                errorText: feedback.errorFor(MemberField.joiningDate),
                onClear: joiningDate != null
                    ? () => onJoiningDateChanged(null)
                    : null,
                valueText: joiningDate != null
                    ? _dateFormat.format(joiningDate!)
                    : null,
                hintText: 'Select Date',
                prefixIcon: const Icon(Icons.event_available_rounded, size: 20),
                onTap: () => _pickJoiningDate(context),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppDatePickerField(
                label: 'Relieving Date',
                valueText: relievingDate != null
                    ? _dateFormat.format(relievingDate!)
                    : null,
                hintText: 'Not Set',
                prefixIcon: const Icon(Icons.event_busy_rounded, size: 20),
                onTap: () => _pickRelievingDate(context),
                onClear: relievingDate != null
                    ? () => onRelievingDateChanged(null)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Asset Details
        AppTextField(
          controller: assetsController,
          label: feedback.label(
            'Issued Asset Details',
            MemberField.assetDetails,
          ),
          errorText: feedback.errorFor(MemberField.assetDetails),
          hintText: 'e.g. Samsung Galaxy A14, ID Badge #042, Store Keys, Apron',
          minLines: 2,
          maxLines: 4,
          prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
        ),
      ],
    );
  }
}
