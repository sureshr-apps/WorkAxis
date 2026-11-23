import { createHash } from "node:crypto";
import type { Actor } from "../auth/roles";
import { isUniqueViolation } from "../db";
import type { SqlExecutor } from "../db/executor";
import { conflict } from "../errors";
import { optString } from "../util/input";

type Row = Record<string, unknown>;

/** Stored on the created row(s) so a retried request can find them again. */
export interface CreationKey {
  /** sha256 of caller + organization + requestId; unique per created row. */
  key: string;
  /** sha256 of the validated payload, to reject a reused id with new details. */
  fingerprint: string;
}

/** A previous create found by its key. */
export interface PriorCreation<T> {
  fingerprint: string | null;
  result: T;
}

const sha256 = (text: string): string => createHash("sha256").update(text).digest("hex");

/**
 * The creation key for an optional `requestId`. Without one (older clients)
 * the create is not retry-safe and behaves exactly as before.
 */
export function creationKey(actor: Actor, vars: Row, payload: unknown): CreationKey | undefined {
  const requestId = optString(vars, "requestId", 8, 100);
  if (!requestId) return undefined;
  return {
    key: sha256(`${actor.uid}:${actor.organizationId ?? ""}:${requestId}`),
    fingerprint: sha256(JSON.stringify(payload)),
  };
}

/**
 * Runs [create] once per creation key. A retry returns what the first attempt
 * created ([replay]); two concurrent attempts race on the unique index and the
 * loser replays the winner's result.
 */
export async function idempotentCreate<T>(
  db: SqlExecutor,
  creation: CreationKey | undefined,
  replay: (db: SqlExecutor, key: string) => Promise<PriorCreation<T> | null>,
  create: () => Promise<T>,
): Promise<T> {
  if (!creation) return create();
  const prior = await matchingPrior(db, creation, replay);
  if (prior) return prior.result;
  try {
    return await create();
  } catch (e) {
    if (!isUniqueViolation(e)) throw e;
    const raced = await matchingPrior(db, creation, replay);
    if (raced) return raced.result;
    throw e;
  }
}

async function matchingPrior<T>(
  db: SqlExecutor,
  creation: CreationKey,
  replay: (db: SqlExecutor, key: string) => Promise<PriorCreation<T> | null>,
): Promise<PriorCreation<T> | null> {
  const prior = await replay(db, creation.key);
  if (prior && prior.fingerprint !== creation.fingerprint) {
    throw conflict("This request was already submitted with different details.");
  }
  return prior;
}
