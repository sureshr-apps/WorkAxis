import type { SqlExecutor } from "../../db/executor";
import { isUniqueViolation } from "../../db";
import { conflict, invalid, precondition } from "../../errors";
import { generatePlanCode } from "../../licenses/planCode";
import { reqEnum, reqString } from "../../util/input";
import { requirePlatform } from "../authz";
import type { OperationRegistry } from "../operation";
import { likeContains, Query, select, selectOne } from "../sql";
import { optEnum, optText, reqId, reqInt } from "../vars";

const PLAN_STATUSES = ["active", "inactive"] as const;
const PLAN_CODE_ATTEMPTS = 5;
const REFERENCED_MESSAGE =
  "This plan is referenced by existing licenses or history and cannot be deleted. Deactivate it instead.";

const PLAN_COLUMNS = `p.id, p.plan_code AS "planCode", p.name, p.description, p.level,
  p.max_stores AS "maxStores", p.max_users AS "maxUsers", p.status`;

interface PlanFields {
  name: string;
  /** Null when the caller omitted the description (create: empty; update: unchanged). */
  description: string | null;
  level: number;
  maxStores: number;
  maxUsers: number;
}

function reqPlanFields(vars: Record<string, unknown>): PlanFields {
  return {
    name: reqString(vars, "name", 2, 60),
    description: optionalDescription(vars),
    level: reqInt(vars, "level", 1, 1_000_000),
    maxStores: reqInt(vars, "maxStores", 1, 1_000_000),
    maxUsers: reqInt(vars, "maxUsers", 1, 1_000_000),
  };
}

/** Trimmed text of at most 200 characters; empty is allowed. */
function optionalDescription(vars: Record<string, unknown>): string | null {
  const value = vars.description;
  if (value === undefined || value === null) return null;
  if (typeof value !== "string") throw invalid("description must be text.");
  const trimmed = value.trim();
  if (trimmed.length > 200) throw invalid("description must be at most 200 characters.");
  return trimmed;
}

/** The violated constraint name for a unique violation, or undefined for any other error. */
function uniqueTarget(e: unknown): string | undefined {
  if (!isUniqueViolation(e)) return undefined;
  const detail = e as { constraint?: string; message?: string };
  return detail.constraint ?? detail.message ?? "";
}

function planConflict(target: string): unknown {
  if (target.includes("level")) return conflict("A license plan with this level already exists.");
  return conflict("A license plan with this name already exists.");
}

async function isReferenced(db: SqlExecutor, id: string): Promise<boolean> {
  const row = await selectOne<{ referenced: boolean }>(
    db,
    `SELECT EXISTS (SELECT 1 FROM organization_license WHERE plan_id = $1)
         OR EXISTS (SELECT 1 FROM license_history WHERE plan_id = $1) AS "referenced"`,
    [id],
  );
  return row?.referenced === true;
}

/**
 * License plan catalogue (platform only). Plans carry no prices; prices belong
 * to each organization's license.
 */
export const licensePlanOps: OperationRegistry = {
  ListLicensePlans: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const q = new Query().eq("p.status", optEnum(vars, "status", PLAN_STATUSES));
    const text = optText(vars, "query", 200);
    if (text !== undefined) {
      const pattern = q.bind(likeContains(text));
      q.and(`(p.name ILIKE ${pattern} OR p.plan_code ILIKE ${pattern})`);
    }
    const licensePlans = await select(
      db,
      `SELECT ${PLAN_COLUMNS},
          (SELECT count(*)::int FROM organization_license ol WHERE ol.plan_id = p.id) AS "assignedOrganizations"
        FROM license_plan p ${q.where}
        ORDER BY p.level ASC, p.id ASC`,
      q.params,
    );
    // Platform-wide totals; the list filters do not narrow the summary.
    const summary = await selectOne(
      db,
      `SELECT (SELECT count(*)::int FROM license_plan) AS "totalPlans",
              (SELECT count(*)::int FROM license_plan WHERE status = 'active') AS "activePlans",
              (SELECT count(*)::int FROM license_plan WHERE status = 'inactive') AS "inactivePlans",
              (SELECT count(*)::int FROM organization_license) AS "assignedOrganizations"`,
    );
    return { licensePlans, summary };
  },

  CreateLicensePlan: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const fields = reqPlanFields(vars);
    const status = reqEnum(vars, "status", PLAN_STATUSES);
    for (let attempt = 1; attempt <= PLAN_CODE_ATTEMPTS; attempt++) {
      try {
        const rows = await db.query<{ id: string; planCode: string }>(
          `INSERT INTO license_plan (plan_code, name, description, level, max_stores, max_users, status)
           VALUES ($1, $2, $3, $4, $5, $6, $7)
           RETURNING id, plan_code AS "planCode"`,
          [
            generatePlanCode(fields.name),
            fields.name,
            fields.description ?? "",
            fields.level,
            fields.maxStores,
            fields.maxUsers,
            status,
          ],
        );
        return { licensePlan_insert: rows[0] };
      } catch (e) {
        const target = uniqueTarget(e);
        if (target === undefined) throw e;
        // A plan code collision is retried with fresh random digits; any other
        // unique violation (level or name) is a real conflict.
        if (!target.includes("plan_code")) throw planConflict(target);
      }
    }
    throw conflict("Could not generate a unique plan code. Try again.");
  },

  UpdateLicensePlan: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const id = reqId(vars, "id");
    const fields = reqPlanFields(vars);
    try {
      const rows = await db.query<{ id: string }>(
        `UPDATE license_plan
            SET name = $2, description = COALESCE($3::text, description), level = $4,
                max_stores = $5, max_users = $6, updated_at = now()
          WHERE id = $1
        RETURNING id`,
        [id, fields.name, fields.description, fields.level, fields.maxStores, fields.maxUsers],
      );
      return { licensePlan_update: rows[0] ?? null };
    } catch (e) {
      const target = uniqueTarget(e);
      if (target === undefined) throw e;
      throw planConflict(target);
    }
  },

  ChangeLicensePlanStatus: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const id = reqId(vars, "id");
    const status = reqEnum(vars, "status", PLAN_STATUSES);
    const rows = await db.query<{ id: string; status: string }>(
      `UPDATE license_plan SET status = $2, updated_at = now()
        WHERE id = $1
        RETURNING id, status`,
      [id, status],
    );
    return { licensePlan_update: rows[0] ?? null };
  },

  DeleteLicensePlan: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const id = reqId(vars, "id");
    if (await isReferenced(db, id)) throw precondition(REFERENCED_MESSAGE);
    try {
      const rows = await db.query<{ id: string }>(
        `DELETE FROM license_plan WHERE id = $1 RETURNING id`,
        [id],
      );
      return { licensePlan_delete: rows[0] ?? null };
    } catch (e) {
      // A license or history row was created after the check above.
      if ((e as { code?: string }).code === "23503") throw precondition(REFERENCED_MESSAGE);
      throw e;
    }
  },
};
