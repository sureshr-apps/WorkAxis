import { reqEnum, reqNumber, reqString } from "../../util/input";
import { requireOrgAdminScope, requirePlatform } from "../authz";
import type { OperationRegistry } from "../operation";
import { insertReturningId, raw, select, type UpdateField, updateById } from "../sql";
import { optEnum, reqDate, reqId, reqInt } from "../vars";

const STATUSES = ["active", "suspended"] as const;
const EVENT_TYPES = ["LICENSE_ASSIGNED", "PLAN_CHANGED", "TERMS_MODIFIED", "RENEWED"] as const;

const AGREEMENT_COLUMNS = `id, agreement_reference AS "agreementReference", plan_name AS "planName",
  plan_tier AS "planTier", negotiated_price AS "negotiatedPrice",
  annual_maintenance_price AS "annualMaintenancePrice", max_stores AS "maxStores",
  max_users AS "maxUsers", to_char(start_date, 'YYYY-MM-DD') AS "startDate",
  to_char(expiry_date, 'YYYY-MM-DD') AS "expiryDate", status`;

const EVENT_COLUMNS = `id, event_type AS "eventType", plan_name AS "planName", plan_tier AS "planTier",
  validity_period AS "validityPeriod", stores_count AS "storesCount", users_count AS "usersCount",
  one_time_price AS "oneTimePrice", annual_maintenance_price AS "annualMaintenancePrice",
  created_at AS "createdAt"`;

const MAX_PRICE = 1e12;

const AGREEMENT_UPDATE_FIELDS: UpdateField[] = [
  { key: "planName", column: "plan_name", kind: "string", max: 200 },
  { key: "planTier", column: "plan_tier", kind: "string", max: 100 },
  { key: "negotiatedPrice", column: "negotiated_price", kind: "float", min: 0, max: MAX_PRICE },
  { key: "annualMaintenancePrice", column: "annual_maintenance_price", kind: "float", min: 0, max: MAX_PRICE },
  { key: "maxStores", column: "max_stores", kind: "int", min: 0, max: 1_000_000 },
  { key: "maxUsers", column: "max_users", kind: "int", min: 0, max: 1_000_000 },
  { key: "startDate", column: "start_date", kind: "date" },
  { key: "expiryDate", column: "expiry_date", kind: "date" },
  { key: "status", column: "status", kind: "string", max: 20 },
];

export const commercialOps: OperationRegistry = {
  GetCommercialAgreementByOrg: async ({ db, actor }, vars) => {
    const orgId = reqId(vars, "orgId");
    requireOrgAdminScope(actor, orgId);
    const commercialAgreements = await select(
      db,
      `SELECT ${AGREEMENT_COLUMNS} FROM commercial_agreement
        WHERE organization_id = $1 ORDER BY created_at DESC LIMIT 1`,
      [orgId],
    );
    return { commercialAgreements };
  },

  ListLicenseEventsByOrg: async ({ db, actor }, vars) => {
    const orgId = reqId(vars, "orgId");
    requireOrgAdminScope(actor, orgId);
    const licenseEvents = await select(
      db,
      `SELECT ${EVENT_COLUMNS} FROM license_event
        WHERE organization_id = $1 ORDER BY created_at DESC, id DESC`,
      [orgId],
    );
    return { licenseEvents };
  },

  CreateCommercialAgreement: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const status = optEnum(vars, "status", STATUSES);
    const commercialAgreement_insert = await insertReturningId(
      db,
      "commercial_agreement",
      [
        ["id", raw("gen_random_uuid()::text")],
        ["organization_id", reqId(vars, "orgId")],
        ["agreement_reference", reqString(vars, "agreementReference", 1, 100)],
        ["plan_name", reqString(vars, "planName", 1, 200)],
        ["plan_tier", reqString(vars, "planTier", 1, 100)],
        ["negotiated_price", reqNumber(vars, "negotiatedPrice", 0, MAX_PRICE)],
        ["annual_maintenance_price", reqNumber(vars, "annualMaintenancePrice", 0, MAX_PRICE)],
        ["max_stores", reqInt(vars, "maxStores", 0, 1_000_000)],
        ["max_users", reqInt(vars, "maxUsers", 0, 1_000_000)],
        ["start_date", reqDate(vars, "startDate"), "date"],
        ["expiry_date", reqDate(vars, "expiryDate"), "date"],
        ["status", status ?? "active"],
        ["created_at", raw("now()")],
      ],
      {
        unique: "A commercial agreement with this reference already exists.",
        fk: "Organization not found.",
      },
    );
    return { commercialAgreement_insert };
  },

  UpdateCommercialAgreement: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    optEnum(vars, "status", STATUSES);
    const id = reqId(vars, "id");
    const commercialAgreement_update = await updateById(
      db,
      "commercial_agreement",
      id,
      AGREEMENT_UPDATE_FIELDS,
      vars,
      { unique: "A commercial agreement with this reference already exists." },
    );
    return { commercialAgreement_update };
  },

  CreateLicenseEvent: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const eventType = reqEnum(vars, "eventType", EVENT_TYPES);
    const licenseEvent_insert = await insertReturningId(
      db,
      "license_event",
      [
        ["id", raw("gen_random_uuid()::text")],
        ["organization_id", reqId(vars, "orgId")],
        ["event_type", eventType],
        ["plan_name", reqString(vars, "planName", 1, 200)],
        ["plan_tier", reqString(vars, "planTier", 1, 100)],
        ["validity_period", reqString(vars, "validityPeriod", 1, 100)],
        ["stores_count", reqInt(vars, "storesCount", 0, 1_000_000)],
        ["users_count", reqInt(vars, "usersCount", 0, 1_000_000)],
        ["one_time_price", reqNumber(vars, "oneTimePrice", 0, MAX_PRICE)],
        ["annual_maintenance_price", reqNumber(vars, "annualMaintenancePrice", 0, MAX_PRICE)],
        ["created_at", raw("now()")],
      ],
      { fk: "Organization not found." },
    );
    return { licenseEvent_insert };
  },
};
