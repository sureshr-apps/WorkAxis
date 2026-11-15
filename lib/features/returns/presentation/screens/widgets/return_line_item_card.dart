import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/return_presentation.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_item_draft.dart';

/// Dedicated card for an individual line item in the return form.
class ReturnLineItemCard extends StatelessWidget {
  final int index;
  final int totalItems;
  final ReturnItemDraft item;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const ReturnLineItemCard({
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
