import 'dart:async';

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
  final FutureOr<void> Function()? onPressed;

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

class _LabelledAction extends StatefulWidget {
  const _LabelledAction({required this.action});

  final AccountCardAction action;

  @override
  State<_LabelledAction> createState() => _LabelledActionState();
}

class _LabelledActionState extends State<_LabelledAction> {
  bool _isLoading = false;

  Future<void> _handlePressed() async {
    if (_isLoading) return;
    final action = widget.action.onPressed;
    if (action == null) return;
    setState(() => _isLoading = true);
    try {
      await Future<void>.sync(action);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final button = TextButton.icon(
      onPressed: _isLoading || action.onPressed == null ? null : _handlePressed,
      icon: _isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: action.color,
              ),
            )
          : Icon(action.icon, size: 18, color: action.color),
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
