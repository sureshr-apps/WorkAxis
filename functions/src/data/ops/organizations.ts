import { denied } from "../../errors";
import { optString, reqEnum, reqString } from "../../util/input";
import { isPlatform, requireOrgAdminScope, requirePlatform } from "../authz";
import type { OperationRegistry } from "../operation";
import {
  countRows,
  groupRows,
  insertReturningId,
  paged,
  Query,
  raw,
  select,
  selectOne,
  type UpdateField,
  updateById,
} from "../sql";
import { optId, optText, pageVars, reqId } from "../vars";

const LIST_COLUMNS = `id, name, code, category, country, status, currency, created_at AS "createdAt"`;

const DETAIL_COLUMNS = `${LIST_COLUMNS}, logo_url AS "logoUrl", tax_identification AS "taxIdentification",
  description, contact_name AS "contactName", contact_email AS "contactEmail",
  contact_phone AS "contactPhone", address`;

const STATUSES = ["active", "suspended"] as const;

/** Columns UpdateOrganization may change (status is deliberately absent). */
const UPDATE_FIELDS: UpdateField[] = [
  { key: "name", column: "name", kind: "string", max: 200 },
  { key: "category", column: "category", kind: "string", nullable: true, max: 100 },
  { key: "country", column: "country", kind: "string", nullable: true, max: 100 },
  { key: "currency", column: "currency", kind: "string", nullable: true, max: 10 },
  { key: "logoUrl", column: "logo_url", kind: "string", nullable: true, max: 2048 },
  { key: "taxIdentification", column: "tax_identification", kind: "string", nullable: true, max: 100 },
  { key: "description", column: "description", kind: "string", nullable: true, max: 2000 },
  { key: "contactName", column: "contact_name", kind: "string", nullable: true, max: 200 },
  { key: "contactEmail", column: "contact_email", kind: "string", nullable: true, max: 320 },
  { key: "contactPhone", column: "contact_phone", kind: "string", nullable: true, max: 50 },
  { key: "address", column: "address", kind: "string", nullable: true, max: 1000 },
];

export const organizationsOps: OperationRegistry = {
  ListOrganizations: async ({ db, actor }) => {
    requirePlatform(actor);
    const organizations = await select(
      db,
      `SELECT ${LIST_COLUMNS} FROM organization ORDER BY created_at DESC`,
    );
    return { organizations };
  },

  ListOrganizationsPaged: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const { limit, offset } = pageVars(vars);
    const q = new Query()
      .contains("name", optText(vars, "nameContains", 200))
      .eq("status", optString(vars, "status", 1, 50));
    const { rows, total } = await paged(db, {
      columns: LIST_COLUMNS,
      from: "organization",
      q,
      orderBy: "created_at DESC, id DESC",
      limit,
      offset,
    });
    return { organizations: rows, total };
  },

  GetOrganizationById: async ({ db, actor }, vars) => {
    const id = reqId(vars, "id");
    if (!isPlatform(actor) && actor.organizationId !== id) throw denied();
    const organization = await selectOne(
      db,
      `SELECT ${DETAIL_COLUMNS} FROM organization WHERE id = $1`,
      [id],
    );
    return { organization };
  },

  GetOrganizationStats: async ({ db, actor }, vars) => {
    const orgId = reqId(vars, "orgId");
    requireOrgAdminScope(actor, orgId);
    const branchCount = await countRows(
      db,
      `SELECT count(*)::int AS "_count" FROM branch WHERE organization_id = $1`,
      [orgId],
    );
    const memberCount = await countRows(
      db,
      `SELECT count(*)::int AS "_count" FROM organization_member WHERE organization_id = $1`,
      [orgId],
    );
    return { branchCount, memberCount };
  },

  GetPlatformStats: async ({ db, actor }) => {
    requirePlatform(actor);
    const organizationsByStatus = await groupRows(
      db,
      `SELECT status, count(*)::int AS "_count" FROM organization GROUP BY status ORDER BY status`,
    );
    const platformAdminCount = await countRows(
      db,
      `SELECT count(*)::int AS "_count" FROM organization_member
        WHERE role IN ('platformOwner', 'platformAdmin')`,
    );
    return { organizationsByStatus, platformAdminCount };
  },

  CreateOrganization: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const status = vars.status === undefined || vars.status === null
      ? undefined
      : reqEnum(vars, "status", STATUSES);
    const organization_insert = await insertReturningId(
      db,
      "organization",
      [
        ["id", optId(vars, "id") ?? raw("gen_random_uuid()::text")],
        ["name", reqString(vars, "name", 1, 200)],
        ["code", reqString(vars, "code", 1, 50)],
        ["category", optText(vars, "category", 100)],
        ["country", optText(vars, "country", 100)],
        ["status", status ?? "active"],
        ["currency", optText(vars, "currency", 10) ?? "INR"],
        ["tax_identification", optText(vars, "taxIdentification", 100)],
        ["description", optText(vars, "description")],
        ["contact_name", optText(vars, "contactName", 200)],
        ["contact_email", optText(vars, "contactEmail", 320)],
        ["contact_phone", optText(vars, "contactPhone", 50)],
        ["address", optText(vars, "address", 1000)],
        ["created_at", raw("now()")],
      ],
      { unique: "An organization with this code already exists." },
    );
    return { organization_insert };
  },

  // `status` cannot be changed here (suspension must also revoke member
  // access, so it goes through the setOrganizationStatus callable).
  UpdateOrganization: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    if (vars.status !== undefined && vars.status !== null) throw denied();
    const id = reqId(vars, "id");
    const organization_update = await updateById(db, "organization", id, UPDATE_FIELDS, vars);
    return { organization_update };
  },
};
