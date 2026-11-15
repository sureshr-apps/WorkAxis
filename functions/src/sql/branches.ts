import { logger } from "firebase-functions/v2";
import { getDb } from "../db";

export interface BranchRecord {
  id: string;
  organizationId: string;
  status: string;
  latitude?: number;
  longitude?: number;
  geofenceRadiusMeters?: number;
}

interface BranchRow {
  id: string;
  organizationId: string;
  status: string;
  latitude: number | null;
  longitude: number | null;
  geofenceRadiusMeters: number | null;
}

export async function getBranches(ids: string[]): Promise<BranchRecord[]> {
  if (ids.length === 0) return [];
  const db = await getDb();
  const rows = await db.query<BranchRow>(
    `SELECT id, organization_id AS "organizationId", status, latitude, longitude,
            geofence_radius_meters AS "geofenceRadiusMeters"
       FROM branch WHERE id = ANY($1::text[])`,
    [ids],
  );
  return rows.map((b) => ({
    id: b.id,
    organizationId: b.organizationId,
    status: b.status,
    latitude: b.latitude ?? undefined,
    longitude: b.longitude ?? undefined,
    geofenceRadiusMeters: b.geofenceRadiusMeters ?? undefined,
  }));
}

export async function getBranch(id: string): Promise<BranchRecord | null> {
  return (await getBranches([id]))[0] ?? null;
}

export interface OrganizationRecord {
  id: string;
  status: string;
}

export async function getOrganization(
  id: string,
): Promise<OrganizationRecord | null> {
  const db = await getDb();
  const rows = await db.query<OrganizationRecord>(
    `SELECT id, status FROM organization WHERE id = $1`,
    [id],
  );
  return rows[0] ?? null;
}

export async function setOrganizationStatusSql(
  id: string,
  status: string,
): Promise<void> {
  const db = await getDb();
  await db.query(`UPDATE organization SET status = $2 WHERE id = $1`, [
    id,
    status,
  ]);
}

/** Ordered deletes (FK-safe); each is idempotent so a failed run can simply be retried. */
export const ORGANIZATION_DELETE_STEPS: ReadonlyArray<{
  name: string;
  sql: string;
}> = [
  {
    name: "member branch assignments",
    sql: `DELETE FROM user_branch_assignment
           WHERE member_id IN (SELECT id FROM organization_member WHERE organization_id = $1)`,
  },
  {
    name: "branch assignments",
    sql: `DELETE FROM user_branch_assignment
           WHERE branch_id IN (SELECT id FROM branch WHERE organization_id = $1)`,
  },
  {
    name: "return records",
    sql: `DELETE FROM return_record WHERE organization_id = $1`,
  },
  {
    name: "commercial agreements",
    sql: `DELETE FROM commercial_agreement WHERE organization_id = $1`,
  },
  {
    name: "license events",
    sql: `DELETE FROM license_event WHERE organization_id = $1`,
  },
  {
    name: "branches",
    sql: `DELETE FROM branch WHERE organization_id = $1`,
  },
  {
    name: "organization members",
    sql: `DELETE FROM organization_member WHERE organization_id = $1`,
  },
  {
    name: "organization",
    sql: `DELETE FROM organization WHERE id = $1`,
  },
];

export async function deleteOrganizationSql(orgId: string): Promise<void> {
  const db = await getDb();
  for (const step of ORGANIZATION_DELETE_STEPS) {
    try {
      await db.query(step.sql, [orgId]);
    } catch (e) {
      // Surface which step failed instead of hiding it and failing later on a
      // misleading foreign-key error. Every step is safe to re-run.
      logger.error(
        `deleteOrganizationSql failed while deleting ${step.name}`,
        orgId,
        e,
      );
      throw e;
    }
  }
}
