import 'package:url_launcher/url_launcher.dart';

/// Builds a Google Maps navigation URL for a pin, with a text fallback for
/// assignments created before destination coordinates were stored.
Uri offSiteWorkDirectionsUri({
  required String destination,
  double? latitude,
  double? longitude,
}) {
  final target = latitude != null && longitude != null
      ? '$latitude,$longitude'
      : destination;
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': target,
    'travelmode': 'driving',
    'dir_action': 'navigate',
  });
}

Future<bool> launchOffSiteWorkDirections({
  required String destination,
  double? latitude,
  double? longitude,
}) => launchUrl(
  offSiteWorkDirectionsUri(
    destination: destination,
    latitude: latitude,
    longitude: longitude,
  ),
  mode: LaunchMode.externalApplication,
);
