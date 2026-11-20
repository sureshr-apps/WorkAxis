import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';

/// Icon action that shows progress and rejects repeat taps while its async
/// callback is running.
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
    this.isLoading = false,
    this.constraints,
    this.padding,
  });

  final String tooltip;
  final IconData icon;
  final FutureOr<void> Function()? onPressed;
  final Color? color;
  final bool isLoading;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isActionInProgress = false;

  bool get _isLoading => widget.isLoading || _isActionInProgress;

  void _handlePressed() {
    if (_isLoading) return;
    final action = widget.onPressed;
    if (action == null) return;

    setState(() => _isActionInProgress = true);
    unawaited(
      Future<void>.sync(action).whenComplete(() {
        if (mounted) setState(() => _isActionInProgress = false);
      }),
    );
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: widget.tooltip,
    onPressed: _isLoading || widget.onPressed == null ? null : _handlePressed,
    constraints:
        widget.constraints ??
        const BoxConstraints(
          minWidth: AppSpacing.minTouchTarget,
          minHeight: AppSpacing.minTouchTarget,
        ),
    padding: widget.padding,
    icon: _isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.color,
            ),
          )
        : Icon(widget.icon, size: 20, color: widget.color),
  );
}
