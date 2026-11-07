import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

enum OrganizationDetailsTab {
  overview('Overview', Icons.apartment_outlined),
  administrators('Administrators', Icons.people_outline),
  license('License', Icons.vpn_key_outlined);

  const OrganizationDetailsTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Horizontally scrollable tab strip for the organization details screen.
class OrganizationDetailsTabBar extends StatelessWidget {
  const OrganizationDetailsTabBar({
    super.key,
    required this.selected,
    required this.administratorCount,
    required this.onChanged,
  });

  final OrganizationDetailsTab selected;
  final int administratorCount;
  final ValueChanged<OrganizationDetailsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineSubtle)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in OrganizationDetailsTab.values)
              _TabButton(
                tab: tab,
                count: tab == OrganizationDetailsTab.administrators
                    ? administratorCount
                    : null,
                selected: selected == tab,
                onPressed: () => onChanged(tab),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.count,
    required this.selected,
    required this.onPressed,
  });

  final OrganizationDetailsTab tab;
  final int? count;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.tertiary : AppColors.secondary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.tertiary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tab.icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(
                tab.label,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.tertiaryContainer.withValues(alpha: 0.12)
                        : AppColors.surfaceContainerHigh,
                    borderRadius: AppSpacing.roundedPill,
                  ),
                  child: Text(
                    '$count',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
