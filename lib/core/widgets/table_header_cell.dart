import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// Uppercase column header cell shared by the platform tables.
///
/// Sized with [flex] inside a header `Row`, so the header and its data rows
/// can use the same flex values to stay aligned.
class TableHeaderCell extends StatelessWidget {
  const TableHeaderCell(
    this.label, {
    super.key,
    required this.flex,
    this.alignment = Alignment.centerLeft,
  });

  final String label;
  final int flex;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
