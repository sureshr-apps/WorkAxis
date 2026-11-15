import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_date_picker_field.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/form_action_row.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_image_picker.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_item_draft.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_line_item_card.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// Multi-item return batch handler. Returns null on success, or the message to
/// show inline when the batch could not be submitted.
typedef ReturnBatchSubmitHandler = Future<String?> Function(
  CreateReturnBatchInput input,
);

/// Record-return page: one bill with the items returned from it.
///
/// The page only reports outcomes: [onClose] for back and cancel, and
/// [onSaved] after a successful submit. The route decides where to go next.
class SubmitReturnScreen extends StatefulWidget {
  const SubmitReturnScreen({
    super.key,
    required this.eyebrow,
    required this.backLabel,
    required this.availableBranches,
    required this.onSubmitBatch,
    required this.onClose,
    required this.onSaved,
    this.initialBranchId,
  });

  final String eyebrow;

  /// Name of the list the page belongs to, shown in the breadcrumb.
  final String backLabel;
  final List<BranchSummary> availableBranches;
  final String? initialBranchId;
  final ReturnBatchSubmitHandler onSubmitBatch;
  final VoidCallback onClose;
  final VoidCallback onSaved;

  @override
  State<SubmitReturnScreen> createState() => _SubmitReturnScreenState();
}

class _SubmitReturnScreenState extends State<SubmitReturnScreen> {
  final _invoiceController = TextEditingController();
  final _billController = TextEditingController();
  final _generalRemarksController = TextEditingController();

  final List<ReturnItemDraft> _items = [];

  String? _invoiceError;
  DateTime _returnDate = DateTime.now();
  String? _selectedBranchId;
  String? _imagePath;
  bool _isSubmitting = false;
  String? _submitError;

