import 'package:flutter/widgets.dart';
import 'package:workaxis/core/maps/map_rendering_scope.dart';

/// `MaterialApp.builder` that makes map widgets render their painted fallback
/// instead of Google Maps platform views, which do not exist under
/// `flutter test`. Sits above the Navigator so dialogs inherit it too.
Widget fallbackMapsBuilder(BuildContext context, Widget? child) =>
    MapRenderingScope(useFallbackMap: true, child: child ?? const SizedBox());
