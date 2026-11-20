import { getAuth } from "firebase-admin/auth";
import { getStorage } from "firebase-admin/storage";
import { attachmentsBucketName } from "../config";
import { withIdentityLocks } from "../accounts/identityLocks";
import { normalizeIdentity } from "../auth/aliasKeys";
import { deleteProfile, releaseAliases } from "../firestore/userStore";
import {
  deleteOrganizationSql,
  setOrganizationStatusSql,
} from "../sql/branches";
import {
  getMemberByAuthUid,
  listMembersOfOrganization,
  type MemberRecord,
} from "../sql/members";
import {
  deleteIdentitySyncJobs,
  deleteOrganizationFirestoreData,
  deleteProvisioningRequestsForMember,
} from "./organizationDeletionFirestore";
import { markOrganizationDeleting } from "./organizationLifecycle";
import type { OrganizationDeleteSteps } from "./deletionWorkflow";

async function deleteStorageObjects(organizationId: string): Promise<void> {
  await getStorage()
    .bucket(attachmentsBucketName())
    .deleteFiles({ prefix: `organizations/${organizationId}/`, force: true });
}

/** Whether an Auth deletion error just means the user is already gone. */
export function isAuthUserNotFound(error: unknown): boolean {
  return (error as { code?: string } | null)?.code === "auth/user-not-found";
}

/** Removes a member's login aliases, profile and Auth user. Idempotent. */
export async function deleteMemberIdentity(member: MemberRecord): Promise<void> {
  const uid = member.authUid;
  await withIdentityLocks([uid], async () => {
    // Account edits use the same lock. Read after acquiring it so alias cleanup
    // uses the committed identity even if an edit started before suspension.
    const currentMember = (await getMemberByAuthUid(uid)) ?? member;

    // Alias doc ids are normalized; synthetic login emails are never aliases.
    const email = currentMember.email?.endsWith(".invalid")
      ? undefined
      : currentMember.email;
    const { aliasKeys } = normalizeIdentity({
      username: currentMember.username,
      email: email ?? undefined,
      phone: currentMember.phone ?? undefined,
    });

    await deleteProvisioningRequestsForMember(uid);

    // A reconciliation worker may already have read a job. The identity lock
    // lets an in-flight projection finish before cleanup, and deleting Auth
    // before releasing the lock makes a waiting worker fail before reprojection.
    await deleteIdentitySyncJobs(uid, (queuedAliasKeys) =>
      releaseAliases([...new Set([...aliasKeys, ...queuedAliasKeys])], uid),
    );
    await deleteProfile(uid);
    try {
      await getAuth().deleteUser(uid);
    } catch (error) {
      if (!isAuthUserNotFound(error)) throw error;
    }
  });
}

export const productionOrganizationDeleteSteps: OrganizationDeleteSteps = {
  suspend: async (id) => {
    await setOrganizationStatusSql(id, "suspended");
    await markOrganizationDeleting(id);
  },
  listMembers: listMembersOfOrganization,
  deleteFirestoreData: (id, members) =>
    deleteOrganizationFirestoreData(id, members),
  deleteStorageObjects,
  deleteMemberIdentity,
  deleteSql: deleteOrganizationSql,
};
