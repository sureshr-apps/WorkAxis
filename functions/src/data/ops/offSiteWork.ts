import { getStorage } from "firebase-admin/storage";
import { denied, invalid } from "../../errors";
import type { Actor } from "../../auth/roles";
import type { SqlExecutor } from "../../db/executor";
import { attachmentsBucketName } from "../../config";
import { requireManagedBranch, requireRole } from "../authz";
import type { OperationRegistry } from "../operation";
import { insertReturningId, paged, Query, raw, select, selectOne } from "../sql";
import { optStringArray, reqNumber, reqString } from "../../util/input";
import { optText, optTimestamp, pageVars, reqId } from "../vars";

type Row = Record<string, unknown>;

const ASSIGNMENT_COLUMNS = `a.id, a.organization_id AS "organizationId",
  a.branch_id AS "branchId", a.branch_name AS "branchName",
  a.employee_member_id AS "employeeMemberId", a.employee_uid AS "employeeUid",
  a.employee_name AS "employeeName", a.assigned_by_uid AS "assignedByUid",
  a.assigned_by_name AS "assignedByName", a.title, a.instructions,
  a.destination, a.destination_latitude AS "destinationLatitude",
  a.destination_longitude AS "destinationLongitude",
  a.due_at AS "dueAt", a.reference,
  a.required_evidence_description AS "requiredEvidenceDescription", a.status,
  a.latest_latitude AS "latestLatitude", a.latest_longitude AS "latestLongitude",
  a.latest_accuracy_meters AS "latestAccuracyMeters",
  a.latest_milestone_at AS "latestMilestoneAt",
  a.created_at AS "createdAt", a.updated_at AS "updatedAt"`;

interface AssignmentScope {
  id: string;
  organizationId: string;
  branchId: string;
  employeeUid: string;
  requiredEvidenceDescription: string | null;
  status: string;
}

async function requireBranchScope(
  db: SqlExecutor,
  actor: Actor,
  vars: Row,
  branchId: string,
): Promise<{ organizationId: string; branchName: string }> {
  requireRole(actor, ["orgAdmin", "branchManager"]);
  if (!actor.organizationId) throw denied("Organization context is required.");
  const branch = await requireManagedBranch(db, actor, branchId);
  if (branch.organizationId !== actor.organizationId) throw denied();
  if (actor.role === "branchManager") {
    const activeBranchId = reqId(vars, "activeBranchId");
    if (activeBranchId !== branchId || !actor.branchIds.includes(branchId)) {
      throw denied("Use an active branch you manage.");
    }
  }
  const row = await selectOne<{ name: string; status: string }>(
    db,
    `SELECT name, status FROM branch
      WHERE id = $1 AND organization_id = $2 LIMIT 1`,
    [branchId, actor.organizationId],
  );
  if (!row || row.status !== "active") throw denied("Branch is not active.");
  return { organizationId: actor.organizationId, branchName: row.name };
}

async function findActor(
  db: SqlExecutor,
  actor: Actor,
  organizationId: string,
): Promise<{ id: string; fullName: string }> {
  const member = await selectOne<{ id: string; fullName: string }>(
    db,
    `SELECT id, full_name AS "fullName" FROM organization_member
      WHERE auth_uid = $1 AND organization_id = $2 AND role = $3 LIMIT 1`,
    [actor.uid, organizationId, actor.role],
  );
  if (!member) throw denied("Your organization profile could not be found.");
  return member;
}

async function loadAssignment(
  db: SqlExecutor,
  id: string,
  withEvents = false,
): Promise<(AssignmentScope & Row) | null> {
  const assignment = await selectOne<AssignmentScope & Row>(
    db,
    `SELECT ${ASSIGNMENT_COLUMNS} FROM off_site_work_assignment a WHERE a.id = $1`,
    [id],
  );
  if (!assignment || !withEvents) return assignment;
  const events = await select<Row>(
    db,
    `SELECT id, event_type AS "eventType", actor_uid AS "actorUid",
            actor_name AS "actorName", occurred_at AS "occurredAt",
            latitude, longitude, accuracy_meters AS "accuracyMeters", note,
            evidence_references AS "evidenceReferences"
       FROM off_site_work_event
      WHERE assignment_id = $1
      ORDER BY occurred_at ASC, id ASC`,
    [id],
  );
  return { ...assignment, events };
}

