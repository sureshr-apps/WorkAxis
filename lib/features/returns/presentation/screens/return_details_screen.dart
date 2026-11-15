import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/attachment_image.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/return_presentation.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// Reviews a return decision. Returns null on success, or the message to show
/// inline when the decision could not be saved.
typedef ReturnReviewHandler = Future<String?> Function(
  ReturnStatus decision,
  String notes,
);

/// Return request page: the proof, product and decision for one return.
///
/// The page only reports outcomes: [onClose] for back and close, and
/// [onReviewed] after a successful decision. The route decides where to go.
class ReturnDetailsScreen extends StatefulWidget {
  const ReturnDetailsScreen({
    super.key,
    required this.item,
    required this.eyebrow,
    required this.backLabel,
    required this.onClose,
    this.canReview = false,
    this.onReviewDecision,
    this.onReviewed,
  });

  final ReturnItem item;
  final String eyebrow;

  /// Name of the list the page belongs to, shown in the breadcrumb.
  final String backLabel;
  final VoidCallback onClose;
  final bool canReview;
  final ReturnReviewHandler? onReviewDecision;
  final VoidCallback? onReviewed;

  @override
  State<ReturnDetailsScreen> createState() => _ReturnDetailsScreenState();
}

class _ReturnDetailsScreenState extends State<ReturnDetailsScreen> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleDecision(ReturnStatus decision) async {
    final handler = widget.onReviewDecision;
    if (handler == null) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    String? error;
    try {
      error = await handler(decision, _notesController.text.trim());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = error;
        });
      }
    }
    if (error == null && mounted) widget.onReviewed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isPending = item.status == ReturnStatus.pending;
    final showReviewActions = widget.canReview && isPending;

    // No leaving (system back, browser back) while a decision is in flight.
    return PopScope(
      canPop: !_isSubmitting,
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
                      backLabel: widget.backLabel,
                      currentLabel: 'Return #${item.id}',
                      onBack: widget.onClose,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPageHeader(
                      eyebrow: widget.eyebrow,
                      title: 'Return Details',
                      subtitle: 'Proof of purchase, quantity, reason and decision for this return.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DashboardSurfaceCard(
                      // Text fields need a Material ancestor inside the card's box.
                      child: Material(
                        type: MaterialType.transparency,
                        child: _buildContent(
                          item,
                          isPending,
                          showReviewActions,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildFooter(showReviewActions),
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

  Widget _buildContent(
    ReturnItem item,
    bool isPending,
    bool showReviewActions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null) ...[
          ErrorBanner(message: _errorMessage!),
          const SizedBox(height: AppSpacing.md),
        ],
        _Header(item: item),
        const SizedBox(height: AppSpacing.lg),
        const Divider(height: 1, thickness: 1, color: AppColors.outlineSubtle),
        const SizedBox(height: AppSpacing.md),
        _ProductBlock(item: item),
        const SizedBox(height: AppSpacing.md),
        if (item.remarks != null && item.remarks!.isNotEmpty) ...[
          const _SectionLabel('Condition Remarks'),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.outlineSubtle),
            ),
            child: Text(item.remarks!, style: AppTypography.bodyMedium),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const _SectionLabel('Proof Photo / Bill Attachment'),
        const SizedBox(height: AppSpacing.xs),
        _BillAttachmentTile(imageUrl: item.billImageUrl),
        const SizedBox(height: AppSpacing.md),
        if (!isPending && item.reviewedBy != null) ...[
          _DecisionSummary(item: item),
          const SizedBox(height: AppSpacing.md),
        ],
        if (showReviewActions) ...[
          const _SectionLabel('Reviewer Decision Remarks'),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            controller: _notesController,
            maxLines: 2,
            hintText: 'Enter reason or credit approval notes...',
          ),
        ],
      ],
    );
  }

  /// The breadcrumb is the way back, so a page without review actions has no
  /// footer.
  Widget _buildFooter(bool showReviewActions) {
    if (!showReviewActions) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        AppButton.outlined(
          text: 'Reject Request',
          isFullWidth: false,
          isLoading: _isSubmitting,
          onPressed: () => _handleDecision(ReturnStatus.rejected),
        ),
        AppButton.primary(
          text: 'Approve Return',
          isFullWidth: false,
          isLoading: _isSubmitting,
          onPressed: () => _handleDecision(ReturnStatus.approved),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.item});

  final ReturnItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Return Request #${item.id}',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${item.branchName} · Submitted by ${item.employeeName}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusChip(label: item.status.label, type: item.status.chipType),
      ],
    );
  }
}

class _ProductBlock extends StatelessWidget {
  const _ProductBlock({required this.item});

  final ReturnItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productTitle,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            children: [
              _DetailItem(
                icon: Icons.scale_outlined,
                label: 'Quantity',
                value: item.quantityLabel,
              ),
              _DetailItem(
                icon: item.reason.icon,
                label: 'Return Reason',
                value: item.reason.displayName,
              ),
              _DetailItem(
                icon: Icons.receipt_outlined,
                label: 'Bill Number',
                value: item.billNumber != null && item.billNumber!.isNotEmpty
                    ? item.billNumber!
                    : item.invoiceNumber,
              ),
              _DetailItem(
                icon: Icons.tag_rounded,
                label: 'Invoice Number',
                value: item.invoiceNumber,
              ),
              _DetailItem(
                icon: Icons.event_note_rounded,
                label: 'Return Date',
                value: AppFormatters.formatDate(item.returnDate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
  );
}

/// Renders either an interactive photo preview or empty state.
class _BillAttachmentTile extends StatelessWidget {
  const _BillAttachmentTile({required this.imageUrl});

  final String? imageUrl;

  void _openZoom(BuildContext context, String path) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: _buildImage(path),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildImage(String path) =>
      AttachmentImage(reference: path, fit: BoxFit.contain, iconSize: 48);

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    if (!hasImage) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.kpiNeutralBackground,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: AppColors.outlineSubtle),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'No proof photo was attached to this return request.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _openZoom(context, imageUrl!),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                width: 72,
                height: 72,
                color: AppColors.surfaceContainerLow,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(imageUrl!),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.zoom_in,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.statusActive,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Proof Photo Verified',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.statusActive,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap preview to view full resolution image',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppButton.outlined(
            text: 'View Full',
            isFullWidth: false,
            onPressed: () => _openZoom(context, imageUrl!),
          ),
        ],
      ),
    );
  }
}

class _DecisionSummary extends StatelessWidget {
  const _DecisionSummary({required this.item});

  final ReturnItem item;

  @override
  Widget build(BuildContext context) {
    final approved = item.status == ReturnStatus.approved;
    final foreground = approved
        ? AppColors.statusActiveText
        : AppColors.statusUrgentText;
    final reviewedAt = item.reviewedAt;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: approved
            ? AppColors.statusActiveContainer
            : AppColors.statusUrgentContainer,
        borderRadius: AppSpacing.roundedMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                approved ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 18,
                color: foreground,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  reviewedAt == null
                      ? 'Decision by ${item.reviewedBy}'
                      : 'Decision by ${item.reviewedBy} · ${AppFormatters.formatDateTime(reviewedAt)}',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
          if (item.reviewerNotes != null && item.reviewerNotes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.reviewerNotes!,
              style: AppTypography.bodySmall.copyWith(color: foreground),
            ),
          ],
        ],
      ),
    );
  }
}
