import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_card_item.dart';

/// Sliver of organization cards: one column, or [columns] equal-height
/// columns on tablets. Rows are built lazily.
class OrganizationCardList extends StatelessWidget {
  const OrganizationCardList({
    super.key,
    required this.organizations,
    required this.columns,
    required this.onSelect,
    required this.onEdit,
  });

  final List<CustomerOrganization> organizations;
  final int columns;
  final ValueChanged<CustomerOrganization> onSelect;
  final ValueChanged<CustomerOrganization> onEdit;

  @override
  Widget build(BuildContext context) {
    final rowCount = (organizations.length / columns).ceil();
    return SliverList.separated(
      itemCount: rowCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, row) {
        Widget cardAt(int index) => OrganizationCardItem(
          organization: organizations[index],
          onTap: () => onSelect(organizations[index]),
          onEdit: () => onEdit(organizations[index]),
        );
        if (columns == 1) return cardAt(row);

        final cells = <Widget>[];
        for (var col = 0; col < columns; col++) {
          final index = row * columns + col;
          if (col > 0) cells.add(const SizedBox(width: AppSpacing.md));
          cells.add(
            Expanded(
              child: index < organizations.length
                  ? cardAt(index)
                  : const SizedBox.shrink(),
            ),
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        );
      },
    );
  }
}
