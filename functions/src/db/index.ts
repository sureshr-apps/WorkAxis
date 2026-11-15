import { createPool, readDbSettings } from "./connection";
import type { SqlExecutor } from "./executor";
import { PgExecutor } from "./pgExecutor";

export type { SqlExecutor } from "./executor";

let current: Promise<SqlExecutor> | undefined;
let override: SqlExecutor | undefined;

/** The process-wide database, created on first use and reused across calls. */
export function getDb(): Promise<SqlExecutor> {
  if (override) return Promise.resolve(override);
  current ??= createPool(readDbSettings()).then((h) => new PgExecutor(h.pool));
  return current;
}

/** Test seam: route every `getDb()` to a fake. Pass undefined to reset. */
export function setDbForTests(db: SqlExecutor | undefined): void {
  override = db;
}

/** SQL helper: `inList(3, ["a","b"])` → `"$3,$4"` for `IN (...)` clauses. */
export function placeholders(start: number, count: number): string {
  return Array.from({ length: count }, (_, i) => `$${start + i}`).join(",");
}

/** True when an error looks like a unique-constraint violation (Postgres 23505). */
export function isUniqueViolation(e: unknown): boolean {
  if (typeof e === "object" && e !== null && (e as { code?: string }).code === "23505") {
    return true;
  }
  const msg = e instanceof Error ? e.message : String(e);
  return /unique|duplicate key|already exists/i.test(msg);
}
