import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/profile/presentation/screens/widgets/profile_section_card.dart';

/// Voluntary password change backed by [AuthController.changePassword];
/// success and failure reflect the real result.
class ChangePasswordCard extends StatefulWidget {
  const ChangePasswordCard({super.key});

  @override
  State<ChangePasswordCard> createState() => _ChangePasswordCardState();
}

class _ChangePasswordCardState extends State<ChangePasswordCard> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _notify(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? AppColors.statusActive
            : AppColors.statusUrgent,
      ),
    );
  }

  String? _validate() {
    if (_current.text.isEmpty || _new.text.isEmpty || _confirm.text.isEmpty) {
      return 'Please fill out all password fields.';
    }
    if (_new.text != _confirm.text) return 'New passwords do not match.';
    if (ContactValidators.password(_new.text) != null) {
      return 'New password must be at least 8 characters long.';
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      _notify(error, success: false);
      return;
    }
    final auth = context.read<AuthController>();
    setState(() => _isUpdating = true);
    final success = await auth.changePassword(
      currentPassword: _current.text,
      newPassword: _new.text,
    );
    if (!mounted) return;
    setState(() {
      _isUpdating = false;
      if (success) {
        _current.clear();
        _new.clear();
        _confirm.clear();
      }
    });
    _notify(
      success
          ? 'Your password has been changed successfully.'
          : (auth.passwordChangeError ??
                'Your password could not be changed. Please try again.'),
      success: success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      icon: Icons.lock_reset_outlined,
      title: 'Security & Password',
      subtitle: 'Change your sign-in password voluntarily at any time',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPasswordField(
            controller: _current,
            label: 'Current Password',
            hintText: 'Enter your current password',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final newField = AppPasswordField(
                controller: _new,
                label: 'New Password',
                hintText: 'At least 8 characters',
                textInputAction: TextInputAction.next,
              );
              final confirmField = AppPasswordField(
                controller: _confirm,
                label: 'Confirm New Password',
                hintText: 'Repeat the new password',
                onSubmitted: (_) => _submit(),
              );
              if (constraints.maxWidth < AppBreakpoints.formSplit) {
                return Column(
                  children: [
                    newField,
                    const SizedBox(height: AppSpacing.md),
                    confirmField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: newField),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: confirmField),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.responsive(
              text: 'Update Password',
              isLoading: _isUpdating,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
