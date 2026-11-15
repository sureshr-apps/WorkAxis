import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { normalizeIdentity } from "../auth/aliasKeys";
import { deleteProfile, releaseAliases } from "../firestore/userStore";
import {
  deleteOrganizationSql,
  setOrganizationStatusSql,
} from "../sql/branches";
import type { MemberRecord } from "../sql/members";
import type { OrganizationDeleteSteps } from "./deletionWorkflow";

/** Collections whose documents carry an `organizationId` field. */
export const ORGANIZATION_SCOPED_COLLECTIONS = [
  "attendance_entries",
  "group_attendance_batches",
  "kiosk_pairing_tokens",
  // Defensive: a no-op when the collection holds nothing for the org.
  "employee_private",
] as const;

/** Runtime-only setting, so plain process.env is enough (no deploy-time param). */
export function attachmentsBucketName(): string {
  return process.env.ATTACHMENTS_BUCKET || "workaxis-app-attachments";
}

async function deleteFirestoreData(organizationId: string): Promise<void> {
  const db = getFirestore();
  const writer = db.bulkWriter();
  let failure: unknown;
  writer.onWriteError((error) => {
    failure ??= error;
    return false;
  });
  for (const name of ORGANIZATION_SCOPED_COLLECTIONS) {
    const snap = await db
      .collection(name)
      .where("organizationId", "==", organizationId)
      .select()
      .get();
    snap.docs.forEach((doc) => void writer.delete(doc.ref));
  }
  void writer.delete(db.collection("organization_settings").doc(organizationId));
  await writer.close();
  if (failure) throw failure;
}

async function deleteStorageObjects(organizationId: string): Promise<void> {
  await getStorage()
    .bucket(attachmentsBucketName())
    .deleteFiles({ prefix: `organizations/${organizationId}/`, force: true });
}

/** Whether an Auth deletion error just means the user is already gone. */
export function isAuthUserNotFound(error: unknown): boolean {
  return (error as { code?: string } | null)?.code === "auth/user-not-found";
}

async function deleteMemberIdentity(member: MemberRecord): Promise<void> {
  // Alias doc ids are normalized; synthetic login emails are never aliases.
  const email = member.email?.endsWith(".invalid") ? undefined : member.email;
  const { aliasKeys } = normalizeIdentity({
    username: member.username,
    email: email ?? undefined,
    phone: member.phone ?? undefined,
  });
  await releaseAliases(aliasKeys, member.authUid);
  await deleteProfile(member.authUid);
  try {
    await getAuth().deleteUser(member.authUid);
  } catch (error) {
    if (!isAuthUserNotFound(error)) throw error;
  }
}

export const productionOrganizationDeleteSteps: OrganizationDeleteSteps = {
  suspend: (id) => setOrganizationStatusSql(id, "suspended"),
  deleteFirestoreData,
  deleteStorageObjects,
  deleteMemberIdentity,
  deleteSql: deleteOrganizationSql,
};
