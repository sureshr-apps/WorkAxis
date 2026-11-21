import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { onCall } from "firebase-functions/v2/https";
import { resolveActor } from "../auth/actor";
import {
  PUNCH_KINDS,
  assertInsideGeofence,
  assertPunchAllowed,
  type BreakSpan,
  type DayState,
  type PunchKind,
} from "../attendance/punchRules";
import { attachmentsBucketName, callableOptions } from "../config";
import { denied, guarded, notFound, precondition } from "../errors";
import { getBranch } from "../sql/branches";
import { getMemberByAuthUid } from "../sql/members";
import { workDateStart, workDateString } from "../time/workDate";
import { asBag, optString, reqEnum, reqNumber, reqString } from "../util/input";

type StoredBreak = {
  startAt: Timestamp;
  endAt?: Timestamp;
  startSelfiePath?: string;
  endSelfiePath?: string;
};

const MAX_SELFIE_AGE_MS = 15 * 60 * 1000;
const MAX_SELFIE_SIZE_BYTES = 5 * 1024 * 1024;

const toDate = (t: Timestamp | undefined): Date | undefined => t?.toDate();

function readState(data: FirebaseFirestore.DocumentData | undefined): DayState {
  const breaks: BreakSpan[] = ((data?.breaks as StoredBreak[] | undefined) ?? []).map((b) => ({
    startAt: b.startAt.toDate(),
    endAt: toDate(b.endAt),
  }));
  return {
    checkInAt: toDate(data?.checkInAt),
    checkOutAt: toDate(data?.checkOutAt),
    breaks,
  };
}

/**
 * recordAttendancePunch (callable, asia-south1) - Employees only.
 * Request:  { kind: 'checkIn'|'checkOut'|'breakStart'|'breakEnd', branchId,
 *             latitude?, longitude?, accuracyMeters?, selfiePath? }
 * Response: { entryId, kind, recordedAt (ISO), workDate, distanceMeters: number | null }
 * Server time and the Asia/Kolkata workDate are stamped here. When required,
 * the geofence uses the branch radius or the organization default.
 */
