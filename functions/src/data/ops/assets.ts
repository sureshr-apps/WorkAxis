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
  ea.notes`;

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

  SaveEmployeeAsset: async ({ db, actor }, vars) => {
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
        const existing = await tx.query<AssetScope>(
          `SELECT id,
                  organization_id AS "organizationId",
                  branch_id AS "branchId",
                  employee_member_id AS "employeeId"
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
                  updated_at = now()
            WHERE id = $1 AND organization_id = $10`,
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
            organizationId,
          ],
        );
        const employeeAsset = await loadAsset(tx, id);
        if (!employeeAsset) throw denied("Asset not found or access denied.");
        return { employeeAsset };
      }

      const inserted = await tx.query<{ id: string }>(
        `INSERT INTO employee_asset (
           organization_id, branch_id, employee_member_id, name, category,
           asset_tag, serial_number, status, notes
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
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
        ],
      );
      const employeeAsset = inserted[0]
        ? await loadAsset(tx, inserted[0].id)
        : null;
      if (!employeeAsset) throw denied("Asset could not be saved.");
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
