import type { Actor } from "../auth/roles";
import type { MemberRecord } from "../sql/members";
import { denied, invalid } from "../errors";
import { workDateStart, workDateString } from "../time/workDate";
import { asBag, optString, reqEnum, reqString } from "../util/input";

export function parseGroupAttendance(input: unknown, now: Date) {
  const bag = asBag(input);
  const requestId = reqString(bag, "requestId", 1, 100);
  if (!/^[a-zA-Z0-9_-]+$/.test(requestId)) throw invalid("Invalid request id.");
  const branchId = reqString(bag, "branchId", 1, 100);
  const workDate = reqString(bag, "workDate", 10, 10);
  const start = workDateStart(workDate);
  const today = workDateStart(workDateString(now));
  if (
    !/^\d{4}-\d{2}-\d{2}$/.test(workDate) ||
    !Number.isFinite(start.getTime()) ||
    workDateString(start) !== workDate ||
    start > today ||
    today.getTime() - start.getTime() > 6 * 86_400_000
  ) {
    throw invalid("Group check-in must be for today or the last six days.");
  }
  const checkInText = reqString(bag, "checkInAt", 20, 40);
  // Require an explicit timezone; never interpret a device-local timestamp.
  const checkInAt = new Date(checkInText);
  if (
    !/(Z|[+-]\d{2}:\d{2})$/.test(checkInText) ||
    !Number.isFinite(checkInAt.getTime()) ||
    checkInAt > now ||
    workDateString(checkInAt) !== workDate
  ) {
    throw invalid(
      "Check-in time must be on the selected business day and not in the future.",
    );
  }
  const raw = bag.employeeIds;
  if (
    !Array.isArray(raw) ||
    raw.length === 0 ||
    raw.length > 400 ||
    raw.some(
      (uid) =>
        typeof uid !== "string" ||
        !uid ||
        uid.length > 128 ||
        uid.includes("/"),
    )
  ) {
    throw invalid("Select between 1 and 400 employees.");
  }
  const employeeIds = raw as string[];
  if (new Set(employeeIds).size !== employeeIds.length)
    throw invalid("Duplicate employees are not allowed.");
  return {
    requestId,
    branchId,
    workDate,
    checkInAt,
    employeeIds: [...employeeIds].sort(),
    status: reqEnum(bag, "status", ["present", "late"] as const),
    shiftName: reqString(bag, "shiftName", 1, 100),
    note: optString(bag, "note", 0, 1000) ?? null,
  };
}

export function assertGroupScope(
  actor: Actor,
  branch: { id: string; organizationId: string; status: string },
) {
  if (
    !actor.organizationId ||
    branch.organizationId !== actor.organizationId ||
    branch.status !== "active" ||
    (actor.role !== "orgAdmin" && actor.role !== "branchManager") ||
    (actor.role === "branchManager" && !actor.branchIds.includes(branch.id))
  )
    throw denied();
}

export function assertGroupAttendee(
  member: MemberRecord | null,
  organizationId: string,
  branchId: string,
) {
  if (
    !member ||
    member.role !== "employee" ||
    member.status !== "active" ||
    member.organizationId !== organizationId ||
    member.organizationStatus !== "active" ||
    !member.activeBranchIds.includes(branchId)
  ) {
    throw denied(
      "Every attendee must be an active employee assigned to this branch.",
    );
  }
}
