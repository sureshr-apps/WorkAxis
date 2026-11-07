import { MAX_GPS_ACCURACY_METERS } from "../config";
import { precondition } from "../errors";
import { evaluateGeofence, type LatLng } from "../geo/distance";

export type PunchKind = "checkIn" | "checkOut" | "breakStart" | "breakEnd";
export const PUNCH_KINDS: readonly PunchKind[] = [
  "checkIn",
  "checkOut",
  "breakStart",
  "breakEnd",
];

export interface BreakSpan {
  startAt: Date;
  endAt?: Date;
}

export interface DayState {
  checkInAt?: Date;
  checkOutAt?: Date;
  breaks: BreakSpan[];
}

/** Throws unless `kind` is a legal next punch for the day's state. */
export function assertPunchAllowed(kind: PunchKind, state: DayState): void {
  const openBreak = state.breaks.some((b) => !b.endAt);
  switch (kind) {
    case "checkIn":
      if (state.checkInAt) throw precondition("You have already checked in today.");
      return;
    case "checkOut":
      if (!state.checkInAt) throw precondition("Check in before checking out.");
      if (state.checkOutAt) throw precondition("You have already checked out today.");
      if (openBreak) throw precondition("End your break before checking out.");
      return;
    case "breakStart":
      if (!state.checkInAt || state.checkOutAt) throw precondition("You are not on shift.");
      if (openBreak) throw precondition("A break is already in progress.");
      return;
    case "breakEnd":
      if (!openBreak) throw precondition("No break is in progress.");
      return;
  }
}

export interface GeofenceBranch {
  latitude?: number;
  longitude?: number;
  geofenceRadiusMeters?: number;
}

/** Validates the GPS fix against the branch geofence. Returns the distance. */
export function assertInsideGeofence(
  fix: LatLng,
  accuracyMeters: number,
  branch: GeofenceBranch,
): number {
  if (
    branch.latitude === undefined ||
    branch.longitude === undefined ||
    branch.geofenceRadiusMeters === undefined ||
    (branch.latitude === 0 && branch.longitude === 0)
  ) {
    throw precondition("This branch has no geofence configured.");
  }
  if (accuracyMeters > MAX_GPS_ACCURACY_METERS) {
    throw precondition("Location accuracy is too low. Move to an open area and retry.");
  }
  const r = evaluateGeofence(
    fix,
    { latitude: branch.latitude, longitude: branch.longitude },
    branch.geofenceRadiusMeters,
  );
  if (!r.inside) throw precondition("You are outside the branch geofence.");
  return r.distanceMeters;
}
