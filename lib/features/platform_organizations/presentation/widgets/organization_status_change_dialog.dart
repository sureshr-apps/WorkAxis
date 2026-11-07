import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';

/// The two status transitions a platform user can request.
enum OrganizationStatusChange { suspend, reactivate }

/// Copy and colors that differ between the suspend and reactivate dialogs.
class _StatusChangeConfig {
  const _StatusChangeConfig({
    required this.title,
    required this.confirmLabel,
    required this.icon,
    required this.accent,
    required this.accentContainer,
    required this.accentBorder,
    required this.currentStatusLabel,
    required this.currentStatusIsActive,
    required this.outcome,
    required this.detail,
    required this.failureMessage,
  });

  final String title;
  final String confirmLabel;
  final IconData icon;
  final Color accent;
  final Color accentContainer;
  final Color accentBorder;
  final String currentStatusLabel;
  final bool currentStatusIsActive;
  final String outcome;
  final String detail;
  final String failureMessage;

  static _StatusChangeConfig of(OrganizationStatusChange change) =>
      switch (change) {
        OrganizationStatusChange.suspend => const _StatusChangeConfig(
          title: 'Suspend Organization?',
          confirmLabel: 'Suspend Organization',
          icon: Icons.pause_circle,
          accent: AppColors.statusUrgent,
          accentContainer: AppColors.statusUrgentContainer,
          accentBorder: AppColors.statusUrgentBorder,
          currentStatusLabel: 'Currently Active',
          currentStatusIsActive: true,
          outcome: ' will be marked as Suspended until it is reactivated.',
          detail:
              'Every member of this organization is signed out and cannot '
              'sign in again until it is reactivated.',
          failureMessage:
              'The organization could not be suspended. Please try again.',
        ),
        OrganizationStatusChange.reactivate => const _StatusChangeConfig(
          title: 'Reactivate Organization?',
          confirmLabel: 'Reactivate Organization',
          icon: Icons.play_circle,
          accent: AppColors.statusActive,
          accentContainer: AppColors.statusActiveContainer,
          accentBorder: AppColors.statusActiveBorder,
          currentStatusLabel: 'Currently Suspended',
          currentStatusIsActive: false,
          outcome: ' will return to Active status.',
          detail:
              'Members of this organization can sign in again and branch '
              'operations resume.',
          failureMessage:
              'The organization could not be reactivated. Please try again.',
        ),
      };
}

/// Confirmation dialog for suspending or reactivating an organization.
///
/// [onConfirm] performs the change and returns whether it succeeded. On
/// failure the dialog stays open and shows [failureMessage] (a server-derived
/// message when the caller has one) with a retry action.
class OrganizationStatusChangeDialog extends StatefulWidget {
  const OrganizationStatusChangeDialog({
    super.key,
    required this.organization,
    required this.change,
    required this.onConfirm,
    this.failureMessage,
  });

  final CustomerOrganization organization;
  final OrganizationStatusChange change;
  final Future<bool> Function() onConfirm;

  /// Supplies the latest failure text after [onConfirm] returns false.
  final String? Function()? failureMessage;

  @override
  State<OrganizationStatusChangeDialog> createState() =>
      _OrganizationStatusChangeDialogState();
}

class _OrganizationStatusChangeDialogState
    extends State<OrganizationStatusChangeDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  _StatusChangeConfig get _config => _StatusChangeConfig.of(widget.change);

  Future<void> _handleConfirm() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await widget.onConfirm();
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = widget.failureMessage?.call() ?? _config.failureMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final org = widget.organization;
    final config = _config;

    return Dialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.isCompact ? AppSpacing.md : AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(config: config, organization: org, busy: _isLoading),
              const SizedBox(height: AppSpacing.md),
              _IdentityBanner(config: config, organization: org),
              const SizedBox(height: AppSpacing.md),
              Text.rich(
                TextSpan(
                  style: AppTypography.bodyMedium,
                  children: [
                    TextSpan(
                      text: org.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: config.outcome),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(config.detail, style: AppTypography.bodySmall),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                _FailureAlert(message: _errorMessage!, onRetry: _handleConfirm),
              ],
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton.outlined(
                    text: 'Cancel',
                    isFullWidth: false,
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                  AppButton(
                    text: config.confirmLabel,
                    variant: widget.change == OrganizationStatusChange.suspend
                        ? AppButtonVariant.destructive
                        : AppButtonVariant.primary,
                    isFullWidth: false,
                    isLoading: _isLoading,
                    onPressed: _handleConfirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.config,
    required this.organization,
    required this.busy,
  });

  final _StatusChangeConfig config;
  final CustomerOrganization organization;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: config.accentContainer,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: config.accentBorder),
          ),
          child: Icon(config.icon, color: config.accent, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(config.title, style: AppTypography.titleLarge),
              Text(
                'Platform Management Action · ${organization.code}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close, size: 20, color: AppColors.secondary),
          onPressed: busy ? null : () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _IdentityBanner extends StatelessWidget {
  const _IdentityBanner({required this.config, required this.organization});

  final _StatusChangeConfig config;
  final CustomerOrganization organization;

  @override
  Widget build(BuildContext context) {
    final currentIsActive = config.currentStatusIsActive;
    final initialsBackground = currentIsActive
        ? AppColors.primaryContainer
        : AppColors.statusUrgentContainer;
    final initialsForeground = currentIsActive
        ? AppColors.primary
        : AppColors.statusUrgent;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: initialsBackground,
              borderRadius: AppSpacing.roundedSm,
            ),
            alignment: Alignment.center,
            child: Text(
              organization.initials,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: initialsForeground,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organization.name,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  organization.code,
                  style: AppTypography.labelMono.copyWith(
                    fontSize: 12,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: currentIsActive
                  ? AppColors.statusActiveContainer
                  : AppColors.statusUrgentContainer,
              borderRadius: AppSpacing.roundedPill,
              border: Border.all(
                color: currentIsActive
                    ? AppColors.statusActiveBorder
                    : AppColors.statusUrgentBorder,
              ),
            ),
            child: Text(
              config.currentStatusLabel,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: currentIsActive
                    ? AppColors.statusActiveText
                    : AppColors.statusUrgentText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureAlert extends StatelessWidget {
  const _FailureAlert({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.statusUrgentContainer,
          borderRadius: AppSpacing.roundedSm,
          border: Border.all(color: AppColors.statusUrgentBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 18,
              color: AppColors.statusUrgent,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.statusUrgentText,
                ),
              ),
            ),
            AppButton.outlined(
              text: 'Retry',
              isFullWidth: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
