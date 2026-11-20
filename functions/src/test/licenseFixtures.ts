import { FakeDb } from "./fakeDb";

/** Matches the license row lock taken by every capacity check. */
export const LICENSE_LOCK = "for update of ol";

/** Locked license row for an organization on an active Pro plan (5 stores, 10 users) valid on 2026-11-15. */
export function usableLicense(over: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    id: "ol1",
    planId: "plan-pro",
    startDate: "2026-01-01",
    expiryDate: "2027-12-31",
    negotiatedPrice: 100,
    maintenancePrice: 10,
    planStatus: "active",
    planLevel: 3,
    maxStores: 5,
    maxUsers: 10,
    today: "2026-11-15",
    ...over,
  };
}

/**
 * A database for capacity checks. `license` null means the organization has no
 * license row. The branch and member counts answer the active-count queries.
 */
export function capacityDb(
  opts: {
    license?: Record<string, unknown> | null;
    activeBranches?: number;
    activeMembers?: number;
  } = {},
): FakeDb {
  const license = opts.license === undefined ? usableLicense() : opts.license;
  const db = new FakeDb().when("SELECT status FROM organization", [
    { status: "active" },
  ]);
  if (license) db.when(LICENSE_LOCK, [license]);
  return db
    .when('"activecount" from branch', [{ activeCount: opts.activeBranches ?? 0 }])
    .when('"activecount" from organization_member', [{ activeCount: opts.activeMembers ?? 0 }]);
}