async function authorizeRead(
  db: SqlExecutor,
  actor: Actor,
  vars: Row,
  assignment: AssignmentScope,
): Promise<void> {
  if (actor.role === "employee") {
    if (assignment.employeeUid !== actor.uid || assignment.organizationId !== actor.organizationId) {
      throw denied("Assignment not found or access denied.");
    }
    return;
  }
  if (actor.role === "orgAdmin") {
    if (assignment.organizationId !== actor.organizationId) throw denied();
    return;
  }
  if (
    actor.role !== "branchManager" ||
    assignment.organizationId !== actor.organizationId ||
    reqId(vars, "activeBranchId") !== assignment.branchId ||
    !actor.branchIds.includes(assignment.branchId)
  ) {
    throw denied("Assignment not found or access denied.");
  }
  await requireBranchScope(db, actor, vars, assignment.branchId);
}

async function validateEvidenceReferences(
  assignment: AssignmentScope,
  references: string[],
): Promise<void> {
  if (references.length > 5) throw invalid("Attach no more than 5 photos.");
  if (references.length === 0) return;
  const prefix =
    `organizations/${assignment.organizationId}/off-site-work-evidence/` +
    `${assignment.branchId}/${assignment.employeeUid}/${assignment.id}/`;
  const bucket = getStorage().bucket(attachmentsBucketName());
  for (const reference of references) {
    if (!reference.startsWith(prefix)) throw invalid("Evidence photo path is invalid.");
    const name = reference.slice(prefix.length);
    if (!/^[0-9a-f-]{36}\.(jpg|png)$/i.test(name)) {
      throw invalid("Evidence photo path is invalid.");
    }
    let metadata;
    try {
      [metadata] = await bucket.file(reference).getMetadata();
    } catch {
      throw invalid("An evidence photo could not be verified. Please retry.");
    }
    const size = Number(metadata.size ?? 0);
    if (
      size < 1 ||
      size > 5 * 1024 * 1024 ||
      !["image/jpeg", "image/png"].includes(metadata.contentType ?? "")
    ) {
      throw invalid("Evidence photos must be JPEG or PNG images under 5 MB.");
    }
  }
}

async function listAssignments(
  db: SqlExecutor,
  actor: Actor,
  vars: Row,
): Promise<unknown> {
  const { limit, offset } = pageVars(vars);
  const q = new Query();
  if (actor.role === "employee") {
    q.eq("a.employee_uid", actor.uid);
  } else if (actor.role === "orgAdmin") {
    if (!actor.organizationId) throw denied("Organization context is required.");
    q.eq("a.organization_id", actor.organizationId);
    const branchId = vars.branchId == null ? undefined : reqId(vars, "branchId");
    if (branchId) {
      const branch = await requireManagedBranch(db, actor, branchId);
      if (branch.organizationId !== actor.organizationId) throw denied();
    }
    q.eq("a.branch_id", branchId);
  } else if (actor.role === "branchManager") {
    const branchId = reqId(vars, "activeBranchId");
    await requireBranchScope(db, actor, vars, branchId);
    q.eq("a.branch_id", branchId);
  } else {
    throw denied();
  }
  const { rows, total } = await paged<Row>(db, {
    columns: ASSIGNMENT_COLUMNS,
    from: "off_site_work_assignment a",
    q,
    orderBy: "a.created_at DESC, a.id DESC",
    limit,
    offset,
  });
  return { offSiteWorkAssignments: rows, total };
}

