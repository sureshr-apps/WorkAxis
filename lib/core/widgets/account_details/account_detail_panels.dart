import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/widgets/access_panel.dart';

/// A titled panel of label and value pairs, such as a profile or account
/// activity section of a details page.
class AccountDetailsPanel extends StatelessWidget {
  const AccountDetailsPanel({
    super.key,
    required this.title,
    required this.values,
  });

  final String title;
  final List<(String, String)> values;

  @override
  Widget build(BuildContext context) {
    return AccessPanel(
      title: title,
      child: AccountDetailGrid(values: values),
    );
  }
}

/// Label/value pairs laid out in one or two columns by available width.
class AccountDetailGrid extends StatelessWidget {
  const AccountDetailGrid({super.key, required this.values});

  final List<(String, String)> values;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.lg;
        final twoColumns = constraints.maxWidth >= AppBreakpoints.formSplit;
        final width = twoColumns
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: AppSpacing.lg,
          children: [
            for (final (label, value) in values)
              SizedBox(
                width: width,
                child: _AccountDetailValue(label: label, value: value),
              ),
          ],
        );
      },
    );
  }
}

class _AccountDetailValue extends StatelessWidget {
  const _AccountDetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SelectableText(value, style: AppTypography.bodyMedium),
      ],
    );
  }
}
