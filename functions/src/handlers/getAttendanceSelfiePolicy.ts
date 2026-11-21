import { getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import { resolveActor } from "../auth/actor";
import { callableOptions } from "../config";
import { denied, guarded } from "../errors";

const DEFAULT_GEOFENCE_RADIUS_METERS = 150;

/** Returns the employee attendance policies needed by the app before a punch. */
export const getAttendanceSelfiePolicy = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    if (actor.role !== "employee" || !actor.organizationId) throw denied();

    const settings = await getFirestore()
      .collection("organization_settings")
      .doc(actor.organizationId)
      .get();
    const configuredRadius = settings.get("geofenceRadiusMeters");
    return {
      requireAttendanceSelfie:
        settings.get("requireAttendanceSelfie") !== false,
      requireGeolocation: settings.get("requireGeolocation") !== false,
      allowBreaks: settings.get("allowBreaks") !== false,
      defaultGeofenceRadiusMeters:
        typeof configuredRadius === "number" &&
        Number.isFinite(configuredRadius) &&
        configuredRadius > 0
          ? Math.round(configuredRadius)
          : DEFAULT_GEOFENCE_RADIUS_METERS,
    };
  }),
);
