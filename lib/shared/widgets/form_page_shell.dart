import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/form_action_row.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// Full page for a single-record form: breadcrumb back link, page header, the
/// form card and the Cancel/submit footer.
///
/// The shell only renders. The form reports through [onClose] and [onSubmit];
/// a failed save passes its message in [errorMessage]. While [isBusy] the page
/// cannot be left, so an in-flight save is never orphaned.
class FormPageShell extends StatelessWidget {
  const FormPageShell({
    super.key,
    required this.backLabel,
    required this.currentLabel,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.submitLabel,
    required this.onClose,
    required this.onSubmit,
    this.submitEnabled = true,
    this.isBusy = false,
    this.errorMessage,
  });

  /// Name of the page the back link returns to.
  final String backLabel;

  /// Name of this form, shown after the breadcrumb separator.
  final String currentLabel;
  final String eyebrow;
  final String title;
  final Widget body;
  final String submitLabel;

  /// Back link and Cancel.
  final VoidCallback onClose;

  /// Null leaves the submit action disabled.
  final VoidCallback? onSubmit;

  final bool submitEnabled;
  final bool isBusy;

  /// Failure from the last save attempt. Form values stay as entered.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isBusy,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              context.isCompact ? AppSpacing.md : AppSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageBreadcrumb(
                      backLabel: backLabel,
                      currentLabel: currentLabel,
                      onBack: onClose,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPageHeader(eyebrow: eyebrow, title: title),
                    const SizedBox(height: AppSpacing.lg),
                    DashboardSurfaceCard(
                      // Form widgets such as ListTiles need a Material ancestor.
                      child: Material(
                        type: MaterialType.transparency,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (errorMessage != null) ...[
                              ErrorBanner(message: errorMessage!),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            body,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FormActionRow(
                      submitLabel: submitLabel,
                      onCancel: onClose,
                      onSubmit: isBusy || !submitEnabled ? null : onSubmit,
                      isBusy: isBusy,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
