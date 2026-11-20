import { getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import { resolveActor } from "../auth/actor";
import { callableOptions } from "../config";
import { denied, guarded } from "../errors";

/** Returns only the selfie policy needed by an employee before a punch. */
export const getAttendanceSelfiePolicy = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    if (actor.role !== "employee" || !actor.organizationId) throw denied();

    const settings = await getFirestore()
      .collection("organization_settings")
      .doc(actor.organizationId)
      .get();
    return {
      requireAttendanceSelfie: settings.get("requireAttendanceSelfie") === true,
    };
  }),
);
