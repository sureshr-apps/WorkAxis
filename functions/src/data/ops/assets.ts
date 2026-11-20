import type { Actor } from "../../auth/roles";
import { denied, invalid } from "../../errors";
import type { SqlExecutor } from "../../db/executor";
import { requireManagedBranch } from "../authz";
import type { OperationRegistry } from "../operation";
import { optId, optText, reqId } from "../vars";
import { reqEnum, reqString } from "../../util/input";

type RequestVars = Record<string, unknown>;

interface AssetScope {
  id: string;
  organizationId: string;
  branchId: string;
  employeeId: string;
}

const ASSET_COLUMNS = `
  ea.id,
  ea.organization_id AS "organizationId",
  ea.branch_id AS "branchId",
  b.name AS "branchName",
  ea.employee_member_id AS "employeeId",
  m.full_name AS "employeeName",
  ea.name,
  ea.category,
  ea.asset_tag AS "assetTag",
  ea.serial_number AS "serialNumber",
  ea.status,
  ea.notes,
  ea.assigned_by_uid AS "assignedByUid",
  ea.assigned_by_name AS "assignedByName",
  ea.assigned_at AS "assignedAt",
  ea.acknowledgement_required AS "acknowledgementRequired",
  ea.acknowledgement_status AS "acknowledgementStatus",
  ea.acknowledged_by_uid AS "acknowledgedByUid",
  ea.acknowledged_by_name AS "acknowledgedByName",
  ea.acknowledged_at AS "acknowledgedAt"`;

async function loadAsset(db: SqlExecutor, id: string) {
  const rows = await db.query<Record<string, unknown>>(
    `SELECT ${ASSET_COLUMNS}
       FROM employee_asset ea
       JOIN branch b ON b.id = ea.branch_id
       JOIN organization_member m ON m.id = ea.employee_member_id
      WHERE ea.id = $1`,
    [id],
  );
  return rows[0] ?? null;
}

function requireEditor(actor: Actor): string {
  if (
    (actor.role !== "orgAdmin" && actor.role !== "branchManager") ||
    !actor.organizationId
  ) {
    throw denied();
  }
  return actor.organizationId;
}

async function assignmentActorName(
  db: SqlExecutor,
  actor: Actor,
  organizationId: string,
): Promise<string> {
  const rows = await db.query<{ fullName: string }>(
    `SELECT full_name AS "fullName"
       FROM organization_member
      WHERE auth_uid = $1
        AND organization_id = $2
        AND role = $3
      LIMIT 1`,
    [actor.uid, organizationId, actor.role],
  );
  const fullName = rows[0]?.fullName;
  if (!fullName) throw denied("Assignment actor not found.");
  return fullName;
}

async function validateActiveBranch(
  db: SqlExecutor,
  actor: Actor,
  vars: RequestVars,
  branchId: string,
): Promise<void> {
  if (actor.role !== "branchManager") return;
  const activeBranchId = reqId(vars, "activeBranchId");
  if (activeBranchId !== branchId || !actor.branchIds.includes(activeBranchId)) {
    throw denied("Branch not found or access denied.");
  }
  const active = await db.query<{ id: string }>(
    `SELECT id FROM branch
      WHERE id = $1 AND organization_id = $2 AND status = 'active'
      LIMIT 1`,
    [branchId, actor.organizationId],
  );
  if (!active[0]) throw denied("Branch not found or access denied.");
}

async function listAssets(
  db: SqlExecutor,
  where: string,
  params: readonly unknown[],
) {
  const employeeAssets = await db.query<Record<string, unknown>>(
    `SELECT ${ASSET_COLUMNS}
       FROM employee_asset ea
       JOIN branch b ON b.id = ea.branch_id
       JOIN organization_member m ON m.id = ea.employee_member_id
      WHERE ${where}
      ORDER BY m.full_name, ea.name, ea.id`,
    params,
  );
  return { employeeAssets };
}

