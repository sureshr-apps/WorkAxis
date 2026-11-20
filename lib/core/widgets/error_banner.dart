import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// An operational alert banner displaying errors or warning feedback.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onDismiss;
  final FutureOr<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      label: 'Error: $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.statusUrgentContainer,
          borderRadius: AppSpacing.roundedSm,
          border: Border.all(color: AppColors.statusUrgentBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: AppColors.statusUrgentText,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.statusUrgentText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _RetryButton(onPressed: onRetry!),
            ],
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                tooltip: 'Dismiss',
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.minTouchTarget,
                  minHeight: AppSpacing.minTouchTarget,
                ),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.statusUrgentText,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  const _RetryButton({required this.onPressed});

  final FutureOr<void> Function() onPressed;

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _isLoading = false;

  Future<void> _retry() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await Future<void>.sync(widget.onPressed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: _isLoading ? null : _retry,
    icon: _isLoading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.statusUrgentText,
            ),
          )
        : const Icon(
            Icons.refresh,
            size: 16,
            color: AppColors.statusUrgentText,
          ),
    label: const Text(
      'Retry',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.statusUrgentText,
      ),
    ),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      minimumSize: const Size(
        AppSpacing.minTouchTarget,
        AppSpacing.minTouchTarget,
      ),
      tapTargetSize: MaterialTapTargetSize.padded,
    ),
  );
}
