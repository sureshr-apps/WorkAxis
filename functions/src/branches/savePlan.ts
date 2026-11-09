import { createHash } from "node:crypto";
import type { Actor } from "../auth/roles";
import { denied, invalid } from "../errors";
import {
  asBag,
  optString,
  optStringArray,
  reqEnum,
  reqNumber,
  reqString,
} from "../util/input";

export function parseBranchSave(actor: Actor, input: unknown) {
  if (actor.role !== "orgAdmin" || !actor.organizationId) throw denied();
  const bag = asBag(input);
  const existingId = optString(bag, "id", 1, 100);
  const requestId = existingId
    ? undefined
    : reqString(bag, "requestId", 1, 100);
  const creationRequestKey = requestId
    ? createHash("sha256")
        .update(`${actor.uid}:${actor.organizationId}:${requestId}`)
        .digest("hex")
    : undefined;
  const id = existingId ?? creationRequestKey!;
  const radius = reqNumber(bag, "geofenceRadiusMeters", 25, 5000);
  if (!Number.isInteger(radius))
    throw invalid("Geofence radius must be a whole number.");
  const latitude =
    bag.latitude == null ? null : reqNumber(bag, "latitude", -90, 90);
  const longitude =
    bag.longitude == null ? null : reqNumber(bag, "longitude", -180, 180);
  if (
    (latitude == null) !== (longitude == null) ||
    (latitude === 0 && longitude === 0)
  ) {
    throw invalid("Enter both coordinates or leave both empty.");
  }
  if (typeof bag.isMainBranch !== "boolean")
    throw invalid("Invalid main branch flag.");
  const data = {
    id,
    organizationId: actor.organizationId,
    name: reqString(bag, "name", 1, 100),
    code: optString(bag, "code", 1, 50) ?? `BR-${id.slice(0, 8).toUpperCase()}`,
    location: reqString(bag, "location", 1, 300),
    status: reqEnum(bag, "status", ["active", "suspended"] as const),
    isMainBranch: bag.isMainBranch,
    geofenceRadiusMeters: radius,
    latitude,
    longitude,
  };
  const managerIds = optStringArray(bag, "managerIds") ?? [];
  const creationFingerprint = creationRequestKey
    ? createHash("sha256")
        .update(JSON.stringify({ data, managerIds: [...managerIds].sort() }))
        .digest("hex")
    : undefined;
  return {
    creationFingerprint,
    creating: !existingId,
    managerIds,
    data: {
      ...data,
      ...(creationRequestKey
        ? { creationRequestKey, creationFingerprint }
        : {}),
    },
  };
}

export interface ManagerAssignment {
  id: string;
  authUid: string;
  organizationId: string;
  role: string;
  branchIds: string[];
}

export function validateManagerPlan(
  orgId: string,
  branchId: string,
  current: ManagerAssignment[],
  wanted: ManagerAssignment[],
  desiredIds: string[],
) {
  if (
    wanted.length !== desiredIds.length ||
    wanted.some(
      (m) =>
        !m.authUid || m.role !== "branchManager" || m.organizationId !== orgId,
    )
  ) {
    throw invalid(
      "A selected manager is outside your organization or has no sign-in identity.",
    );
  }
  for (const manager of current) {
    if (
      !desiredIds.includes(manager.id) &&
      !manager.branchIds.some((id) => id !== branchId)
    ) {
      throw invalid(
        "A manager must keep at least one branch. Assign another branch first.",
      );
    }
  }
}
