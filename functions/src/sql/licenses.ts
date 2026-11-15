import type { SqlExecutor } from "../db/executor";
import { precondition } from "../errors";
import { isLicenseUsable, LICENSE_TODAY_SQL } from "../licenses/licenseStatus";

/** The organization's license row with its live plan, read under a row lock. */
export interface LockedLicense {
  id: string;
  planId: string;
  startDate: string;
  expiryDate: string;
  negotiatedPrice: number;
  maintenancePrice: number;
  planStatus: string | null;
  planLevel: number | null;
  maxStores: number | null;
  maxUsers: number | null;
  today: string;
}

/** Capacity granted by an organization's license, as enforced at write time. */
export interface LicenseCapacity {
  usable: boolean;
  maxStores: number;
  maxUsers: number;
}

const LOCKED_LICENSE_SQL = `SELECT ol.id, ol.plan_id AS "planId",
    to_char(ol.start_date, 'YYYY-MM-DD') AS "startDate",
    to_char(ol.expiry_date, 'YYYY-MM-DD') AS "expiryDate",
    ol.negotiated_price AS "negotiatedPrice", ol.maintenance_price AS "maintenancePrice",
    p.status AS "planStatus", p.level AS "planLevel",
    p.max_stores AS "maxStores", p.max_users AS "maxUsers",
    to_char(${LICENSE_TODAY_SQL}, 'YYYY-MM-DD') AS "today"
  FROM organization_license ol
  LEFT JOIN license_plan p ON p.id = ol.plan_id
  WHERE ol.organization_id = $1
  FOR UPDATE OF ol`;

/**
 * Locks the organization's license row until the transaction ends. Every
 * store and member capacity change takes this lock first, so concurrent
 * creations and activations for one organization are serialised.
 */
export async function lockOrganizationLicense(
  tx: SqlExecutor,
  organizationId: string,
): Promise<LockedLicense | null> {
  const rows = await tx.query<LockedLicense>(LOCKED_LICENSE_SQL, [organizationId]);
  return rows[0] ?? null;
}

/** Locks the license and reports whether it grants capacity today. */
export async function lockLicenseCapacity(
  tx: SqlExecutor,
  organizationId: string,
): Promise<LicenseCapacity> {
  const license = await lockOrganizationLicense(tx, organizationId);
  return {
    usable: license !== null && isLicenseUsable(license),
    maxStores: license?.maxStores ?? 0,
    maxUsers: license?.maxUsers ?? 0,
  };
}

export const NO_ACTIVE_PLAN_FOR_STORES =
  "This organization does not have an active license plan. Assign an active license before adding or activating stores.";
export const NO_ACTIVE_PLAN_FOR_USERS =
  "This organization does not have an active license plan. Assign an active license before adding or activating users.";

const storeLimitMessage = (max: number) =>
  `This organization has reached its plan limit of ${max} active stores. Deactivate an existing store before adding or activating another store.`;
const userLimitMessage = (max: number) =>
  `This organization has reached its plan limit of ${max} active users. Deactivate an existing administrator or employee before adding or activating another user.`;

/**
 * Refuses creating a store, or making one active, when the organization has no
 * usable license or its active store count already equals the plan limit.
 * Call inside the write transaction. A suspended store needs only a usable license.
 */
export async function assertStoreAllowed(
  tx: SqlExecutor,
  organizationId: string,
  branchId: string,
  becomingActive: boolean,
): Promise<void> {
  const capacity = await lockLicenseCapacity(tx, organizationId);
  if (!capacity.usable) throw precondition(NO_ACTIVE_PLAN_FOR_STORES);
  if (!becomingActive) return;
  const [count] = await tx.query<{ activeCount: number }>(
    `SELECT count(*)::int AS "activeCount" FROM branch
      WHERE organization_id = $1 AND status = 'active' AND id <> $2`,
    [organizationId, branchId],
  );
  if (Number(count?.activeCount ?? 0) + 1 > capacity.maxStores) {
    throw precondition(storeLimitMessage(capacity.maxStores));
  }
}

/**
 * Refuses adding an active member, or reactivating one, when the organization
 * has no usable license or its active member count already equals the plan
 * limit. Platform roles are never counted. Pass null for a member that does not
 * exist yet. Call inside the write transaction.
 */
export async function assertMemberAllowed(
  tx: SqlExecutor,
  organizationId: string,
  memberId: string | null,
): Promise<void> {
  const capacity = await lockLicenseCapacity(tx, organizationId);
  if (!capacity.usable) throw precondition(NO_ACTIVE_PLAN_FOR_USERS);
  const [count] = await tx.query<{ activeCount: number }>(
    `SELECT count(*)::int AS "activeCount" FROM organization_member
      WHERE organization_id = $1 AND status = 'active'
        AND role NOT IN ('platformOwner', 'platformAdmin')
        AND ($2::text IS NULL OR id <> $2)`,
    [organizationId, memberId],
  );
  if (Number(count?.activeCount ?? 0) + 1 > capacity.maxUsers) {
    throw precondition(userLimitMessage(capacity.maxUsers));
  }
}
