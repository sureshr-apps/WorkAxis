import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';

enum AppButtonVariant {
  primary,
  secondaryTonal,
  outlined,

  /// Confirms an irreversible or access-removing action (suspend, revoke).
  destructive,
}

/// Canonical, responsive Material 3 Button template.
///
/// Features:
/// - 48dp minimum touch target adhering to Material 3 accessibility guidelines.
/// - Adaptive sizing: full-width on smartphone, auto/intrinsic-width on tablet and desktop.
/// - Primary, Secondary (Tonal), Outlined, and Destructive variants.
/// - Built-in loading indicator state.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final bool? isFullWidth;
  final bool isAdaptive;

  AppButton({
    super.key,
    String? text,
    String? label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    Widget? icon,
    IconData? iconData,
    this.isFullWidth = true,
    this.isAdaptive = false,
  }) : text = text ?? label ?? '',
       icon = icon ?? (iconData != null ? Icon(iconData, size: 18) : null);

  /// Convenient primary button template.
  factory AppButton.primary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    IconData? iconData,
    bool isFullWidth = true,
  }) => AppButton(
    key: key,
    text: text,
    onPressed: onPressed,
    variant: AppButtonVariant.primary,
    isLoading: isLoading,
    icon: icon,
    iconData: iconData,
    isFullWidth: isFullWidth,
  );

  /// Convenient secondary tonal button template.
  factory AppButton.secondary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    IconData? iconData,
    bool isFullWidth = true,
  }) => AppButton(
    key: key,
    text: text,
    onPressed: onPressed,
    variant: AppButtonVariant.secondaryTonal,
    isLoading: isLoading,
    icon: icon,
    iconData: iconData,
    isFullWidth: isFullWidth,
  );

  /// Convenient outlined button template.
  factory AppButton.outlined({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    IconData? iconData,
    bool isFullWidth = true,
  }) => AppButton(
    key: key,
    text: text,
    onPressed: onPressed,
    variant: AppButtonVariant.outlined,
    isLoading: isLoading,
    icon: icon,
    iconData: iconData,
    isFullWidth: isFullWidth,
  );

  /// Destructive confirmation button (e.g. "Suspend").
  factory AppButton.destructive({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    IconData? iconData,
    bool isFullWidth = true,
  }) => AppButton(
    key: key,
    text: text,
    onPressed: onPressed,
    variant: AppButtonVariant.destructive,
    isLoading: isLoading,
    icon: icon,
    iconData: iconData,
    isFullWidth: isFullWidth,
  );

  /// Adaptive button template: automatically full-width on smartphone (< 600dp)
  /// and intrinsic/compact width on tablet and desktop.
  factory AppButton.responsive({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    AppButtonVariant variant = AppButtonVariant.primary,
    bool isLoading = false,
    Widget? icon,
    IconData? iconData,
  }) => AppButton(
    key: key,
    text: text,
    onPressed: onPressed,
    variant: variant,
    isLoading: isLoading,
    icon: icon,
    iconData: iconData,
    isAdaptive: true,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final foreground = _foregroundColor;

    final childContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: _textColor(),
            ),
          ),
        ),
      ],
    );

    const minSize = Size(AppSpacing.minButtonWidth, AppSpacing.minTouchTarget);
    final shape = RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm);

    final Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            // While loading the button is intentionally disabled but must
            // keep its variant colors so the spinner stays visible.
            disabledBackgroundColor: isLoading ? AppColors.primary : null,
            disabledForegroundColor: isLoading ? AppColors.onPrimary : null,
            minimumSize: minSize,
            shape: shape,
          ),
          child: childContent,
        );
      case AppButtonVariant.secondaryTonal:
        button = FilledButton.tonal(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimaryContainer,
            disabledBackgroundColor: isLoading
                ? AppColors.primaryContainer
                : null,
            disabledForegroundColor: isLoading
                ? AppColors.onPrimaryContainer
                : null,
            minimumSize: minSize,
            shape: shape,
          ),
          child: childContent,
        );
      case AppButtonVariant.destructive:
        button = FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: isLoading ? AppColors.error : null,
            disabledForegroundColor: isLoading ? AppColors.onPrimary : null,
            minimumSize: minSize,
            shape: shape,
          ),
          child: childContent,
        );
      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            disabledForegroundColor: isLoading ? AppColors.primary : null,
            side: const BorderSide(color: AppColors.outlineVariant),
            minimumSize: minSize,
            shape: shape,
          ),
          child: childContent,
        );
    }

    // Width policy is applied at layout time by a render object that also
    // answers intrinsic-size queries, so the button is safe inside
    // AlertDialog action rows and other intrinsic layouts (a LayoutBuilder
    // is not), as well as inside unbounded Rows.
    return _ButtonWidthPolicy(
      fill: isAdaptive ? null : (isFullWidth ?? true),
      adaptiveThreshold: AppBreakpoints.mediumMin,
      child: button,
    );
  }

  Color get _foregroundColor {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.onPrimary;
      case AppButtonVariant.secondaryTonal:
        return AppColors.onPrimaryContainer;
      case AppButtonVariant.outlined:
        return AppColors.primary;
      case AppButtonVariant.destructive:
        return AppColors.onPrimary;
    }
  }

  Color _textColor() {
    if (onPressed == null && !isLoading) {
      return AppColors.textMuted;
    }
    return _foregroundColor;
  }
}

/// Applies [AppButton]'s width policy without a `LayoutBuilder`.
///
/// - [fill] `true`: stretch to the available width when it is bounded,
///   otherwise size to content (e.g. inside a `Row`).
/// - [fill] `false`: always size to content.
/// - [fill] `null` (adaptive): stretch only when the available width is below
///   [adaptiveThreshold], i.e. on compact layouts.
///
/// Intrinsic dimensions are delegated to the child, so this works inside
/// `IntrinsicWidth`/`IntrinsicHeight` and `AlertDialog` actions.
class _ButtonWidthPolicy extends SingleChildRenderObjectWidget {
  const _ButtonWidthPolicy({
    required this.fill,
    required this.adaptiveThreshold,
    required super.child,
  });

  final bool? fill;
  final double adaptiveThreshold;

  @override
  _RenderButtonWidthPolicy createRenderObject(BuildContext context) =>
      _RenderButtonWidthPolicy(
        fill: fill,
        adaptiveThreshold: adaptiveThreshold,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderButtonWidthPolicy renderObject,
  ) {
    renderObject
      ..fill = fill
      ..adaptiveThreshold = adaptiveThreshold;
  }
}

class _RenderButtonWidthPolicy extends RenderProxyBox {
  _RenderButtonWidthPolicy({this._fill, required this._adaptiveThreshold});

  bool? _fill;
  set fill(bool? value) {
    if (value == _fill) return;
    _fill = value;
    markNeedsLayout();
  }

  double _adaptiveThreshold;
  set adaptiveThreshold(double value) {
    if (value == _adaptiveThreshold) return;
    _adaptiveThreshold = value;
    markNeedsLayout();
  }

  bool _shouldFill(BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) return false;
    return _fill ?? constraints.maxWidth < _adaptiveThreshold;
  }

  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      _shouldFill(constraints)
      ? constraints.tighten(width: constraints.maxWidth)
      : constraints;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    size = constraints.constrain(child.size);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return constraints.constrain(
      child.getDryLayout(_childConstraints(constraints)),
    );
  }
}
