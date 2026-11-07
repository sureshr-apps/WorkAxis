import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';

/// Avatar menu offering the signed-in user's identity and Sign Out.
///
/// [userName] and [roleLabel] are null until the access context resolves; the
/// menu then offers only Sign Out rather than showing a placeholder identity.
class UserProfileMenu extends StatelessWidget {
  const UserProfileMenu({
    super.key,
    required this.onSignOut,
    this.userName,
    this.roleLabel,
    this.showNameAndRole = false,
  });

  final String? userName;
  final String? roleLabel;
  final bool showNameAndRole;
  final VoidCallback onSignOut;

  bool get _hasName => userName != null && userName!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'User Profile & Actions',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedSm,
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      onSelected: (value) {
        if (value == 'sign_out') onSignOut();
      },
      itemBuilder: (context) => [
        if (_hasName) ...[
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName!,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.onSurface,
                  ),
                ),
                if (roleLabel != null)
                  Text(
                    roleLabel!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.secondary,
                    ),
                  ),
              ],
            ),
          ),
          const PopupMenuDivider(),
        ],
        PopupMenuItem<String>(
          value: 'sign_out',
          child: Row(
            children: [
              const Icon(
                Icons.logout,
                size: 18,
                color: AppColors.statusUrgentText,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Sign Out',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.statusUrgentText,
                ),
              ),
            ],
          ),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.minTouchTarget,
          minWidth: AppSpacing.minTouchTarget,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showNameAndRole && _hasName) ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        userName!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (roleLabel != null)
                        Text(
                          roleLabel!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondary,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
              ],
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primaryDark,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
