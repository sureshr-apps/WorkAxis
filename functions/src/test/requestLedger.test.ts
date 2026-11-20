import assert from "node:assert/strict";
import { it } from "node:test";
import type { Firestore } from "firebase-admin/firestore";
import { claimRequest } from "../provisioning/requestLedger";

class MemoryFirestore {
  readonly documents = new Map<string, Record<string, unknown>>();

  collection(name: string) {
    return {
      doc: (id: string) => ({ path: `${name}/${id}` }),
    };
  }

  async runTransaction<T>(action: (transaction: MemoryTransaction) => Promise<T>) {
    return action(new MemoryTransaction(this));
  }
}

class MemoryTransaction {
  constructor(private readonly firestore: MemoryFirestore) {}

  async get(reference: { path: string }) {
    const data = this.firestore.documents.get(reference.path);
    return {
      exists: data !== undefined,
      data: () => data,
    };
  }

  create(reference: { path: string }, data: Record<string, unknown>) {
    if (this.firestore.documents.has(reference.path)) {
      throw new Error("Document already exists.");
    }
    this.firestore.documents.set(reference.path, data);
  }

  update(reference: { path: string }, data: Record<string, unknown>) {
    const existing = this.firestore.documents.get(reference.path);
    if (!existing) throw new Error("Document does not exist.");
    this.firestore.documents.set(reference.path, { ...existing, ...data });
  }
}

it("blocks provisioning claims after organization deletion starts", async () => {
  const db = new MemoryFirestore();
  db.documents.set("organization_deletion_markers/org-1", {
    startedAt: "timestamp",
  });

  await assert.rejects(
    claimRequest("caller-1", "request-123", "org-1", db as unknown as Firestore),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "failed-precondition",
  );

  assert.equal(db.documents.has("provision_requests/caller-1_request-123"), false);
});

it("stores organization and caller metadata with a new claim", async () => {
  const db = new MemoryFirestore();

  const claim = await claimRequest(
    "caller-1",
    "request-123",
    "org-1",
    db as unknown as Firestore,
  );

  assert.equal(claim.kind, "run");
  const ledger = db.documents.get("provision_requests/caller-1_request-123");
  assert.equal(ledger?.callerUid, "caller-1");
  assert.equal(ledger?.organizationId, "org-1");
});
