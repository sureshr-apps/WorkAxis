import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// A labelled action in an [AccountCardActions] row.
class AccountCardAction {
  const AccountCardAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final Color color;

  /// Null disables the action.
  final VoidCallback? onPressed;

  /// Explains the action, for example why a disabled one is unavailable.
  final String? tooltip;
}

/// Labelled actions for the footer of an account card. Spread evenly by
/// default; pass [alignment] to pack them to one side.
class AccountCardActions extends StatelessWidget {
  const AccountCardActions({
    super.key,
    required this.actions,
    this.alignment = WrapAlignment.spaceEvenly,
  });

  final List<AccountCardAction> actions;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: alignment,
    runSpacing: AppSpacing.xs,
    children: [for (final action in actions) _LabelledAction(action: action)],
  );
}

class _LabelledAction extends StatelessWidget {
  const _LabelledAction({required this.action});

  final AccountCardAction action;

  @override
  Widget build(BuildContext context) {
    final button = TextButton.icon(
      onPressed: action.onPressed,
      icon: Icon(action.icon, size: 18, color: action.color),
      label: Text(
        action.label,
        style: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: action.color,
        ),
      ),
      style: TextButton.styleFrom(
        minimumSize: const Size.square(AppSpacing.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
    );
    final tooltip = action.tooltip;
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
