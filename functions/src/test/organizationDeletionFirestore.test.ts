import assert from "node:assert/strict";
import { it } from "node:test";
import type { Firestore } from "firebase-admin/firestore";
import type { MemberRecord } from "../sql/members";
import {
  deleteIdentitySyncJobs,
  deleteOrganizationFirestoreData,
  deleteProvisioningRequestsForMember,
} from "../organizations/organizationDeletionFirestore";

type Filter = {
  field: string;
  operator: "==" | "in" | ">=" | "<=";
  value: unknown;
};

class MemoryFirestore {
  private readonly collections = new Map<
    string,
    Map<string, Record<string, unknown>>
  >();

  collection(name: string) {
    return new MemoryCollection(this, name);
  }

  bulkWriter() {
    const pending: string[] = [];
    return {
      onWriteError: (_handler: (error: unknown) => boolean) => undefined,
      delete: (ref: { path: string }) => {
        pending.push(ref.path);
        return Promise.resolve();
      },
      close: async () => {
        for (const path of pending) this.deletePath(path);
      },
    };
  }

  seed(collection: string, id: string, data: Record<string, unknown> = {}) {
    this.collectionData(collection).set(id, data);
  }

  ids(collection: string): string[] {
    return [...this.collectionData(collection).keys()].sort();
  }

  collectionData(name: string): Map<string, Record<string, unknown>> {
    let documents = this.collections.get(name);
    if (!documents) {
      documents = new Map();
      this.collections.set(name, documents);
    }
    return documents;
  }

  deletePath(path: string): void {
    const separator = path.indexOf("/");
    const collection = path.slice(0, separator);
    const id = path.slice(separator + 1);
    this.collectionData(collection).delete(id);
  }
}

class MemoryQuery {
  protected readonly filters: Filter[];

  constructor(
    protected readonly firestore: MemoryFirestore,
    protected readonly collectionName: string,
    filters: Filter[] = [],
  ) {
    this.filters = filters;
  }

  where(field: unknown, operator: Filter["operator"], value: unknown) {
    const fieldName = typeof field === "string" ? field : "__name__";
    return new MemoryQuery(this.firestore, this.collectionName, [
      ...this.filters,
      { field: fieldName, operator, value },
    ]);
  }

  select(..._fields: string[]) {
    return this;
  }

  async get() {
    const docs = [...this.firestore.collectionData(this.collectionName)].filter(
      ([id, data]) =>
        this.filters.every(({ field, operator, value }) => {
          const actual = field === "__name__" ? id : data[field];
          switch (operator) {
            case "==":
              return actual === value;
            case "in":
              return Array.isArray(value) && value.includes(actual);
            case ">=":
              return typeof actual === "string" &&
                typeof value === "string" && actual >= value;
            case "<=":
              return typeof actual === "string" &&
                typeof value === "string" && actual <= value;
          }
        }),
    );
    return {
      docs: docs.map(([id, data]) => new MemoryDocumentSnapshot(
        new MemoryDocumentReference(this.collectionName, id),
        data,
      )),
    };
  }
}

class MemoryCollection extends MemoryQuery {
  doc(id: string) {
    return new MemoryDocumentReference(this.collectionName, id);
  }
}

class MemoryDocumentReference {
  constructor(
    readonly collectionName: string,
    readonly id: string,
  ) {}

  get path() {
    return `${this.collectionName}/${this.id}`;
  }
}

class MemoryDocumentSnapshot {
  constructor(
    readonly ref: MemoryDocumentReference,
    private readonly value: Record<string, unknown>,
  ) {}

  get(field: string): unknown {
    return this.value[field];
  }
}

function member(authUid: string): MemberRecord {
  return {
    id: `member-${authUid}`,
    authUid,
    fullName: authUid,
    username: authUid,
    email: `${authUid}@example.test`,
    role: "employee",
    status: "active",
    organizationId: "org-1",
    licenseUsable: true,
    licenseToday: "2026-11-20",
    branchIds: [],
    activeBranchIds: [],
  };
}

