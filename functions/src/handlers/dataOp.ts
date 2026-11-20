import { onCall } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { resolveActor } from "../auth/actor";
import { reprojectAfterLicenseChange } from "../accounts/licenseProjection";
import { callableOptions } from "../config";
import { runOperation } from "../data/dispatch";
import { operations } from "../data/registry";
import { getDb } from "../db";
import { guarded } from "../errors";

/**
 * dataOp (callable, asia-south1)
 * Request:  { op: string, vars?: object }
 * Response: { data: <operation result> }
 *
 * The single door through which the app reads and writes relational data.
 * The caller is resolved from SQL on every call, so a suspension or role
 * change takes effect immediately instead of waiting for claims to refresh.
 */
export const dataOp = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    const db = await getDb();
    const data = await runOperation(
      operations,
      {
        db,
        actor,
        requireEmployeeAssetAcknowledgement: async (organizationId) => {
          const snapshot = await getFirestore()
            .collection("organization_settings")
            .doc(organizationId)
            .get();
          return snapshot.get("requireEmployeeAssetAcknowledgement") === true;
        },
      },
      request.data,
    );
    await reprojectAfterLicenseChange(request.data);
    return { data };
  }),
);
