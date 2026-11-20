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
import 'package:workaxis/features/employees/presentation/screens/widgets/employee_photo_picker.dart';

/// Form section managing KYC and personal demographic details:
/// - Aadhaar Number (12 digits)
/// - Aadhaar Card Photo capture/upload
/// - Date of Birth (DatePicker)
/// - Gender (Male, Female, Other)
/// - Residential Address
class EmployeeDemographicsSection extends StatelessWidget {
  const EmployeeDemographicsSection({
    super.key,
    required this.aadhaarController,
    required this.addressController,
    required this.aadhaarPhotoPath,
    required this.onAadhaarPhotoChanged,
    required this.dateOfBirth,
    required this.onDateOfBirthChanged,
    required this.gender,
    required this.onGenderChanged,
    this.feedback = MemberFormFeedback.none,
  });

  final TextEditingController aadhaarController;
  final TextEditingController addressController;
  final String? aadhaarPhotoPath;
  final ValueChanged<String?> onAadhaarPhotoChanged;
  final DateTime? dateOfBirth;
  final ValueChanged<DateTime?> onDateOfBirthChanged;
  final String? gender;
  final ValueChanged<String?> onGenderChanged;
  final MemberFormFeedback feedback;

  static final _dateFormat = DateFormat('dd MMM yyyy');

  Future<void> _pickDob(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(1940);
    final lastDate = DateTime(now.year - 14, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: clampDate(
        dateOfBirth ?? DateTime(now.year - 22, now.month, now.day),
        firstDate,
        lastDate,
      ),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'SELECT DATE OF BIRTH',
    );
    if (picked != null) {
      onDateOfBirthChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KYC & Demographics',
          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Official identity verification and residential contact information.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Aadhaar Number
        feedback.anchor(
          MemberField.aadhaarNumber,
          AppTextField(
            controller: aadhaarController,
            label: feedback.label('Aadhaar Number', MemberField.aadhaarNumber),
            hintText: '12-digit UID number (e.g. 5432 1098 7654)',
            keyboardType: TextInputType.number,
            errorText: feedback.errorFor(MemberField.aadhaarNumber),
            prefixIcon: const Icon(Icons.fingerprint_rounded, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Aadhaar Document Photo Attachment
        feedback.anchor(
          MemberField.aadhaarPhoto,
          EmployeePhotoPicker.document(
            imagePath: aadhaarPhotoPath,
            onImageChanged: onAadhaarPhotoChanged,
            label: feedback.label(
              'Aadhaar Card Document Photo',
              MemberField.aadhaarPhoto,
            ),
            errorText: feedback.errorFor(MemberField.aadhaarPhoto),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Date of Birth & Gender Row (Matched sizing & styling)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: feedback.anchor(
                MemberField.dateOfBirth,
                AppDatePickerField(
                  label: feedback.label(
                    'Date of Birth',
                    MemberField.dateOfBirth,
                  ),
                  errorText: feedback.errorFor(MemberField.dateOfBirth),
                  onClear: dateOfBirth != null
                      ? () => onDateOfBirthChanged(null)
                      : null,
                  valueText: dateOfBirth != null
                      ? _dateFormat.format(dateOfBirth!)
                      : null,
                  hintText: 'Select Date',
                  prefixIcon: const Icon(Icons.cake_outlined, size: 20),
                  onTap: () => _pickDob(context),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gender',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<String>(
                    initialValue: gender ?? 'Male',
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Select Gender',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: onGenderChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Address
        AppTextField(
          controller: addressController,
          label: feedback.label('Residential Address', MemberField.address),
          errorText: feedback.errorFor(MemberField.address),
          hintText: 'Street address, city, state, postal code',
          minLines: 2,
          maxLines: 4,
          prefixIcon: const Icon(Icons.home_outlined, size: 20),
        ),
      ],
    );
  }
}
