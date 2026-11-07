import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/settings/presentation/controllers/settings_controller.dart';

/// Shared frame of the organization and platform settings screens: header
/// with the save action, load/error states, and save feedback (validation,
/// server failure, saved) driven by [SettingsController].
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.status,
    required this.hasLoaded,
    required this.loadFallbackMessage,
    required this.onRetry,
    required this.onSave,
    required this.children,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final SettingsController controller;

  /// Load status of the settings this page edits.
  final SettingsLoadStatus status;

  /// Whether a settings value is available to edit.
  final bool hasLoaded;
  final String loadFallbackMessage;
  final VoidCallback onRetry;
  final VoidCallback onSave;

  /// Section cards, shown once the settings have loaded.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isLoading =
        status == SettingsLoadStatus.loading ||
        status == SettingsLoadStatus.initial;
    final hasLoadError = status == SettingsLoadStatus.error;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPageHeader(
                  eyebrow: eyebrow,
                  title: title,
                  subtitle: subtitle,
                  action: AppButton.responsive(
                    text: 'Save Changes',
                    iconData: Icons.check,
                    isLoading: controller.isSaving,
                    onPressed: hasLoaded ? onSave : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (hasLoaded) ...[
                  _SaveFeedback(controller: controller),
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.lg),
                    children[i],
                  ],
                ] else if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (hasLoadError)
                  ErrorState(
                    message: controller.loadErrorMessage ?? loadFallbackMessage,
                    onRetry: onRetry,
                  ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveFeedback extends StatelessWidget {
  const _SaveFeedback({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final String? error = controller.saveErrorMessage;
    final hasValidation = controller.validationErrors.isNotEmpty;
    if (error == null && !hasValidation && !controller.lastSaveSucceeded) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: error != null
          ? ErrorBanner(message: error, onDismiss: controller.clearSaveState)
          : hasValidation
          ? ErrorBanner(
              message: 'Fix the highlighted fields, then save again.',
              onDismiss: controller.clearSaveState,
            )
          : const _SavedBanner(),
    );
  }
}

class _SavedBanner extends StatelessWidget {
  const _SavedBanner();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.statusActiveContainer,
          borderRadius: AppSpacing.roundedSm,
          border: Border.all(color: AppColors.statusActiveBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.statusActiveText,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Changes saved.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.statusActiveText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
