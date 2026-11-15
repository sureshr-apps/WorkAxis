import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_date_picker_field.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/return_presentation.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_image_picker.dart';

/// Legacy single-item return handler.
typedef ReturnSubmitHandler = Future<String?> Function(CreateReturnInput input);

/// Multi-item return batch handler.
typedef ReturnBatchSubmitHandler = Future<String?> Function(
  CreateReturnBatchInput input,
);

/// Interactive draft model for an individual item row being returned from a bill.
class _ReturnItemDraft {
  final TextEditingController productController;
  final TextEditingController quantityController;
  final TextEditingController remarksController;
  ReturnReason reason;
  String unit;
  String? productError;
  String? quantityError;

  _ReturnItemDraft({
    String product = '',
    String quantity = '1',
    this.reason = ReturnReason.damaged,
    this.unit = 'kg',
    String remarks = '',
  }) : productController = TextEditingController(text: product),
       quantityController = TextEditingController(text: quantity),
       remarksController = TextEditingController(text: remarks);

  void dispose() {
    productController.dispose();
    quantityController.dispose();
    remarksController.dispose();
  }
}

class SubmitReturnDialog extends StatefulWidget {
  final ReturnSubmitHandler? onSubmit;
  final ReturnBatchSubmitHandler? onSubmitBatch;
  final List<BranchSummary> availableBranches;
  final String? initialBranchId;

  const SubmitReturnDialog({
    super.key,
    this.onSubmit,
    this.onSubmitBatch,
    this.availableBranches = const [],
    this.initialBranchId,
  }) : assert(
         onSubmit != null || onSubmitBatch != null,
         'Either onSubmit or onSubmitBatch must be provided',
       );

  @override
  State<SubmitReturnDialog> createState() => _SubmitReturnDialogState();
}

class _SubmitReturnDialogState extends State<SubmitReturnDialog> {
  final _invoiceController = TextEditingController();
  final _billController = TextEditingController();
  final _generalRemarksController = TextEditingController();

  final List<_ReturnItemDraft> _items = [];

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
    _items.add(_ReturnItemDraft());
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
        _ReturnItemDraft(
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
      if (widget.onSubmitBatch != null) {
        error = await widget.onSubmitBatch!(batchInput);
      } else if (widget.onSubmit != null) {
        final singleInputs = batchInput.toCreateReturnInputs();
        for (final single in singleInputs) {
          error = await widget.onSubmit!(single);
          if (error != null) break;
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitError = error;
        });
      }
    }
    if (error == null && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = _items.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
      backgroundColor: AppColors.surfaceContainerLowest,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      Icons.assignment_return_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record Return',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Capture bill details and record returned items with reasons.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.outlineSubtle,
              ),
              const SizedBox(height: AppSpacing.lg),

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
                        return DropdownMenuItem(
                          value: b.id,
                          child: Text(b.name),
                        );
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
                return _ReturnLineItemCard(
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
                hintText: 'Overall notes, customer circumstances, or manager remarks...',
                minLines: 2,
                maxLines: 4,
                prefixIcon: const Icon(Icons.notes_rounded, size: 20),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (_submitError != null) ...[
                ErrorBanner(message: _submitError!),
                const SizedBox(height: AppSpacing.md),
              ],

              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton.outlined(
                    text: 'Cancel',
                    isFullWidth: false,
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                  AppButton.primary(
                    text: itemCount == 1
                        ? 'Submit Return'
                        : 'Submit Return ($itemCount items)',
                    isFullWidth: false,
                    isLoading: _isSubmitting,
                    onPressed: _handleSubmit,
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

/// Dedicated card for an individual line item in the return form.
class _ReturnLineItemCard extends StatelessWidget {
  final int index;
  final int totalItems;
  final _ReturnItemDraft item;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ReturnLineItemCard({
    super.key,
    required this.index,
    required this.totalItems,
    required this.item,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Item Card Header Row
          Row(
            children: [
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
                  'Item #${index + 1}',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (totalItems > 1)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.statusUrgentText,
                    size: 20,
                  ),
                  tooltip: 'Remove Item #${index + 1}',
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Product Name
          AppTextField(
            controller: item.productController,
            label: 'Product Name *',
            hintText: 'e.g. Kashmiri Apples (Batch #FA-902), Robusta Bananas',
            prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
            errorText: item.productError,
          ),
          const SizedBox(height: AppSpacing.md),

          // Quantity & Unit Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AppTextField(
                  controller: item.quantityController,
                  label: 'Quantity *',
                  hintText: 'e.g. 5.5',
                  prefixIcon: const Icon(Icons.scale_outlined, size: 20),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  errorText: item.quantityError,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unit',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<String>(
                      initialValue: item.unit,
                      isExpanded: true,
                      decoration: const InputDecoration(hintText: 'Unit'),
                      items: const [
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(
                          value: 'units',
                          child: Text('Units / Pcs'),
                        ),
                        DropdownMenuItem(value: 'boxes', child: Text('Boxes')),
                        DropdownMenuItem(
                          value: 'crates',
                          child: Text('Crates'),
                        ),
                        DropdownMenuItem(
                          value: 'liters',
                          child: Text('Liters'),
                        ),
                        DropdownMenuItem(
                          value: 'dozens',
                          child: Text('Dozens'),
                        ),
                        DropdownMenuItem(
                          value: 'packets',
                          child: Text('Packets'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          item.unit = v;
                          onChanged();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Return Reason Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Return Reason *',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<ReturnReason>(
                initialValue: item.reason,
                isExpanded: true,
                decoration: const InputDecoration(hintText: 'Select Reason'),
                items: ReturnReason.values.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Row(
                      children: [
                        Icon(reason.icon, size: 18, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(reason.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    item.reason = v;
                    onChanged();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Item-Specific Remarks (Optional)
          AppTextField(
            controller: item.remarksController,
            label: 'Item Remarks (Optional)',
            hintText: 'e.g. 2 pieces rotten in bottom layer...',
            prefixIcon: const Icon(Icons.comment_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}
