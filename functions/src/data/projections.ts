import { select, selectOne } from "./sql";
import type { SqlExecutor } from "../db/executor";
import { placeholders } from "../db";

type Row = Record<string, unknown>;

/** `alias.column AS "camel"` for the requested contract fields only. */
function cols(alias: string, map: Record<string, string>, names: readonly string[]): string {
  return names.map((n) => `${alias}.${map[n]} AS "${n}"`).join(", ");
}

const BRANCH_MAP: Record<string, string> = {
  id: "id",
  name: "name",
  code: "code",
  location: "location",
  status: "status",
  isMainBranch: "is_main_branch",
  geofenceRadiusMeters: "geofence_radius_meters",
  latitude: "latitude",
  longitude: "longitude",
  kioskEnabled: "kiosk_enabled",
};

export const BRANCH_FIELDS = Object.keys(BRANCH_MAP);
export const branchCols = (alias: string, names: readonly string[] = BRANCH_FIELDS): string =>
  cols(alias, BRANCH_MAP, names);

const MEMBER_MAP: Record<string, string> = {
  id: "id",
  authUid: "auth_uid",
  fullName: "full_name",
  username: "username",
  email: "email",
  phone: "phone",
  role: "role",
  status: "status",
  employeeCode: "employee_code",
  createdAt: "created_at",
};

export const memberCols = (alias: string, names: readonly string[]): string =>
  cols(alias, MEMBER_MAP, names);

/** The member fields shared by the list/get member operations. */
export const MEMBER_LIST_FIELDS = [
  "id",
  "authUid",
  "fullName",
  "username",
  "email",
  "phone",
  "role",
  "status",
  "employeeCode",
] as const;

const RETURN_MAP: Record<string, string> = {
  id: "id",
  employeeId: "employee_id",
  employeeUid: "employee_uid",
  employeeName: "employee_name",
  customerName: "customer_name",
  invoiceNumber: "invoice_number",
  status: "status",
  returnReason: "return_reason",
  amount: "amount",
  productTitle: "product_title",
  quantity: "quantity",
  unit: "unit",
  billImageUrl: "bill_image_url",
  remarks: "remarks",
  reviewerNotes: "reviewer_notes",
  reviewerUid: "reviewer_uid",
  reviewerName: "reviewer_name",
  reviewedAt: "reviewed_at",
  createdAt: "created_at",
  billNumber: "bill_number",
  returnDate: "return_date",
};

export const returnCols = (alias: string, names: readonly string[]): string =>
  cols(alias, RETURN_MAP, names);

/** Return fields selected by the manager / org list operations. */
export const RETURN_MANAGER_FIELDS = [
  "id",
  "employeeId",
  "employeeUid",
  "employeeName",
  "customerName",
  "invoiceNumber",
  "status",
  "returnReason",
  "amount",
  "productTitle",
  "quantity",
  "unit",
  "billImageUrl",
  "remarks",
  "reviewerNotes",
  "reviewerUid",
  "reviewerName",
  "reviewedAt",
  "createdAt",
  "billNumber",
  "returnDate",
] as const;

/** Splits flat `__`-less helper columns into the nested `branch: {id, name}` object. */
export function nestBranchRef(row: Row): Row {
  const { branchRefId, branchRefName, ...rest } = row;
  return { ...rest, branch: { id: branchRefId, name: branchRefName } };
}

/** Adds `userBranchAssignments_on_member: [{ branch: { id[, name] } }]` to member rows. */
export async function withMemberAssignments(
  db: SqlExecutor,
  members: Row[],
  includeName = false,
): Promise<Row[]> {
  if (members.length === 0) return members;
  const ids = members.map((m) => m.id as string);
  const rows = await select<{ memberId: string; branchId: string; branchName: string }>(
    db,
    `SELECT a.member_id AS "memberId", a.branch_id AS "branchId", b.name AS "branchName"
       FROM user_branch_assignment a JOIN branch b ON b.id = a.branch_id
      WHERE a.member_id IN (${placeholders(1, ids.length)})
      ORDER BY a.assigned_at ASC, a.id ASC`,
    ids,
  );
  return members.map((m) => ({
    ...m,
    userBranchAssignments_on_member: rows
      .filter((r) => r.memberId === m.id)
      .map((r) => ({
        branch: includeName ? { id: r.branchId, name: r.branchName } : { id: r.branchId },
      })),
  }));
}

export interface BranchOrg {
  id: string;
  organizationId: string;
}

/** Branch id + owning organization, or null when it does not exist. */
export function findBranchOrg(db: SqlExecutor, branchId: string): Promise<BranchOrg | null> {
  return selectOne<BranchOrg>(
    db,
    `SELECT id, organization_id AS "organizationId" FROM branch WHERE id = $1`,
    [branchId],
  );
}
