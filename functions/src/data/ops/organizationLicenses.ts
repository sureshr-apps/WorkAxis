import type { SqlExecutor } from "../../db/executor";
import { isUniqueViolation } from "../../db";
import { conflict, invalid, notFound, precondition } from "../../errors";
import {
  InvalidLicenseTermError,
  type LicenseRenewalTerm,
  resolveLicenseRenewalTerm,
} from "../../licenses/licenseRenewal";
import { deriveLicenseStatus, LICENSE_TODAY_SQL } from "../../licenses/licenseStatus";
import { lockOrganizationLicense, type LockedLicense } from "../../sql/licenses";
import { requirePlatform } from "../authz";
import type { OperationRegistry } from "../operation";
import { select, selectOne } from "../sql";
import { reqDate, reqId } from "../vars";
import { reqLicenseTerm, reqPrice } from "./licenseInput";

const NO_LICENSE = "This organization does not have a license.";
const ALREADY_LICENSED = "This organization already has a license.";
const ACTIVE_PLAN_REQUIRED = "Select an active license plan.";
const HIGHER_PLAN_REQUIRED = "Only a higher-level active plan can be selected.";
const RENEWAL_TERM_INVALID =
  "The renewal must start after the current expiry date and end after its start date.";

type LicenseEventType = "assigned" | "plan_changed" | "commercial_terms_modified" | "renewed";

interface LicenseEvent {
  organizationId: string;
  eventType: LicenseEventType;
  planId: string;
  startDate: string;
  expiryDate: string;
  negotiatedPrice: number;
  maintenancePrice: number;
}

interface PlanRow {
  id: string;
  level: number;
  status: string;
}

interface LicenseDetailRow {
  id: string;
  organizationId: string;
  planId: string;
  startDate: string;
  expiryDate: string;
  negotiatedPrice: number;
  maintenancePrice: number;
  planCode: string;
  planName: string;
  planLevel: number;
  planMaxStores: number;
  planMaxUsers: number;
  planStatus: string;
  today: string;
}

const LICENSE_DETAIL_SQL = `SELECT ol.id, ol.organization_id AS "organizationId", ol.plan_id AS "planId",
    to_char(ol.start_date, 'YYYY-MM-DD') AS "startDate",
    to_char(ol.expiry_date, 'YYYY-MM-DD') AS "expiryDate",
    ol.negotiated_price AS "negotiatedPrice", ol.maintenance_price AS "maintenancePrice",
    p.plan_code AS "planCode", p.name AS "planName", p.level AS "planLevel",
    p.max_stores AS "planMaxStores", p.max_users AS "planMaxUsers", p.status AS "planStatus",
    to_char(${LICENSE_TODAY_SQL}, 'YYYY-MM-DD') AS "today"
  FROM organization_license ol
  JOIN license_plan p ON p.id = ol.plan_id
  WHERE ol.organization_id = $1`;

/** Newest first; plan name, level and limits come from the live plan row. */
const LICENSE_HISTORY_SQL = `SELECT h.id, h.event_type AS "eventType", h.event_at AS "eventAt",
    h.plan_id AS "planId", p.plan_code AS "planCode", p.name AS "planName", p.level AS "planLevel",
    p.max_stores AS "maxStores", p.max_users AS "maxUsers",
    to_char(h.start_date, 'YYYY-MM-DD') AS "startDate",
    to_char(h.expiry_date, 'YYYY-MM-DD') AS "expiryDate",
    h.negotiated_price AS "negotiatedPrice", h.maintenance_price AS "maintenancePrice"
  FROM license_history h
  JOIN license_plan p ON p.id = h.plan_id
  WHERE h.organization_id = $1
  ORDER BY h.event_at DESC, h.id DESC`;

async function findPlan(tx: SqlExecutor, planId: string): Promise<PlanRow | null> {
  const rows = await tx.query<PlanRow>(
    `SELECT id, level, status FROM license_plan WHERE id = $1`,
    [planId],
  );
  return rows[0] ?? null;
}

/** The organization's license, locked for the rest of the transaction. */
async function requireLicense(tx: SqlExecutor, organizationId: string): Promise<LockedLicense> {
  const license = await lockOrganizationLicense(tx, organizationId);
  if (!license) throw precondition(NO_LICENSE);
  return license;
}

