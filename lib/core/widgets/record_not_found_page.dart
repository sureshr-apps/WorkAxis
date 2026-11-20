import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';

/// Full page for a routed record that could not be loaded. It keeps the same
/// breadcrumb back link as the record's pages, so the user can always leave.
class RecordNotFoundPage extends StatelessWidget {
  const RecordNotFoundPage({
    super.key,
    required this.backLabel,
    required this.currentLabel,
    required this.onBack,
    required this.message,
    required this.onRetry,
  });

  final String backLabel;
  final String currentLabel;
  final VoidCallback onBack;
  final String message;
  final FutureOr<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ResponsivePageContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageBreadcrumb(
                backLabel: backLabel,
                currentLabel: currentLabel,
                onBack: onBack,
              ),
              const SizedBox(height: AppSpacing.md),
              ErrorState(message: message, onRetry: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
