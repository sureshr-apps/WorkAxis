import { getDb } from "../db";
import { invalid, notFound, precondition } from "../errors";
import type { parseBranchSave, ManagerAssignment } from "../branches/savePlan";

type Plan = ReturnType<typeof parseBranchSave>;

interface ManagerRow {
  id: string;
  authUid: string;
  organizationId: string;
  role: string;
  branchId: string | null;
}

export async function loadBranchManagers(
  orgId: string,
): Promise<ManagerAssignment[]> {
  const db = await getDb();
  const rows = await db.query<ManagerRow>(
    `SELECT m.id, m.auth_uid AS "authUid", m.organization_id AS "organizationId",
            m.role, a.branch_id AS "branchId"
       FROM organization_member m
       LEFT JOIN user_branch_assignment a ON a.member_id = m.id
      WHERE m.organization_id = $1 AND m.role = 'branchManager'
      ORDER BY m.created_at, m.id, a.assigned_at, a.branch_id`,
    [orgId],
  );
  const byId = new Map<string, ManagerAssignment>();
  for (const r of rows) {
    let m = byId.get(r.id);
    if (!m) {
      m = {
        id: r.id,
        authUid: r.authUid,
        organizationId: r.organizationId,
        role: r.role,
        branchIds: [],
      };
      byId.set(r.id, m);
    }
    if (r.branchId) m.branchIds.push(r.branchId);
  }
  return [...byId.values()];
}

/** Branch columns writable by a save; id and organization are fixed after creation. */
const BRANCH_COLUMNS: ReadonlyArray<[string, string]> = [
  ["id", "id"],
  ["organizationId", "organization_id"],
  ["name", "name"],
  ["code", "code"],
  ["location", "location"],
  ["status", "status"],
  ["isMainBranch", "is_main_branch"],
  ["geofenceRadiusMeters", "geofence_radius_meters"],
  ["latitude", "latitude"],
  ["longitude", "longitude"],
  ["kioskEnabled", "kiosk_enabled"],
  ["creationRequestKey", "creation_request_key"],
  ["creationFingerprint", "creation_fingerprint"],
];

/**
 * Rechecks membership and last-branch invariants inside the write transaction.
 * The branch row and the affected manager rows are locked first (members in id
 * order to avoid deadlocks), so concurrent saves serialise instead of racing
 * between the checks and the writes.
 */
export async function commitBranchSave(plan: Plan, currentIds: string[]) {
  const wanted = plan.managerIds;
  const removed = currentIds.filter((id) => !wanted.includes(id));
  const data = plan.data as Record<string, unknown>;
  const branchId = plan.data.id;
  const orgId = plan.data.organizationId;
  const db = await getDb();

  await db.transaction(async (tx) => {
    const existing = await tx.query<{ organizationId: string }>(
      `SELECT organization_id AS "organizationId" FROM branch WHERE id = $1 FOR UPDATE`,
      [branchId],
    );
    const branchOk = plan.creating
      ? existing.length === 0
      : existing.length === 1 && existing[0].organizationId === orgId;
    if (!branchOk) throw notFound("Branch not found.");

    const lockIds = [...new Set([...wanted, ...removed])].sort();
    if (lockIds.length > 0) {
      await tx.query(
        `SELECT id FROM organization_member WHERE id = ANY($1::text[]) ORDER BY id FOR UPDATE`,
        [lockIds],
      );
    }

    const wantedRows = wanted.length
      ? await tx.query<{ id: string; authUid: string | null }>(
          `SELECT id, auth_uid AS "authUid" FROM organization_member
            WHERE id = ANY($1::text[]) AND organization_id = $2 AND role = 'branchManager'`,
          [wanted, orgId],
        )
      : [];
    if (
      wantedRows.length !== wanted.length ||
      wantedRows.some((m) => !m.authUid)
    ) {
      throw invalid("Invalid manager selection.");
    }

    const currentRows = await tx.query<{ memberId: string }>(
      `SELECT a.member_id AS "memberId"
         FROM user_branch_assignment a
         JOIN organization_member m ON m.id = a.member_id
        WHERE a.branch_id = $1 AND m.role = 'branchManager'`,
      [branchId],
    );
    if (
      currentRows.length !== currentIds.length ||
      currentRows.some((r) => !currentIds.includes(r.memberId))
    ) {
      throw precondition("Assignments changed. Reload the branch.");
    }

    if (removed.length > 0) {
      const removedRows = await tx.query<{
        id: string;
        otherBranches: number | string;
      }>(
        `SELECT m.id, COUNT(a.branch_id) FILTER (WHERE a.branch_id <> $2) AS "otherBranches"
           FROM organization_member m
           LEFT JOIN user_branch_assignment a ON a.member_id = m.id
          WHERE m.id = ANY($1::text[])
          GROUP BY m.id`,
        [removed, branchId],
      );
      if (removedRows.some((r) => Number(r.otherBranches) === 0)) {
        throw invalid("A manager must keep at least one branch.");
      }
    }

    const cols = BRANCH_COLUMNS.filter(([k]) => data[k] !== undefined);
    if (plan.creating) {
      // Plain INSERT (not an upsert): a concurrent create with the same id must
      // fail with a unique violation so the caller can resolve the replay.
      await tx.query(
        `INSERT INTO branch (${cols.map(([, c]) => c).join(", ")})
         VALUES (${cols.map((_, i) => `$${i + 1}`).join(", ")})`,
        cols.map(([k]) => data[k]),
      );
    } else {
      const sets = cols.filter(([k]) => k !== "id" && k !== "organizationId");
      await tx.query(
        `UPDATE branch SET ${sets.map(([, c], i) => `${c} = $${i + 2}`).join(", ")}
          WHERE id = $1`,
        [branchId, ...sets.map(([k]) => data[k])],
      );
    }

    await tx.query(
      `DELETE FROM user_branch_assignment a
        USING organization_member m
        WHERE a.member_id = m.id AND a.branch_id = $1 AND m.role = 'branchManager'`,
      [branchId],
    );
    if (wanted.length > 0) {
      await tx.query(
        `INSERT INTO user_branch_assignment (member_id, branch_id)
         SELECT unnest($1::text[]), $2`,
        [wanted, branchId],
      );
    }
  });
}

export async function branchCreation(id: string): Promise<{
  id: string;
  code: string;
  creationFingerprint: string | null;
} | null> {
  const db = await getDb();
  const rows = await db.query<{
    id: string;
    code: string;
    creationFingerprint: string | null;
  }>(
    `SELECT id, code, creation_fingerprint AS "creationFingerprint" FROM branch WHERE id = $1`,
    [id],
  );
  return rows[0] ?? null;
}
