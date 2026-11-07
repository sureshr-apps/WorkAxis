import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// Read-only account details; full-screen on phones, dialog elsewhere.
class MemberDetailsDialog extends StatelessWidget {
  const MemberDetailsDialog({
    super.key,
    required this.member,
    required this.branchNames,
  });

  final OrganizationMember member;
  final List<String> branchNames;

  @override
  Widget build(BuildContext context) {
    final email = LoginEmail.displayable(member.email);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Detail(label: 'Role', value: member.role.displayName),
        _Detail(label: 'Username', value: member.username),
        _Detail(label: 'Email', value: email.isEmpty ? 'Not provided' : email),
        _Detail(label: 'Phone', value: member.phone ?? 'Not provided'),
        _Detail(
          label: 'Status',
          value: member.status == AccountStatus.active ? 'Active' : 'Suspended',
        ),
        _Detail(
          label: 'Branches',
          value: branchNames.isEmpty ? 'None' : branchNames.join(', '),
        ),
      ],
    );
    if (context.isCompact) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: const Text('Account details')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.fullName, style: AppTypography.headlineMedium),
                  const SizedBox(height: AppSpacing.lg),
                  content,
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppButton.primary(
                text: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      );
    }
    // A plain Dialog (not AlertDialog): AlertDialog lays its content out with
    // intrinsic sizing, which AppButton's LayoutBuilder cannot support.
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(member.fullName, style: AppTypography.headlineMedium),
                const SizedBox(height: AppSpacing.md),
                content,
                const SizedBox(height: AppSpacing.md),
                AppButton.outlined(
                  text: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