/** Inserts the organization's license row; a second license for the same organization is a conflict. */
async function insertLicense(
  tx: SqlExecutor,
  row: {
    organizationId: string;
    planId: string;
    startDate: string;
    expiryDate: string;
    negotiatedPrice: number;
    maintenancePrice: number;
  },
): Promise<string> {
  try {
    const rows = await tx.query<{ id: string }>(
      `INSERT INTO organization_license
         (organization_id, plan_id, start_date, expiry_date, negotiated_price, maintenance_price)
       VALUES ($1, $2, $3::date, $4::date, $5, $6)
       RETURNING id`,
      [row.organizationId, row.planId, row.startDate, row.expiryDate, row.negotiatedPrice, row.maintenancePrice],
    );
    return rows[0].id;
  } catch (e) {
    if (isUniqueViolation(e)) throw conflict(ALREADY_LICENSED);
    throw e;
  }
}

async function recordEvent(tx: SqlExecutor, event: LicenseEvent): Promise<void> {
  await tx.query(
    `INSERT INTO license_history
       (organization_id, event_type, plan_id, start_date, expiry_date, negotiated_price, maintenance_price)
     VALUES ($1, $2, $3, $4::date, $5::date, $6, $7)`,
    [
      event.organizationId,
      event.eventType,
      event.planId,
      event.startDate,
      event.expiryDate,
      event.negotiatedPrice,
      event.maintenancePrice,
    ],
  );
}

function toLicenseView(row: LicenseDetailRow) {
  return {
    id: row.id,
    organizationId: row.organizationId,
    planId: row.planId,
    startDate: row.startDate,
    expiryDate: row.expiryDate,
    negotiatedPrice: row.negotiatedPrice,
    maintenancePrice: row.maintenancePrice,
    status: deriveLicenseStatus(row.startDate, row.expiryDate, row.today),
    plan: {
      id: row.planId,
      planCode: row.planCode,
      name: row.planName,
      level: row.planLevel,
      maxStores: row.planMaxStores,
      maxUsers: row.planMaxUsers,
      status: row.planStatus,
    },
  };
}

/**
 * Organization license operations (platform only). Each organization has at
 * most one license row; every change writes one license_history row.
 */