export const offSiteWorkOps: OperationRegistry = {
  ListOffSiteWorkAssignments: async ({ db, actor }, vars) =>
    listAssignments(db, actor, vars),

  GetOffSiteWorkAssignment: async ({ db, actor }, vars) => {
    requireRole(actor, ["orgAdmin", "branchManager", "employee"]);
    const id = reqId(vars, "id");
    const assignment = await loadAssignment(db, id);
    if (!assignment) throw denied("Assignment not found or access denied.");
    await authorizeRead(db, actor, vars, assignment);
    const offSiteWorkAssignment = await loadAssignment(db, id, true);
    return { offSiteWorkAssignment };
  },

  CreateOffSiteWorkAssignment: async ({ db, actor }, vars) => {
    requireRole(actor, ["orgAdmin", "branchManager"]);
    const branchId = reqId(vars, "branchId");
    const title = reqString(vars, "title", 1, 120);
    const instructions = optText(vars, "instructions", 4000);
    const destination = reqString(vars, "destination", 1, 250);
    const destinationLatitude = vars.destinationLatitude == null
      ? undefined
      : reqNumber(vars, "destinationLatitude", -90, 90);
    const destinationLongitude = vars.destinationLongitude == null
      ? undefined
      : reqNumber(vars, "destinationLongitude", -180, 180);
    if ((destinationLatitude == null) !== (destinationLongitude == null)) {
      throw invalid("Destination coordinates must be provided together.");
    }
    const dueAt = optTimestamp(vars, "dueAt");
    const reference = optText(vars, "reference", 200);
    const evidenceDescription = optText(vars, "requiredEvidenceDescription", 500);
    const employeeMemberId = reqId(vars, "employeeMemberId");
    return db.transaction(async (tx) => {
      const branch = await requireBranchScope(tx, actor, vars, branchId);
      const employee = await selectOne<{ id: string; uid: string; fullName: string }>(
        tx,
        `SELECT m.id, m.auth_uid AS uid, m.full_name AS "fullName"
           FROM organization_member m
           JOIN user_branch_assignment a ON a.member_id = m.id
          WHERE m.id = $1 AND m.organization_id = $2 AND m.role = 'employee'
            AND m.status = 'active' AND a.branch_id = $3
          LIMIT 1`,
        [employeeMemberId, branch.organizationId, branchId],
      );
      if (!employee?.uid) throw denied("Employee is not active in this branch.");
      const manager = await findActor(tx, actor, branch.organizationId);
      const { id } = await insertReturningId(tx, "off_site_work_assignment", [
        ["organization_id", branch.organizationId],
        ["branch_id", branchId],
        ["branch_name", branch.branchName],
        ["employee_member_id", employee.id],
        ["employee_uid", employee.uid],
        ["employee_name", employee.fullName],
        ["assigned_by_uid", actor.uid],
        ["assigned_by_name", manager.fullName],
        ["title", title],
        ["instructions", instructions],
        ["destination", destination],
        ["destination_latitude", destinationLatitude],
        ["destination_longitude", destinationLongitude],
        ["due_at", dueAt],
        ["reference", reference],
        ["required_evidence_description", evidenceDescription],
        ["status", "assigned"],
        ["created_at", raw("now()")],
        ["updated_at", raw("now()")],
      ]);
      await tx.query(
        `INSERT INTO off_site_work_event
           (assignment_id, event_type, actor_uid, actor_name, occurred_at)
         VALUES ($1, 'assigned', $2, $3, now())`,
        [id, actor.uid, manager.fullName],
      );
      const offSiteWorkAssignment = await loadAssignment(tx, id, true);
      if (!offSiteWorkAssignment) throw denied("Assignment could not be loaded.");
      return { offSiteWorkAssignment };
    });
  },

  RecordOffSiteWorkMilestone: async ({ db, actor }, vars) => {
    requireRole(actor, ["employee"]);
    const id = reqId(vars, "id");
    const eventType = reqString(vars, "eventType", 1, 40);
    const allowed = ["started", "arrived", "completed", "unable_to_complete", "returned_to_branch"];
    if (!allowed.includes(eventType)) throw invalid("Invalid off-site work milestone.");
    const latitude = reqNumber(vars, "latitude", -90, 90);
    const longitude = reqNumber(vars, "longitude", -180, 180);
    const accuracy = reqNumber(vars, "accuracyMeters", 0, 100000);
    const note = optText(vars, "note", 2000);
    const evidenceReferences = optStringArray(vars, "evidenceReferences", 5) ?? [];
    const initial = await selectOne<AssignmentScope>(
      db,
      `SELECT id, organization_id AS "organizationId", branch_id AS "branchId",
              employee_uid AS "employeeUid",
              required_evidence_description AS "requiredEvidenceDescription",
              status
         FROM off_site_work_assignment WHERE id = $1`,
      [id],
    );
    if (!initial || initial.employeeUid !== actor.uid || initial.organizationId !== actor.organizationId) {
      throw denied("Assignment not found or access denied.");
    }
    if (eventType === "unable_to_complete" && !note?.trim()) {
      throw invalid("Add a reason before marking the assignment unable to complete.");
    }
    if (
      eventType === "completed" &&
      initial.requiredEvidenceDescription?.trim() &&
      !note?.trim() &&
      evidenceReferences.length === 0
    ) {
      throw invalid("Add the requested evidence as a note or photo before completing.");
    }
    if (!(["completed", "unable_to_complete"].includes(eventType)) && evidenceReferences.length > 0) {
      throw invalid("Photos can only be attached to the completion or failure event.");
    }
    await validateEvidenceReferences(initial, evidenceReferences);

    const nextStatus: Record<string, { from: string[]; to: string }> = {
      started: { from: ["assigned"], to: "in_progress" },
      arrived: { from: ["in_progress"], to: "arrived" },
      completed: { from: ["arrived"], to: "completed" },
      unable_to_complete: { from: ["arrived"], to: "unable_to_complete" },
      returned_to_branch: { from: ["completed", "unable_to_complete"], to: "returned" },
    };
    const transition = nextStatus[eventType];
    if (!transition) throw invalid("Invalid off-site work milestone.");
    return db.transaction(async (tx) => {
      const current = await selectOne<AssignmentScope>(
        tx,
        `SELECT id, organization_id AS "organizationId", branch_id AS "branchId",
                employee_uid AS "employeeUid",
                required_evidence_description AS "requiredEvidenceDescription",
                status
           FROM off_site_work_assignment WHERE id = $1 FOR UPDATE`,
        [id],
      );
      if (!current || current.employeeUid !== actor.uid || current.organizationId !== actor.organizationId) {
        throw denied("Assignment not found or access denied.");
      }
      if (!transition.from.includes(current.status)) {
        throw denied("This assignment has changed. Refresh it and try again.");
      }
      const member = await findActor(tx, actor, current.organizationId);
      await tx.query(
        `INSERT INTO off_site_work_event
           (assignment_id, event_type, actor_uid, actor_name, occurred_at,
            latitude, longitude, accuracy_meters, note, evidence_references)
         VALUES ($1, $2, $3, $4, now(), $5, $6, $7, $8, $9::text[])`,
        [id, eventType, actor.uid, member.fullName, latitude, longitude, accuracy, note ?? null, evidenceReferences],
      );
      await tx.query(
        `UPDATE off_site_work_assignment
            SET status = $2, latest_latitude = $3, latest_longitude = $4,
                latest_accuracy_meters = $5, latest_milestone_at = now(), updated_at = now()
          WHERE id = $1`,
        [id, transition.to, latitude, longitude, accuracy],
      );
      const offSiteWorkAssignment = await loadAssignment(tx, id, true);
      if (!offSiteWorkAssignment) throw denied("Assignment could not be loaded.");
      return { offSiteWorkAssignment };
    });
  },
};
