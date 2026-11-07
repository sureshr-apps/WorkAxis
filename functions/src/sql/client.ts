import { getApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import { DATA_CONNECT_SERVICE_ID, REGION } from "../config";

/**
 * Thin wrapper over the Admin SDK's executeGraphql. Admin execution bypasses
 * connector @auth rules, so it is only ever called from trusted functions
 * after they have authorized the caller themselves.
 */
function service() {
  return getDataConnect(
    { location: REGION, serviceId: DATA_CONNECT_SERVICE_ID },
    getApp(),
  );
}

export async function sqlQuery<T>(
  query: string,
  variables?: Record<string, unknown>,
): Promise<T> {
  const res = await service().executeGraphqlRead<T, Record<string, unknown>>(query, {
    variables,
  });
  return res.data;
}

export async function sqlMutate<T>(
  query: string,
  variables?: Record<string, unknown>,
): Promise<T> {
  const res = await service().executeGraphql<T, Record<string, unknown>>(query, {
    variables,
  });
  return res.data;
}

/** True when an error looks like a unique-constraint violation. */
export function isUniqueViolation(e: unknown): boolean {
  const msg = e instanceof Error ? e.message : String(e);
  return /unique|duplicate key|already exists/i.test(msg);
}
