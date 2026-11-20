import {
  FieldPath,
  getFirestore,
  type Firestore,
  type Query,
} from "firebase-admin/firestore";
import type { MemberRecord } from "../sql/members";

/** Firestore collections whose documents are explicitly scoped to an org. */
export const ORGANIZATION_SCOPED_COLLECTIONS = [
  "attendance_entries",
  "group_attendance_batches",
  "kiosk_pairing_tokens",
  // Defensive: a no-op when the collection holds nothing for the org.
  "employee_private",
] as const;

const FIRESTORE_IN_QUERY_LIMIT = 30;

async function addQueryDocuments(
  refs: Map<string, FirebaseFirestore.DocumentReference>,
  query: Query,
): Promise<void> {
  const snapshot = await query.get();
  for (const document of snapshot.docs) {
    refs.set(document.ref.path, document.ref);
  }
}

async function deleteDocuments(
  db: Firestore,
  refs: Iterable<FirebaseFirestore.DocumentReference>,
): Promise<void> {
  const writer = db.bulkWriter();
  let failure: unknown;
  writer.onWriteError((error) => {
    failure ??= error;
    return false;
  });

  for (const ref of refs) {
    void writer.delete(ref).catch((error) => {
      failure ??= error;
    });
  }
  await writer.close();
  if (failure) throw failure;
}

/** Removes current and legacy provisioning records owned by or targeting a member. */
export async function deleteProvisioningRequestsForMember(
  uid: string,
  db: Firestore = getFirestore(),
): Promise<void> {
  const refs = new Map<string, FirebaseFirestore.DocumentReference>();
  const requests = db.collection("provision_requests");
  await addQueryDocuments(refs, requests.where("uid", "==", uid).select());
  await addQueryDocuments(
    refs,
    requests.where("callerUid", "==", uid).select(),
  );

  const prefix = `${uid}_`;
  await addQueryDocuments(
    refs,
    requests
      .where(FieldPath.documentId(), ">=", prefix)
      .where(FieldPath.documentId(), "<=", `${prefix}\uf8ff`)
      .select(),
  );
  await deleteDocuments(db, refs.values());
}

/**
 * Deletes Firestore data and provisioning idempotency records owned by an org.
 * The member UID filters and document-ID prefix queries also catch records
 * written before provisioning requests stored organizationId/callerUid fields.
 */
export async function deleteOrganizationFirestoreData(
  organizationId: string,
  members: readonly MemberRecord[],
  db: Firestore = getFirestore(),
): Promise<void> {
  const refs = new Map<string, FirebaseFirestore.DocumentReference>();

  for (const name of ORGANIZATION_SCOPED_COLLECTIONS) {
    await addQueryDocuments(
      refs,
      db
        .collection(name)
        .where("organizationId", "==", organizationId)
        .select(),
    );
  }
  refs.set(
    `organization_settings/${organizationId}`,
    db.collection("organization_settings").doc(organizationId),
  );

  const memberUids = [
    ...new Set(
      members
        .map((member) => member.authUid)
        .filter((uid): uid is string => uid.length > 0),
    ),
  ];
  const requests = db.collection("provision_requests");
  await addQueryDocuments(
    refs,
    requests.where("organizationId", "==", organizationId).select(),
  );

  for (let index = 0; index < memberUids.length; index += FIRESTORE_IN_QUERY_LIMIT) {
    const uidChunk = memberUids.slice(index, index + FIRESTORE_IN_QUERY_LIMIT);
    // `uid` identifies the provisioned account; `callerUid` is also stored on
    // new ledger records so both sides can be purged without scanning a tenant.
    await addQueryDocuments(
      refs,
      requests.where("uid", "in", uidChunk).select(),
    );
    await addQueryDocuments(
      refs,
      requests.where("callerUid", "in", uidChunk).select(),
    );
  }

  // Older ledger records encode the caller in the document id instead of a
  // field. The underscore delimiter prevents matching a UID that merely shares
  // a prefix with another member's UID.
  for (const uid of memberUids) {
    const prefix = `${uid}_`;
    await addQueryDocuments(
      refs,
      requests
        .where(FieldPath.documentId(), ">=", prefix)
        .where(FieldPath.documentId(), "<=", `${prefix}\uf8ff`)
        .select(),
    );
  }

  await deleteDocuments(db, refs.values());
}

/**
 * Removes pending identity projections while returning their old aliases for
 * cleanup. The caller releases current and queued aliases before job deletion.
 */
export async function deleteIdentitySyncJobs(
  uid: string,
  releaseAliasesForUid: (queuedAliasKeys: string[]) => Promise<void>,
  db: Firestore = getFirestore(),
): Promise<void> {
  const snapshot = await db
    .collection("identity_sync_jobs")
    .where("uid", "==", uid)
    .select("aliasKeys")
    .get();
  const queuedAliasKeys = [
    ...new Set(
      snapshot.docs.flatMap((document) => {
        const keys = document.get("aliasKeys");
        return Array.isArray(keys)
          ? keys.filter((key): key is string => typeof key === "string")
          : [];
      }),
    ),
  ];

  await releaseAliasesForUid(queuedAliasKeys);
  await deleteDocuments(
    db,
    snapshot.docs.map((document) => document.ref),
  );
}
