import type { Actor } from "../auth/roles";
import type { SqlExecutor } from "../db/executor";

/** What every data operation receives. The actor is resolved from SQL. */
export interface OperationContext {
  db: SqlExecutor;
  actor: Actor;
}

/**
 * One named read or write the app may request through the `dataOp` callable.
 *
 * Contract: each operation owns its own authorization (replacing the old
 * connector `@auth`/`@check` rules), validates its variables, and returns
 * JSON-serialisable data. Optional variables arrive omitted, never null.
 */
export type DataOperation = (
  ctx: OperationContext,
  vars: Record<string, unknown>,
) => Promise<unknown>;

export type OperationRegistry = Record<string, DataOperation>;
