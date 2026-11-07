import { logger } from "firebase-functions/v2";
import { HttpsError, type FunctionsErrorCode } from "firebase-functions/v2/https";

/** Error raised by domain logic; mapped to a client-safe HttpsError. */
export class DomainError extends Error {
  constructor(
    readonly code: FunctionsErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "DomainError";
  }
}

export const denied = (msg = "You are not allowed to perform this action.") =>
  new DomainError("permission-denied", msg);
export const invalid = (msg: string) => new DomainError("invalid-argument", msg);
export const notFound = (msg: string) => new DomainError("not-found", msg);
export const conflict = (msg: string) => new DomainError("already-exists", msg);
export const precondition = (msg: string) =>
  new DomainError("failed-precondition", msg);

/** Maps any thrown value to an HttpsError without leaking internals. */
export function toHttpsError(e: unknown): HttpsError {
  if (e instanceof HttpsError) return e;
  if (e instanceof DomainError) return new HttpsError(e.code, e.message);
  logger.error("Unhandled function error", e);
  return new HttpsError("internal", "Something went wrong. Please try again.");
}

/** Wraps a handler body so every failure surfaces as an HttpsError. */
export async function guarded<T>(fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (e) {
    throw toHttpsError(e);
  }
}
