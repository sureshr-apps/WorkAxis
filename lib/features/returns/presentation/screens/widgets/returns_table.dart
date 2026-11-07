import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/return_presentation.dart';

/// One column of [SliverReturnsTable].
class ReturnsTableColumn {
  const ReturnsTableColumn({
    required this.title,
    required this.cell,
    this.flex = 1,
    this.width,
    this.alignRight = false,
  });

  final String title;
  final Widget Function(BuildContext context, ReturnItem item) cell;

  /// Relative width when [width] is null.
  final double flex;

  /// Fixed width; overrides [flex].
  final double? width;
  final bool alignRight;

  static ReturnsTableColumn product() => ReturnsTableColumn(
    title: 'Product & Reason',
    flex: 3,
    cell: (context, item) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.productTitle,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          item.reason.label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  static ReturnsTableColumn quantity() => ReturnsTableColumn(
    title: 'Quantity',
    flex: 1.4,
    cell: (context, item) => Text(
      item.quantityLabel,
      style: AppTypography.labelMono.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  static ReturnsTableColumn invoice(String title) => ReturnsTableColumn(
    title: title,
    flex: 1.6,
    cell: (context, item) =>
        Text(item.invoiceNumber, style: AppTypography.labelMono),
  );

  static ReturnsTableColumn employee() => ReturnsTableColumn(
    title: 'Requested By',
    flex: 1.8,
    cell: (context, item) =>
        Text(item.employeeName, style: AppTypography.bodySmall),
  );

  static ReturnsTableColumn branch() => ReturnsTableColumn(
    title: 'Branch',
    flex: 1.8,
    cell: (context, item) =>
        Text(item.branchName, style: AppTypography.bodySmall),
  );

  static ReturnsTableColumn status() => ReturnsTableColumn(
    title: 'Status',
    width: 128,
    cell: (context, item) =>
        StatusChip(label: item.status.label, type: item.status.chipType),
  );

  static ReturnsTableColumn action({
    required void Function(ReturnItem item) onOpen,
    required bool canReview,
  }) => ReturnsTableColumn(
    title: 'Action',
    width: 128,
    alignRight: true,
    cell: (context, item) => AppButton.outlined(
      text: canReview && item.status == ReturnStatus.pending
          ? 'Review'
          : 'Details',
      isFullWidth: false,
      onPressed: () => onOpen(item),
    ),
  );
}

/// Table with a header row and lazily built data rows, for wide layouts.
class SliverReturnsTable extends StatelessWidget {
  const SliverReturnsTable({
    super.key,
    required this.items,
    required this.columns,
  });

  final List<ReturnItem> items;
  final List<ReturnsTableColumn> columns;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _TableRow(
            columns: columns,
            isHeader: true,
            builder: (column) => Text(
              column.title,
              textAlign: column.alignRight ? TextAlign.right : TextAlign.left,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => _TableRow(
            columns: columns,
            isHeader: false,
            builder: (column) => Align(
              alignment: column.alignRight
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: column.cell(context, items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.columns,
    required this.isHeader,
    required this.builder,
  });

  final List<ReturnsTableColumn> columns;
  final bool isHeader;
  final Widget Function(ReturnsTableColumn column) builder;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: AppColors.outlineSubtle);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: isHeader ? AppSpacing.sm : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isHeader
            ? AppColors.surfaceContainerLow
            : AppColors.surfaceContainerLowest,
        border: Border(
          top: isHeader ? side : BorderSide.none,
          left: side,
          right: side,
          bottom: side,
        ),
      ),
      child: Row(
        children: [
          for (final column in columns)
            if (column.width != null)
              SizedBox(
                width: column.width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: builder(column),
                ),
              )
            else
              Expanded(
                flex: (column.flex * 10).round(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: builder(column),
                ),
              ),
        ],
      ),
    );
  }
}
