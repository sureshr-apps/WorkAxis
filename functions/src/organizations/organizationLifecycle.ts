import {
  FieldValue,
  getFirestore,
  type Firestore,
} from "firebase-admin/firestore";

const DELETION_MARKERS = "organization_deletion_markers";

/**
 * A minimal tombstone fences off new provisioning claims after deletion starts.
 * It contains only the organization ID and is intentionally retained.
 */
export function organizationDeletionMarkerRef(
  organizationId: string,
  db: Firestore = getFirestore(),
) {
  return db.collection(DELETION_MARKERS).doc(organizationId);
}

export async function markOrganizationDeleting(
  organizationId: string,
  db: Firestore = getFirestore(),
): Promise<void> {
  await organizationDeletionMarkerRef(organizationId, db).set(
    { startedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
}
