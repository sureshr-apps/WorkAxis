import 'package:flutter/widgets.dart';

/// Exposes the width actually available to page content (after the shell's
/// sidebar, max-width constraints and page padding) to descendants.
///
/// Intrinsic-sizing widgets such as `ResponsiveKpiSection` cannot use a
/// `LayoutBuilder` (it does not support intrinsic dimensions), yet they are
/// embedded in `IntrinsicHeight` rows. They read this scope instead and fall
/// back to the screen width when no scope is present.
class ContentWidthScope extends InheritedWidget {
  const ContentWidthScope({
    super.key,
    required this.width,
    required super.child,
  });

  /// Width available to the content, in logical pixels.
  final double width;

  /// The enclosing content width, or `null` when no scope is present.
  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ContentWidthScope>()?.width;

  /// The enclosing content width, falling back to the screen width.
  static double of(BuildContext context) =>
      maybeOf(context) ?? MediaQuery.sizeOf(context).width;

  @override
  bool updateShouldNotify(ContentWidthScope oldWidget) =>
      width != oldWidget.width;
}

/// Measures its own constraints and publishes them through a
/// [ContentWidthScope]. Place it around page content, never inside an
/// `IntrinsicHeight`/`IntrinsicWidth`.
class ContentWidthProvider extends StatelessWidget {
  const ContentWidthProvider({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return ContentWidthScope(width: width, child: child);
      },
    );
  }
}
