import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// One contact line on an [AccountCard], such as email, phone or last login.
class AccountCardDetail {
  const AccountCardDetail({required this.icon, required this.value});

  final IconData icon;
  final String value;
}

/// Card for one user account, shared by the organization and platform
/// administrator lists.
///
/// Layout: an identity header (initials, name, username and status chip), a
/// divider, the contact lines, then a footer (usually `AccountCardActions`)
/// set off by a full-width divider. When [onTap] is given, the header and
/// contact area is tappable; the footer keeps its own controls.
class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    this.initials,
    this.avatar,
    required this.name,
    required this.username,
    required this.statusChip,
    required this.details,
    this.footer,
    this.onTap,
    this.onTapLabel,
  }) : assert(
         initials != null || avatar != null,
         'Give initials or an avatar.',
       );

  /// Initials for the default avatar. Ignored when [avatar] is given.
  final String? initials;

  /// Custom avatar, such as a member photo, in place of the initials.
  final Widget? avatar;
  final String name;
  final String username;
  final Widget statusChip;
  final List<AccountCardDetail> details;

  /// Actions along the foot of the card. Null leaves the footer out.
  final Widget? footer;

  /// Opens the account (for example its details page). Null makes the card
  /// static.
  final VoidCallback? onTap;

  /// Accessible name announced for the tappable area.
  final String? onTapLabel;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              avatar ?? _CardAvatar(initials: initials!),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMono.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              statusChip,
            ],
          ),
          const Divider(height: AppSpacing.xl),
          for (final (index, detail) in details.indexed) ...[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            _DetailLine(detail: detail),
          ],
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineSubtle),
        borderRadius: AppSpacing.roundedMd,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onTap == null)
            body
          else
            Semantics(
              button: true,
              label: onTapLabel,
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: body,
              ),
            ),
          if (footer != null) ...[
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.outlineSubtle,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: footer,
            ),
          ],
        ],
      ),
    );
  }
}

/// Larger mint avatar used on the card header.
class _CardAvatar extends StatelessWidget {
  const _CardAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.onTertiaryContainer.withValues(alpha: 0.35),
      shape: BoxShape.circle,
      border: Border.all(
        color: AppColors.onTertiaryContainer.withValues(alpha: 0.7),
      ),
    ),
    child: Text(
      initials,
      style: AppTypography.labelMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.tertiary,
      ),
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.detail});

  final AccountCardDetail detail;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(detail.icon, size: 18, color: AppColors.secondary),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          detail.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface),
        ),
      ),
    ],
  );
}
