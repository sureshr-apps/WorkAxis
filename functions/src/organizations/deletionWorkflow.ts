import { logger } from "firebase-functions/v2";
import type { MemberRecord } from "../sql/members";

/**
 * Cleanup seam for organization deletion. Every step must be idempotent
 * (already-done work is not an error) and must throw on real failure so the
 * callable fails while SQL is still intact and the same call can be retried.
 */
export interface OrganizationDeleteSteps {
  /** Locks members out (resolveActor treats a suspended org as suspended). */
  suspend(organizationId: string): Promise<void>;
  listMembers(organizationId: string): Promise<MemberRecord[]>;
  deleteFirestoreData(
    organizationId: string,
    members: readonly MemberRecord[],
  ): Promise<void>;
  deleteStorageObjects(organizationId: string): Promise<void>;
  deleteMemberIdentity(member: MemberRecord): Promise<void>;
  /** Final step: removes the organization, its members and branches. */
  deleteSql(organizationId: string): Promise<void>;
}

export interface OrganizationDeleteResult {
  membersCleaned: number;
}

async function named<T>(
  name: string,
  organizationId: string,
  work: () => Promise<T>,
): Promise<T> {
  try {
    return await work();
  } catch (error) {
    logger.error(`deleteOrganization failed during ${name}`, organizationId, error);
    throw error;
  }
}

/**
 * Order: suspend, read members, Firestore data, Storage, member identities,
 * SQL last. A failure before SQL leaves relational data available for retry.
 */
export async function runOrganizationDeletion(
  organizationId: string,
  steps: OrganizationDeleteSteps,
): Promise<OrganizationDeleteResult> {
  await named("suspend", organizationId, () => steps.suspend(organizationId));
  const members = await named("list members", organizationId, () =>
    steps.listMembers(organizationId),
  );
  await named("firestore data", organizationId, () =>
    steps.deleteFirestoreData(organizationId, members),
  );
  await named("storage objects", organizationId, () =>
    steps.deleteStorageObjects(organizationId),
  );
  let membersCleaned = 0;
  for (const member of members) {
    if (!member.authUid) continue;
    await named(`member ${member.authUid}`, organizationId, () =>
      steps.deleteMemberIdentity(member),
    );
    membersCleaned += 1;
  }
  await named("sql", organizationId, () => steps.deleteSql(organizationId));
  return { membersCleaned };
}
