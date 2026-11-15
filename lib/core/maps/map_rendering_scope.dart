import 'package:flutter/widgets.dart';

/// Chooses how map widgets render, injected from above instead of detected.
///
/// Production never installs one, so real Google Maps views are used wherever
/// the platform supports them. Tests (and any host without platform views)
/// wrap their tree in `MapRenderingScope(useFallbackMap: true)` to get the
/// lightweight painted fallback.
class MapRenderingScope extends InheritedWidget {
  const MapRenderingScope({
    super.key,
    required this.useFallbackMap,
    required super.child,
  });

  final bool useFallbackMap;

  /// Whether the nearest scope asks for the painted fallback; false when no
  /// scope is installed.
  static bool useFallbackOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<MapRenderingScope>()
          ?.useFallbackMap ??
      false;

  @override
  bool updateShouldNotify(MapRenderingScope oldWidget) =>
      useFallbackMap != oldWidget.useFallbackMap;
}