async function requireEmployeeAtBranch(
  db: SqlExecutor,
  organizationId: string,
  branchId: string,
  employeeId: string,
): Promise<void> {
  const rows = await db.query<{ id: string }>(
    `SELECT m.id
       FROM organization_member m
       JOIN user_branch_assignment a ON a.member_id = m.id
      WHERE m.id = $1
        AND m.organization_id = $2
        AND m.role = 'employee'
        AND a.branch_id = $3
      LIMIT 1`,
    [employeeId, organizationId, branchId],
  );
  if (!rows[0]) {
    throw denied("Employee is not assigned to this branch.");
  }
}

async function ensureAssetScope(
  db: SqlExecutor,
  actor: Actor,
  scope: AssetScope,
  vars: RequestVars,
): Promise<void> {
  const organizationId = requireEditor(actor);
  if (scope.organizationId !== organizationId) throw denied();
  if (actor.role === "branchManager") {
    await validateActiveBranch(db, actor, vars, scope.branchId);
    const branch = await requireManagedBranch(db, actor, scope.branchId);
    if (branch.organizationId !== organizationId) throw denied();
  }
}

export const assetsOps: OperationRegistry = {
  ListMyEmployeeAssets: async ({ db, actor }) => {
    if (actor.role !== "employee") throw denied();
    return listAssets(
      db,
      `ea.employee_member_id IN (
         SELECT m.id FROM organization_member m
          WHERE m.auth_uid = $1 AND m.role = 'employee'
       )`,
      [actor.uid],
    );
  },

  ListOrganizationEmployeeAssets: async ({ db, actor }) => {
    if (actor.role !== "orgAdmin" || !actor.organizationId) throw denied();
    return listAssets(db, "ea.organization_id = $1", [actor.organizationId]);
  },

  ListBranchEmployeeAssets: async ({ db, actor }, vars) => {
    if (actor.role !== "branchManager") throw denied();
    const branchId = reqId(vars, "branchId");
    const branch = await requireManagedBranch(db, actor, branchId);
    if (!actor.organizationId || branch.organizationId !== actor.organizationId) {
      throw denied();
    }
    await validateActiveBranch(db, actor, vars, branchId);
    return listAssets(
      db,
      `ea.organization_id = $1 AND ea.branch_id = $2
       AND m.role = 'employee'
       AND EXISTS (
         SELECT 1 FROM user_branch_assignment a
          WHERE a.member_id = ea.employee_member_id AND a.branch_id = ea.branch_id
       )`,
      [actor.organizationId, branchId],
    );
  },

  SaveEmployeeAsset: async (
    { db, actor, requireEmployeeAssetAcknowledgement },
    vars,
  ) => {
    const organizationId = requireEditor(actor);
    const branchId = reqId(vars, "branchId");
    const employeeId = reqId(vars, "employeeId");
    const id = optId(vars, "id");
    const name = reqString(vars, "name", 1, 120);
    const category = reqString(vars, "category", 1, 80);
    const assetTag = reqString(vars, "assetTag", 1, 80);
    const serialNumber = optText(vars, "serialNumber", 128);
    const notes = optText(vars, "notes", 2000);
    const status = reqEnum(vars, "status", [
      "assigned",
      "maintenance",
      "returned",
    ] as const);
    const requireAcknowledgement =
      await requireEmployeeAssetAcknowledgement(organizationId);

    return db.transaction(async (tx) => {
      const branch = await requireManagedBranch(tx, actor, branchId);
      if (branch.organizationId !== organizationId) throw denied();
      await validateActiveBranch(tx, actor, vars, branchId);
      await requireEmployeeAtBranch(tx, organizationId, branchId, employeeId);

      const duplicate = await tx.query<{ id: string }>(
        `SELECT id FROM employee_asset
          WHERE organization_id = $1
            AND lower(asset_tag) = lower($2)
            AND ($3::text IS NULL OR id <> $3)
          LIMIT 1`,
        [organizationId, assetTag, id ?? null],
      );
      if (duplicate[0]) throw invalid("That asset tag is already in use.");

      if (id) {
        const existing = await tx.query<
          AssetScope & { status: string; acknowledgementStatus: string }
        >(
          `SELECT id,
                  organization_id AS "organizationId",
                  branch_id AS "branchId",
                  employee_member_id AS "employeeId",
                  acknowledgement_status AS "acknowledgementStatus",
                  status
             FROM employee_asset
            WHERE id = $1
            FOR UPDATE`,
          [id],
        );
        if (!existing[0]) throw denied("Asset not found or access denied.");
        await ensureAssetScope(tx, actor, existing[0], vars);
        if (
          actor.role === "branchManager" &&
          existing[0].branchId !== branchId
        ) {
          throw denied("Asset is outside the active branch.");
        }
        if (actor.role === "branchManager") {
          await requireEmployeeAtBranch(
            tx,
            organizationId,
            existing[0].branchId,
            existing[0].employeeId,
          );
        }
        const assignmentChanged =
          existing[0].employeeId !== employeeId ||
          existing[0].branchId !== branchId ||
          (existing[0].status === "returned" && status === "assigned");
        const clearPendingAcknowledgement =
          status === "returned" &&
          existing[0].acknowledgementStatus === "pending";
        const resetAcknowledgement =
          assignmentChanged || clearPendingAcknowledgement;
        const assignmentAcknowledgementRequired =
          resetAcknowledgement &&
          status !== "returned" &&
          requireAcknowledgement;
        const assignedByName = assignmentChanged
          ? await assignmentActorName(tx, actor, organizationId)
          : null;
        await tx.query(
          `UPDATE employee_asset
              SET branch_id = $2,
                  employee_member_id = $3,
                  name = $4,
                  category = $5,
                  asset_tag = $6,
                  serial_number = $7,
                  status = $8,
                  notes = $9,
                  acknowledgement_required = CASE WHEN $10
                    THEN $11 ELSE acknowledgement_required END,
                  acknowledgement_status = CASE WHEN $10
                    THEN $12 ELSE acknowledgement_status END,
                  acknowledged_at = CASE WHEN $10
                    THEN NULL ELSE acknowledged_at END,
                  acknowledged_by_uid = CASE WHEN $10
                    THEN NULL ELSE acknowledged_by_uid END,
                  acknowledged_by_name = CASE WHEN $10
                    THEN NULL ELSE acknowledged_by_name END,
                  assigned_by_uid = CASE WHEN $13
                    THEN $14 ELSE assigned_by_uid END,
                  assigned_by_name = CASE WHEN $13
                    THEN $15 ELSE assigned_by_name END,
                  assigned_at = CASE WHEN $13
                    THEN now() ELSE assigned_at END,
                  updated_at = now()
            WHERE id = $1 AND organization_id = $16`,
          [
            id,
            branchId,
            employeeId,
            name,
            category,
            assetTag,
            serialNumber ?? null,
            status,
            notes ?? null,
            resetAcknowledgement,
            assignmentAcknowledgementRequired,
            assignmentAcknowledgementRequired ? "pending" : "not_required",
            assignmentChanged,
            actor.uid,
            assignedByName,
            organizationId,
          ],
        );
        const employeeAsset = await loadAsset(tx, id);
        if (!employeeAsset) throw denied("Asset not found or access denied.");
        return { employeeAsset };
      }

      const assignedByName = await assignmentActorName(tx, actor, organizationId);
      const created = await tx.query<{ id: string }>(
        `INSERT INTO employee_asset (
           organization_id, branch_id, employee_member_id, name, category,
           asset_tag, serial_number, status, notes, acknowledgement_required,
           acknowledgement_status, assigned_by_uid, assigned_by_name, assigned_at
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, now())
         RETURNING id`,
        [
          organizationId,
          branchId,
          employeeId,
          name,
          category,
          assetTag,
          serialNumber ?? null,
          status,
          notes ?? null,
          requireAcknowledgement && status !== "returned",
          requireAcknowledgement && status !== "returned"
            ? "pending"
            : "not_required",
          actor.uid,
          assignedByName,
        ],
      );
      const employeeAsset = created[0]
        ? await loadAsset(tx, created[0].id)
        : null;
      if (!employeeAsset) throw denied("Asset could not be saved.");
      return { employeeAsset };
    });
  },

  AcknowledgeMyEmployeeAsset: async ({ db, actor }, vars) => {
    if (actor.role !== "employee" || !actor.organizationId) throw denied();
    const assetId = reqId(vars, "assetId");
    return db.transaction(async (tx) => {
      const rows = await tx.query<{
        id: string;
        acknowledgementRequired: boolean;
        acknowledgementStatus: string;
        employeeName: string;
      }>(
        `SELECT ea.id,
                ea.acknowledgement_required AS "acknowledgementRequired",
                ea.acknowledgement_status AS "acknowledgementStatus",
                m.full_name AS "employeeName"
           FROM employee_asset ea
           JOIN organization_member m ON m.id = ea.employee_member_id
          WHERE ea.id = $1
            AND ea.organization_id = $2
            AND m.organization_id = $2
            AND m.auth_uid = $3
            AND m.role = 'employee'
          FOR UPDATE OF ea`,
        [assetId, actor.organizationId, actor.uid],
      );
      const assignedAsset = rows[0];
      if (!assignedAsset) throw denied("Asset not found or access denied.");
      if (assignedAsset.acknowledgementStatus === "acknowledged") {
        const employeeAsset = await loadAsset(tx, assetId);
        if (!employeeAsset) throw denied("Asset not found or access denied.");
        return { employeeAsset };
      }
      if (
        !assignedAsset.acknowledgementRequired ||
        assignedAsset.acknowledgementStatus !== "pending"
      ) {
        throw invalid("This asset does not require acknowledgment.");
      }
      await tx.query(
        `UPDATE employee_asset
            SET acknowledgement_status = 'acknowledged',
                acknowledged_at = now(),
                acknowledged_by_uid = $2,
                acknowledged_by_name = $3,
                updated_at = now()
          WHERE id = $1 AND organization_id = $4`,
        [assetId, actor.uid, assignedAsset.employeeName, actor.organizationId],
      );
      const employeeAsset = await loadAsset(tx, assetId);
      if (!employeeAsset) throw denied("Asset not found or access denied.");
      return { employeeAsset };
    });
  },

  DeleteEmployeeAsset: async ({ db, actor }, vars) => {
    const organizationId = requireEditor(actor);
    const assetId = reqId(vars, "assetId");
    return db.transaction(async (tx) => {
      const existing = await tx.query<AssetScope>(
        `SELECT id,
                organization_id AS "organizationId",
                branch_id AS "branchId",
                employee_member_id AS "employeeId"
           FROM employee_asset
          WHERE id = $1
          FOR UPDATE`,
        [assetId],
      );
      if (!existing[0]) throw denied("Asset not found or access denied.");
      await ensureAssetScope(tx, actor, existing[0], vars);
      if (actor.role === "branchManager") {
        const activeBranchId = reqId(vars, "activeBranchId");
        if (activeBranchId !== existing[0].branchId) throw denied();
        await requireEmployeeAtBranch(
          tx,
          organizationId,
          existing[0].branchId,
          existing[0].employeeId,
        );
      }
      const deleted = await tx.query<{ id: string }>(
        `DELETE FROM employee_asset
          WHERE id = $1 AND organization_id = $2
          RETURNING id`,
        [assetId, organizationId],
      );
      if (!deleted[0]) throw denied("Asset not found or access denied.");
      return { deleted: true };
    });
  },
};
