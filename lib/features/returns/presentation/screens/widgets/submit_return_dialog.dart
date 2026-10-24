import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';

class SubmitReturnDialog extends StatefulWidget {
  final Future<bool> Function(CreateReturnInput input) onSubmit;

  const SubmitReturnDialog({
    super.key,
    required this.onSubmit,
  });

  @override
  State<SubmitReturnDialog> createState() => _SubmitReturnDialogState();
}

class _SubmitReturnDialogState extends State<SubmitReturnDialog> {
  final _productController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _invoiceController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _productError;
  String? _quantityError;
  String? _invoiceError;

  ReturnReason _selectedReason = ReturnReason.damaged;
  String _selectedUnit = 'units';
  bool _hasAttachedBill = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _invoiceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final product = _productController.text.trim();
    final quantityStr = _quantityController.text.trim();
    final invoice = _invoiceController.text.trim();

    String? pErr, qErr, iErr;
    if (product.isEmpty) pErr = 'Product name is required';
    if (quantityStr.isEmpty) {
      qErr = 'Required';
    } else if (double.tryParse(quantityStr) == null) {
      qErr = 'Invalid number';
    }
    if (invoice.isEmpty) iErr = 'Invoice number is required';

    setState(() {
      _productError = pErr;
      _quantityError = qErr;
      _invoiceError = iErr;
    });

    if (pErr != null || qErr != null || iErr != null) return;

    final quantity = double.tryParse(quantityStr) ?? 1.0;
    final input = CreateReturnInput(
      productTitle: product,
      reason: _selectedReason,
      quantity: quantity,
      unit: _selectedUnit,
      invoiceNumber: invoice,
      billImageUrl: _hasAttachedBill ? 'mock_bill_scan.jpg' : null,
      remarks: _remarksController.text.trim(),
    );

    setState(() => _isSubmitting = true);
    try {
      final success = await widget.onSubmit(input);
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      backgroundColor: AppColors.surfaceContainerLowest,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
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
                          'Submit Return Request',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Attach bill and return item details for manager verification',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1, thickness: 1, color: AppColors.outlineSubtle),
              const SizedBox(height: AppSpacing.lg),

              // Product Title
              AppTextField(
                controller: _productController,
                label: 'Product / Item Name *',
                hintText: 'e.g. Organic Fuji Apples (Batch #FA-902)',
                errorText: _productError,
              ),
              const SizedBox(height: AppSpacing.md),

              // Reason Dropdown
              Text(
                'Return Reason *',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<ReturnReason>(
                initialValue: _selectedReason,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: ReturnReason.values.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Row(
                      children: [
                        Icon(reason.icon, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(reason.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedReason = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Quantity and Unit Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      controller: _quantityController,
                      label: 'Quantity *',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      errorText: _quantityError,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unit',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedUnit,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'units', child: Text('Units')),
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'boxes', child: Text('Boxes')),
                            DropdownMenuItem(value: 'liters', child: Text('Liters')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedUnit = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Invoice / Bill Number
              AppTextField(
                controller: _invoiceController,
                label: 'Invoice / Bill Reference Number *',
                hintText: 'e.g. INV-2026-8812',
                errorText: _invoiceError,
              ),
              const SizedBox(height: AppSpacing.md),

              // Attached bill scan mockup
              Text(
                'Attached Bill Image *',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  setState(() => _hasAttachedBill = !_hasAttachedBill);
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _hasAttachedBill
                        ? AppColors.statusActiveContainer.withValues(alpha: 0.4)
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: _hasAttachedBill
                          ? AppColors.statusActive
                          : AppColors.outlineSubtle,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hasAttachedBill
                            ? Icons.check_circle_outline
                            : Icons.add_photo_alternate_outlined,
                        color: _hasAttachedBill
                            ? AppColors.statusActiveText
                            : AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _hasAttachedBill
                                  ? 'Bill Receipt Attached (bill_scan_8812.jpg)'
                                  : 'Tap to attach bill or receipt image',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _hasAttachedBill
                                    ? AppColors.statusActiveText
                                    : AppColors.onSurface,
                              ),
                            ),
                            Text(
                              _hasAttachedBill
                                  ? 'OCR verified: matching vendor invoice number'
                                  : 'Supports JPG, PNG, PDF up to 5MB',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Remarks
              AppTextField(
                controller: _remarksController,
                label: 'Condition Remarks (Optional)',
                hintText: 'Describe defects, temperature variations, or customer explanation...',
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: 'Cancel',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  AppButton(
                    text: 'Submit Return',
                    variant: AppButtonVariant.primary,
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
