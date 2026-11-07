import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/shell/nav_destination.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';

/// Visual density of a [NavTile].
enum NavTileDensity {
  /// Persistent sidebar on expanded layouts.
  sidebar,

  /// Drawer on compact/medium layouts (larger icon, selection dot).
  drawer,
}

/// One navigation entry shared by the sidebar and the drawer.
///
/// The selected state is exposed to assistive technology, not only through
/// color, and the tile always meets the 48dp minimum touch target.
class NavTile extends StatelessWidget {
  const NavTile({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.onTap,
    this.density = NavTileDensity.sidebar,
  });

  final AppNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;
  final NavTileDensity density;

  @override
  Widget build(BuildContext context) {
    final isDrawer = density == NavTileDensity.drawer;
    final foreground = isSelected
        ? AppColors.onPrimaryContainer
        : AppColors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: destination.label,
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: AppSpacing.roundedSm,
          child: InkWell(
            borderRadius: AppSpacing.roundedSm,
            hoverColor: AppColors.surfaceContainerLow,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? destination.selectedIcon : destination.icon,
                      size: isDrawer ? 22 : 20,
                      color: foreground,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        destination.label,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.onPrimaryContainer
                              : AppColors.onSurface,
                        ),
                      ),
                    ),
                    if (isDrawer && isSelected)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
