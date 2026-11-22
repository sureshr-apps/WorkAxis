import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/attachment_image.dart';

/// Avatar menu offering the signed-in user's identity and optional Sign Out.
///
/// [userName] and [roleLabel] are null until the access context resolves; the
/// menu does not show a placeholder identity. Compact layouts keep Sign Out in
/// this menu; expanded layouts provide it at the bottom of the sidebar.
class UserProfileMenu extends StatefulWidget {
  const UserProfileMenu({
    super.key,
    required this.onSignOut,
    this.userName,
    this.roleLabel,
    this.profilePhotoUrl,
    this.showNameAndRole = false,
    this.showSignOut = true,
  });

  final String? userName;
  final String? roleLabel;
  final String? profilePhotoUrl;
  final bool showNameAndRole;
  final bool showSignOut;
  final FutureOr<void> Function() onSignOut;

  @override
  State<UserProfileMenu> createState() => _UserProfileMenuState();
}

class _UserProfileMenuState extends State<UserProfileMenu> {
  bool _isSigningOut = false;

  String? get _displayName {
    final name = widget.userName?.trim();
    if (name == null || name.isEmpty) return null;

    final role = widget.roleLabel?.trim();
    if (role != null &&
        role.isNotEmpty &&
        name.toLowerCase() == role.toLowerCase()) {
      return role;
    }
    return name;
  }

  String? get _displayRole {
    final role = widget.roleLabel?.trim();
    if (role == null || role.isEmpty) return null;

    return _displayName?.toLowerCase() == role.toLowerCase() ? null : role;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName;
    final displayRole = _displayRole;
    final photoReference = widget.profilePhotoUrl?.trim();
    final avatar = ConstrainedBox(
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
            if (widget.showNameAndRole && displayName != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (displayRole != null)
                      Text(
                        displayRole,
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
              child: _isSigningOut
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : photoReference == null || photoReference.isEmpty
                  ? const Center(
                      child: Icon(Icons.person, size: 18, color: Colors.white),
                    )
                  : ClipOval(
                      child: AttachmentImage(
                        reference: photoReference,
                        fit: BoxFit.cover,
                        iconSize: 18,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );

    if (!widget.showSignOut && displayName == null) {
      return Tooltip(message: 'User Profile & Actions', child: avatar);
    }

    return PopupMenuButton<String>(
      tooltip: 'User Profile & Actions',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedSm,
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      onSelected: _onSelected,
      itemBuilder: (context) => [
        if (displayName != null) ...[
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.onSurface,
                  ),
                ),
                if (displayRole != null)
                  Text(
                    displayRole,
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
        if (widget.showSignOut)
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
      child: avatar,
    );
  }

  void _onSelected(String value) {
    if (value == 'sign_out') unawaited(_signOut());
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await Future<void>.sync(widget.onSignOut);
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }
}