export const organizationLicenseOps: OperationRegistry = {
  GetOrganizationLicense: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const organizationId = reqId(vars, "organizationId");
    const row = await selectOne<LicenseDetailRow>(db, LICENSE_DETAIL_SQL, [organizationId]);
    return { organizationLicense: row ? toLicenseView(row) : null };
  },

  GetOrganizationLicenseHistory: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const organizationId = reqId(vars, "organizationId");
    const licenseHistory = await select(db, LICENSE_HISTORY_SQL, [organizationId]);
    return { licenseHistory };
  },

  AssignOrganizationLicense: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const organizationId = reqId(vars, "organizationId");
    const planId = reqId(vars, "planId");
    const term = reqLicenseTerm(vars);
    const negotiatedPrice = reqPrice(vars, "negotiatedPrice");
    const maintenancePrice = reqPrice(vars, "maintenancePrice");
    return db.transaction(async (tx) => {
      // The organization row lock serialises concurrent assignments.
      const [organization] = await tx.query<{ id: string }>(
        `SELECT id FROM organization WHERE id = $1 FOR UPDATE`,
        [organizationId],
      );
      if (!organization) throw notFound("Organization not found.");
      const existing = await tx.query<{ id: string }>(
        `SELECT id FROM organization_license WHERE organization_id = $1`,
        [organizationId],
      );
      if (existing.length > 0) throw conflict(ALREADY_LICENSED);
      const plan = await findPlan(tx, planId);
      if (!plan || plan.status !== "active") throw precondition(ACTIVE_PLAN_REQUIRED);
      const id = await insertLicense(tx, {
        organizationId,
        planId: plan.id,
        ...term,
        negotiatedPrice,
        maintenancePrice,
      });
      await recordEvent(tx, {
        organizationId,
        eventType: "assigned",
        planId: plan.id,
        ...term,
        negotiatedPrice,
        maintenancePrice,
      });
      return { organizationLicense_insert: { id } };
    });
  },

  ChangeOrganizationLicensePlan: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const organizationId = reqId(vars, "organizationId");
    const targetPlanId = reqId(vars, "targetPlanId");
    const negotiatedPrice = reqPrice(vars, "negotiatedPrice");
    const maintenancePrice = reqPrice(vars, "maintenancePrice");
    return db.transaction(async (tx) => {
      const current = await requireLicense(tx, organizationId);
      const target = await findPlan(tx, targetPlanId);
      const higher =
        target !== null &&
        target.status === "active" &&
        current.planLevel !== null &&
        target.level > current.planLevel;
      if (!target || !higher) throw precondition(HIGHER_PLAN_REQUIRED);
      await tx.query(
        `UPDATE organization_license
            SET plan_id = $2, negotiated_price = $3, maintenance_price = $4, updated_at = now()
          WHERE id = $1`,
        [current.id, target.id, negotiatedPrice, maintenancePrice],
      );
      await recordEvent(tx, {
        organizationId,
        eventType: "plan_changed",
        planId: target.id,
        startDate: current.startDate,
        expiryDate: current.expiryDate,
        negotiatedPrice,
        maintenancePrice,
      });
      return { organizationLicense_update: { id: current.id } };
    });
  },

  ModifyOrganizationCommercialTerms: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const organizationId = reqId(vars, "organizationId");
    const negotiatedPrice = reqPrice(vars, "negotiatedPrice");
    const maintenancePrice = reqPrice(vars, "maintenancePrice");
    return db.transaction(async (tx) => {
      const current = await requireLicense(tx, organizationId);
      const unchanged =
        current.negotiatedPrice === negotiatedPrice &&
        current.maintenancePrice === maintenancePrice;
      if (unchanged) return { organizationLicense_update: { id: current.id } };
      await tx.query(
        `UPDATE organization_license
            SET negotiated_price = $2, maintenance_price = $3, updated_at = now()
          WHERE id = $1`,
        [current.id, negotiatedPrice, maintenancePrice],
      );
      await recordEvent(tx, {
        organizationId,
        eventType: "commercial_terms_modified",
        planId: current.planId,
        startDate: current.startDate,
        expiryDate: current.expiryDate,
        negotiatedPrice,
        maintenancePrice,
      });
      return { organizationLicense_update: { id: current.id } };
    });
  },

  RenewOrganizationLicense: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const organizationId = reqId(vars, "organizationId");
    const planId = reqId(vars, "planId");
    const newStartDate = reqDate(vars, "newStartDate");
    const newExpiryDate = reqDate(vars, "newExpiryDate");
    const negotiatedPrice = reqPrice(vars, "negotiatedPrice");
    const maintenancePrice = reqPrice(vars, "maintenancePrice");
    return db.transaction(async (tx) => {
      const current = await requireLicense(tx, organizationId);
      let term: LicenseRenewalTerm;
      try {
        term = resolveLicenseRenewalTerm({
          currentStartDate: current.startDate,
          currentExpiryDate: current.expiryDate,
          currentPlanStatus: current.planStatus,
          newStartDate,
          newExpiryDate,
          today: current.today,
        });
      } catch (e) {
        if (e instanceof InvalidLicenseTermError) throw invalid(RENEWAL_TERM_INVALID);
        throw e;
      }
      const plan = await findPlan(tx, planId);
      if (!plan || plan.status !== "active") throw precondition(ACTIVE_PLAN_REQUIRED);
      await tx.query(
        `UPDATE organization_license
            SET plan_id = $2, start_date = $3::date, expiry_date = $4::date,
                negotiated_price = $5, maintenance_price = $6, updated_at = now()
          WHERE id = $1`,
        [current.id, plan.id, term.startDate, term.expiryDate, negotiatedPrice, maintenancePrice],
      );
      await recordEvent(tx, {
        organizationId,
        eventType: "renewed",
        planId: plan.id,
        startDate: term.startDate,
        expiryDate: term.expiryDate,
        negotiatedPrice,
        maintenancePrice,
      });
      return { organizationLicense_update: { id: current.id } };
    });
  },
};