it("deletes org-scoped documents and current/legacy provisioning records", async () => {
  const db = new MemoryFirestore();
  db.seed("attendance_entries", "attendance-org", { organizationId: "org-1" });
  db.seed("attendance_entries", "attendance-other", { organizationId: "org-2" });
  db.seed("employee_private", "private-org", { organizationId: "org-1" });
  db.seed("organization_settings", "org-1", { requireGeolocation: true });
  db.seed("organization_settings", "org-2", { requireGeolocation: false });

  db.seed("provision_requests", "platform-new-org-request", {
    organizationId: "org-1",
    callerUid: "platform-owner",
    uid: "u1",
  });
  db.seed("provision_requests", "platform-failed-org-request", {
    organizationId: "org-1",
    callerUid: "platform-owner",
    uid: "orphaned-user",
  });
  db.seed("provision_requests", "platform-old-target-request", { uid: "u2" });
  db.seed("provision_requests", "u1_old-caller-request", { uid: "other-user" });
  db.seed("provision_requests", "u2_legacy-caller-request", { uid: "other-user" });
  db.seed("provision_requests", "u20_other-caller-request", { uid: "other-user" });
  db.seed("provision_requests", "unrelated-request", {
    organizationId: "org-2",
    callerUid: "other-user",
    uid: "other-user",
  });

  await deleteOrganizationFirestoreData(
    "org-1",
    [member("u1"), member("u2")],
    db as unknown as Firestore,
  );

  assert.deepEqual(db.ids("attendance_entries"), ["attendance-other"]);
  assert.deepEqual(db.ids("employee_private"), []);
  assert.deepEqual(db.ids("organization_settings"), ["org-2"]);
  assert.deepEqual(db.ids("provision_requests"), [
    "u20_other-caller-request",
    "unrelated-request",
  ]);
});

it("releases queued identity aliases before deleting sync jobs", async () => {
  const db = new MemoryFirestore();
  db.seed("identity_sync_jobs", "job-1", {
    uid: "u1",
    aliasKeys: ["old-user", "old-email"],
  });
  db.seed("identity_sync_jobs", "job-2", {
    uid: "u1",
    aliasKeys: ["old-email", 42],
  });
  db.seed("identity_sync_jobs", "job-other", {
    uid: "u2",
    aliasKeys: ["other-user"],
  });
  let released: string[] = [];

  await deleteIdentitySyncJobs(
    "u1",
    async (keys) => {
      released = keys;
    },
    db as unknown as Firestore,
  );

  assert.deepEqual(released, ["old-user", "old-email"]);
  assert.deepEqual(db.ids("identity_sync_jobs"), ["job-other"]);
});

it("clears a deleted member's current and legacy provisioning records", async () => {
  const db = new MemoryFirestore();
  db.seed("provision_requests", "request-targeted-to-u1", { uid: "u1" });
  db.seed("provision_requests", "request-owned-by-u1", { callerUid: "u1" });
  db.seed("provision_requests", "u1_legacy-request", { uid: "other-user" });
  db.seed("provision_requests", "u10_other-member-request", {
    uid: "other-user",
  });
  db.seed("provision_requests", "unrelated-request", {
    callerUid: "other-user",
    uid: "other-user",
  });

  await deleteProvisioningRequestsForMember("u1", db as unknown as Firestore);

  assert.deepEqual(db.ids("provision_requests"), [
    "u10_other-member-request",
    "unrelated-request",
  ]);
});

it("keeps identity jobs available for retry if alias cleanup fails", async () => {
  const db = new MemoryFirestore();
  db.seed("identity_sync_jobs", "job-1", {
    uid: "u1",
    aliasKeys: ["old-user"],
  });

  await assert.rejects(
    deleteIdentitySyncJobs(
      "u1",
      async () => {
        throw new Error("alias cleanup failed");
      },
      db as unknown as Firestore,
    ),
    /alias cleanup failed/,
  );

  assert.deepEqual(db.ids("identity_sync_jobs"), ["job-1"]);
});