export const recordAttendancePunch = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    if (actor.role !== "employee") throw denied();

    const bag = asBag(request.data);
    const kind: PunchKind = reqEnum(bag, "kind", PUNCH_KINDS);
    const branchId = reqString(bag, "branchId", 1, 100);
    const selfiePath = optString(bag, "selfiePath", 1, 512);

    if (!actor.branchIds.includes(branchId)) throw denied("You are not assigned to this branch.");
    const branch = await getBranch(branchId);
    if (!branch || branch.status !== "active") throw notFound("Branch not found.");
    if (branch.organizationId !== actor.organizationId) throw denied();
    const member = await getMemberByAuthUid(actor.uid);
    if (!member) throw denied();

    const settingsRef = getFirestore()
      .collection("organization_settings")
      .doc(branch.organizationId);
    if (selfiePath) {
      await validateSelfieObject(selfiePath, {
        organizationId: branch.organizationId,
        branchId,
        employeeUid: actor.uid,
      });
    }

    const now = new Date();
    const workDate = workDateString(now);
    const entryId = `${actor.uid}_${workDate}`;
    const ref = getFirestore().collection("attendance_entries").doc(entryId);
    const stamp = Timestamp.fromDate(now);
    let distanceMeters: number | null = null;

    await getFirestore().runTransaction(async (tx) => {
      distanceMeters = null;
      const snap = await tx.get(ref);
      const settings = await tx.get(settingsRef);
      const selfieRequired = settings.get("requireAttendanceSelfie") !== false;
      if (selfieRequired && !selfiePath) {
        throw precondition("Take a selfie before recording this attendance action.");
      }
      if (settings.get("requireGeolocation") !== false) {
        const fix = {
          latitude: reqNumber(bag, "latitude", -90, 90),
          longitude: reqNumber(bag, "longitude", -180, 180),
        };
        const accuracy = reqNumber(bag, "accuracyMeters", 0, 100_000);
        const configuredRadius = settings.get("geofenceRadiusMeters");
        const defaultRadius =
          typeof configuredRadius === "number" &&
          Number.isFinite(configuredRadius) &&
          configuredRadius > 0
            ? Math.round(configuredRadius)
            : 150;
        distanceMeters = assertInsideGeofence(
          fix,
          accuracy,
          branch,
          defaultRadius,
        );
      }
      const data = snap.data();
      if (snap.exists && data?.branchId !== branchId) {
        throw precondition("You are already checked in at a different branch today.");
      }
      const state = readState(data);
      assertPunchAllowed(kind, state, settings.get("allowBreaks") !== false);
      if (selfiePath && hasUsedSelfiePath(data, selfiePath)) {
        throw precondition("Take a new selfie for each attendance action.");
      }

      if (kind === "checkIn") {
        tx.set(ref, {
          id: entryId,
          organizationId: branch.organizationId,
          branchId,
          employeeId: actor.uid,
          employeeName: member.fullName,
          workDate: Timestamp.fromDate(workDateStart(workDate)),
          workDateString: workDate,
          status: "present",
          reviewStatus: "none",
          checkInAt: stamp,
          ...(selfiePath ? { checkInSelfiePath: selfiePath } : {}),
          breaks: [],
          kioskEntry: false,
          source: "employee-app",
          createdAt: FieldValue.serverTimestamp(),
        });
        return;
      }
      const stored = (data?.breaks as StoredBreak[] | undefined) ?? [];
      if (kind === "checkOut") {
        tx.update(ref, {
          checkOutAt: stamp,
          ...(selfiePath ? { checkOutSelfiePath: selfiePath } : {}),
        });
      } else if (kind === "breakStart") {
        tx.update(ref, {
          breaks: [
            ...stored,
            { startAt: stamp, ...(selfiePath ? { startSelfiePath: selfiePath } : {}) },
          ],
        });
      } else {
        const next = stored.map((b) =>
          b.endAt
            ? b
            : {
                ...b,
                endAt: stamp,
                ...(selfiePath ? { endSelfiePath: selfiePath } : {}),
              },
        );
        tx.update(ref, { breaks: next });
      }
    });

    return {
      entryId,
      kind,
      recordedAt: now.toISOString(),
      workDate,
      distanceMeters:
        distanceMeters === null ? null : Math.round(distanceMeters),
    };
  }),
);

async function validateSelfieObject(
  path: string,
  expected: { organizationId: string; branchId: string; employeeUid: string },
): Promise<void> {
  const prefix = `organizations/${expected.organizationId}/attendance-selfies/${expected.branchId}/${expected.employeeUid}/`;
  const filename = path.startsWith(prefix) ? path.slice(prefix.length) : "";
  if (!/^[0-9a-f-]{36}\.(jpg|png)$/i.test(filename)) {
    throw denied("The attendance selfie does not belong to this employee and branch.");
  }

  let metadata: {
    contentType?: string;
    size?: string | number;
    timeCreated?: string;
  };
  try {
    [metadata] = await getStorage()
      .bucket(attachmentsBucketName())
      .file(path)
      .getMetadata();
  } catch {
    throw precondition("The attendance selfie could not be verified. Take a new selfie.");
  }

  const size = Number(metadata.size);
  const createdAt = metadata.timeCreated ? Date.parse(metadata.timeCreated) : NaN;
  const age = Date.now() - createdAt;
  const expectedContentType = filename.endsWith(".png")
    ? "image/png"
    : "image/jpeg";
  const validContentType =
    (metadata.contentType ?? "").toLowerCase() === expectedContentType;
  if (
    !validContentType ||
    !Number.isFinite(size) ||
    size <= 0 ||
    size > MAX_SELFIE_SIZE_BYTES ||
    !Number.isFinite(createdAt) ||
    age < -60_000 ||
    age > MAX_SELFIE_AGE_MS
  ) {
    throw precondition("The attendance selfie is invalid or too old. Take a new selfie.");
  }
}

function hasUsedSelfiePath(
  data: FirebaseFirestore.DocumentData | undefined,
  path: string,
): boolean {
  if (!data) return false;
  if (data.checkInSelfiePath === path || data.checkOutSelfiePath === path) {
    return true;
  }
  const breaks = (data.breaks as StoredBreak[] | undefined) ?? [];
  return breaks.some(
    (entry) => entry.startSelfiePath === path || entry.endSelfiePath === path,
  );
}
