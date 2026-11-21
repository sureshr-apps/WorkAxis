import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/off_site_work/presentation/widgets/off_site_work_directions.dart';

void main() {
  test('directions use selected coordinates and request navigation', () {
    final uri = offSiteWorkDirectionsUri(
      destination: 'old text destination',
      latitude: 12.9716,
      longitude: 77.5946,
    );

    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters, {
      'api': '1',
      'destination': '12.9716,77.5946',
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });
  });

  test('legacy assignments use their saved destination search text', () {
    final uri = offSiteWorkDirectionsUri(destination: 'Main Street Bank');
    expect(uri.queryParameters['destination'], 'Main Street Bank');
  });
}
