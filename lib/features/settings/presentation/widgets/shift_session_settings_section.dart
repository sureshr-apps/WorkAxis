import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/settings/domain/validators/settings_validators.dart';
import 'package:workaxis/features/settings/presentation/widgets/settings_section_card.dart';

/// Timing rules for shift sessions: when a check-in counts toward a shift,
/// when to remind about check-out, when an open session needs review and
/// when it is closed as a missing check-out. The screen owns the controllers.
class ShiftSessionSettingsSection extends StatelessWidget {
  const ShiftSessionSettingsSection({
    super.key,
    required this.earlyCheckInController,
    required this.checkoutReminderController,
    required this.overtimeReviewController,
    required this.maxSessionController,
    required this.errors,
    required this.onChanged,
  });

  final TextEditingController earlyCheckInController;
  final TextEditingController checkoutReminderController;
  final TextEditingController overtimeReviewController;
  final TextEditingController maxSessionController;
  final Map<SettingsField, String> errors;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => SettingsSectionCard(
    icon: Icons.nights_stay_outlined,
    title: 'Shift Sessions',
    subtitle:
        'Check-in windows, check-out reminders, overtime review and session '
        'closure, including night shifts that end the next day',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsFieldPair(
          first: _TimingField(
            controller: earlyCheckInController,
            label: 'Early Check-in Window (Minutes)',
            error: errors[SettingsField.earlyCheckIn],
            helper:
                'How long before a shift starts a check-in still counts '
                'toward it. 0–${SettingsValidators.maxEarlyCheckInMinutes} min.',
            onChanged: onChanged,
          ),
          second: _TimingField(
            controller: checkoutReminderController,
            label: 'Check-out Reminder (Minutes)',
            error: errors[SettingsField.checkoutReminder],
            helper:
                'After the scheduled shift end, the employee is reminded to '
                'check out. 0–${SettingsValidators.maxCheckoutReminderMinutes} min.',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsFieldPair(
          first: _TimingField(
            controller: overtimeReviewController,
            label: 'Overtime Allowance Before Review (Minutes)',
            error: errors[SettingsField.overtimeReview],
            helper:
                'After the shift end plus this allowance, an open session is '
                'flagged overdue for the manager; a later check-out is still '
                'recorded. 0–${SettingsValidators.maxOvertimeReviewMinutes} min.',
            onChanged: onChanged,
          ),
          second: _TimingField(
            controller: maxSessionController,
            label: 'Maximum Session Length (Hours)',
            error: errors[SettingsField.maxSession],
            helper:
                'At this length an open session is closed as a missing '
                'check-out for the employee to correct. No check-out is '
                'recorded automatically. ${SettingsValidators.minSessionHours}–'
                '${SettingsValidators.maxSessionHours} h.',
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );
}

/// A whole-number field with a wrapping explanation below it.
class _TimingField extends StatelessWidget {
  const _TimingField({
    required this.controller,
    required this.label,
    required this.helper,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String helper;
  final String? error;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppTextField(
        controller: controller,
        label: label,
        errorText: error,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => onChanged(),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        helper,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );
}
