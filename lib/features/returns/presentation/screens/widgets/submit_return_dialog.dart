import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/return_presentation.dart';

/// Submits a return. Returns null on success, or the message to show inline
/// when the request could not be saved.
typedef ReturnSubmitHandler = Future<String?> Function(CreateReturnInput input);

class SubmitReturnDialog extends StatefulWidget {
  final ReturnSubmitHandler onSubmit;

  const SubmitReturnDialog({super.key, required this.onSubmit});

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
  bool _isSubmitting = false;
  String? _submitError;

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
    } else if (double.parse(quantityStr) <= 0) {
      qErr = 'Must be greater than zero';
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
      // No upload pipeline yet: never send a placeholder URL to the backend.
      billImageUrl: null,
      remarks: _remarksController.text.trim(),
    );

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    String? error;
    try {
      error = await widget.onSubmit(input);
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
      backgroundColor: AppColors.surfaceContainerLowest,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
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
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.outlineSubtle,
              ),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'units',
                              child: Text('Units'),
                            ),
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(
                              value: 'boxes',
                              child: Text('Boxes'),
                            ),
                            DropdownMenuItem(
                              value: 'liters',
                              child: Text('Liters'),
                            ),
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

              // Bill capture has no upload pipeline yet, so say so instead
              // of pretending a file was attached.
              Text(
                'Bill Image',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: AppColors.outlineSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Bill photo upload is coming soon. Enter the invoice number above for now.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
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
                    text: 'Submit Return',
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
