const EARTH_RADIUS_METERS = 6_371_000;
const toRad = (deg: number): number => (deg * Math.PI) / 180;

export interface LatLng {
  latitude: number;
  longitude: number;
}

/** Great-circle distance in metres (haversine). */
export function distanceMeters(a: LatLng, b: LatLng): number {
  const dLat = toRad(b.latitude - a.latitude);
  const dLon = toRad(b.longitude - a.longitude);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(a.latitude)) * Math.cos(toRad(b.latitude)) * Math.sin(dLon / 2) ** 2;
  return 2 * EARTH_RADIUS_METERS * Math.asin(Math.min(1, Math.sqrt(h)));
}

export interface GeofenceResult {
  inside: boolean;
  distanceMeters: number;
}

export function evaluateGeofence(
  fix: LatLng,
  center: LatLng,
  radiusMeters: number,
): GeofenceResult {
  const d = distanceMeters(fix, center);
  return { inside: d <= radiusMeters, distanceMeters: d };
}