  static final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    // The dropdown asserts when its initial value is not one of its items, so
    // only honour initialBranchId when it is actually selectable.
    final initialIsSelectable = widget.availableBranches.any(
      (b) => b.id == widget.initialBranchId,
    );
    _selectedBranchId = initialIsSelectable
        ? widget.initialBranchId
        : (widget.availableBranches.isNotEmpty
              ? widget.availableBranches.first.id
              : null);
    // Initialize with 1 item row
    _items.add(ReturnItemDraft());
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _billController.dispose();
    _generalRemarksController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(
        ReturnItemDraft(
          unit: _items.isNotEmpty ? _items.last.unit : 'kg',
          reason: ReturnReason.damaged,
        ),
      );
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _pickReturnDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      helpText: 'SELECT RETURN DATE',
    );
    if (picked != null && mounted) {
      setState(() => _returnDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    var invoice = _invoiceController.text.trim();
    var bill = _billController.text.trim();
    String? iErr;

    if (invoice.isEmpty) {
      if (bill.isNotEmpty) {
        invoice = bill;
        _invoiceController.text = bill;
      } else {
        iErr = 'Invoice or Bill number is required';
      }
    }
    if (bill.isEmpty && invoice.isNotEmpty) {
      bill = invoice;
      _billController.text = invoice;
    }

    bool hasItemErrors = false;
    for (final item in _items) {
      final product = item.productController.text.trim();
      final quantityStr = item.quantityController.text.trim();
      String? pErr, qErr;

      if (product.isEmpty) {
        pErr = 'Product name is required';
        hasItemErrors = true;
      }
      if (quantityStr.isEmpty) {
        qErr = 'Required';
        hasItemErrors = true;
      } else {
        final val = double.tryParse(quantityStr);
        if (val == null || !val.isFinite) {
          qErr = 'Invalid';
          hasItemErrors = true;
        } else if (val <= 0) {
          qErr = 'Must be > 0';
          hasItemErrors = true;
        }
      }
      item.productError = pErr;
      item.quantityError = qErr;
    }

    setState(() {
      _invoiceError = iErr;
    });

    if (iErr != null || hasItemErrors) return;

    final selectedBranch = widget.availableBranches
        .where((b) => b.id == _selectedBranchId)
        .firstOrNull;

    final batchInput = CreateReturnBatchInput(
      branchId: _selectedBranchId,
      branchName: selectedBranch?.name,
      billNumber: bill.isEmpty ? null : bill,
      invoiceNumber: invoice,
      returnDate: _returnDate,
      billImageUrl: _imagePath,
      remarks: _generalRemarksController.text.trim().isEmpty
          ? null
          : _generalRemarksController.text.trim(),
      items: _items.map((item) {
        return ReturnLineItemInput(
          productTitle: item.productController.text.trim(),
          quantity: double.tryParse(item.quantityController.text.trim()) ?? 1.0,
          unit: item.unit,
          reason: item.reason,
          remarks: item.remarksController.text.trim().isEmpty
              ? null
              : item.remarksController.text.trim(),
        );
      }).toList(),
    );

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    String? error;
    try {
      error = await widget.onSubmitBatch(batchInput);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitError = error;
        });
      }
    }
    if (error == null && mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = _items.length;
    final footer = FormActionRow(
      submitLabel: itemCount == 1
          ? 'Submit Return'
          : 'Submit Return ($itemCount items)',
      onCancel: widget.onClose,
      onSubmit: _isSubmitting ? null : _handleSubmit,
      isBusy: _isSubmitting,
    );

    // No leaving (system back, browser back) while a submit is in flight.
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
                      currentLabel: 'New return',
                      onBack: widget.onClose,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPageHeader(
                      eyebrow: widget.eyebrow,
                      title: 'Record Return',
                      subtitle: 'Capture bill details and record returned items with reasons.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DashboardSurfaceCard(
                      // Text fields need a Material ancestor inside the card's box.
                      child: Material(
                        type: MaterialType.transparency,
                        child: _buildForm(itemCount),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    footer,
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

  Widget _buildForm(int itemCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_submitError != null) ...[
          ErrorBanner(message: _submitError!),
          const SizedBox(height: AppSpacing.md),
        ],

        // 1. Branch Selector (when multiple branches available)
        if (widget.availableBranches.length > 1) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Branch *',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                initialValue: _selectedBranchId,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Select Branch',
                  prefixIcon: Icon(Icons.store_outlined, size: 20),
                ),
                items: widget.availableBranches.map((b) {
                  return DropdownMenuItem(value: b.id, child: Text(b.name));
                }).toList(),
                onChanged: (v) => setState(() => _selectedBranchId = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 2. Bill Number & Invoice Number Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: _billController,
                label: 'Bill Number *',
                hintText: 'e.g. BILL-4092',
                prefixIcon: const Icon(Icons.receipt_outlined, size: 20),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                controller: _invoiceController,
                label: 'Invoice Number *',
                hintText: 'e.g. INV-2026-8812',
                prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                errorText: _invoiceError,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // 3. Return Date Picker
        AppDatePickerField(
          label: 'Return Date *',
          valueText: _dateFormat.format(_returnDate),
          hintText: 'Select Date',
          prefixIcon: const Icon(Icons.event_note_rounded, size: 20),
          onTap: _pickReturnDate,
        ),
        const SizedBox(height: AppSpacing.md),

        // 4. Bill Photo Upload
        ReturnImagePicker(
          imagePath: _imagePath,
          onImageChanged: (path) => setState(() => _imagePath = path),
          label: 'Bill / Receipt Photo (Showing Purchased Items)',
        ),
        const SizedBox(height: AppSpacing.xl),

        // 5. Items Being Returned Section Header
        Row(
          children: [
            Text(
              'Items to Return',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Add each product being returned from this bill along with its quantity and reason.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 6. List of Return Item Cards
        ...List.generate(_items.length, (index) {
          final item = _items[index];
          return ReturnLineItemCard(
            key: ValueKey(item),
            index: index,
            totalItems: _items.length,
            item: item,
            onRemove: () => _removeItem(index),
            onChanged: () => setState(() {}),
          );
        }),

        const SizedBox(height: AppSpacing.xs),

        // Add Another Item Button
        OutlinedButton.icon(
          onPressed: _addItem,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          icon: const Icon(Icons.add_circle_outline, size: 20),
          label: Text(
            itemCount == 1
                ? '+ Add Another Item from this Bill'
                : '+ Add Another Item',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // 7. General Bill-Level Remarks (Optional)
        AppTextField(
          controller: _generalRemarksController,
          label: 'General Remarks / Notes (Optional)',
          hintText:
              'Overall notes, customer circumstances, or manager remarks...',
          minLines: 2,
          maxLines: 4,
          prefixIcon: const Icon(Icons.notes_rounded, size: 20),
        ),
      ],
    );
  }
}
