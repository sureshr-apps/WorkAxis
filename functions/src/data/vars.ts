import { invalid } from "../errors";
import { optString, reqString } from "../util/input";

type Bag = Record<string, unknown>;

const absent = (v: unknown): boolean => v === undefined || v === null;
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

export const reqId = (bag: Bag, key: string): string => reqString(bag, key, 1, 128);
export const optId = (bag: Bag, key: string): string | undefined => optString(bag, key, 1, 128);

/** Free text; absent/null/"" all mean "not provided". */
export const optText = (bag: Bag, key: string, max = 2000): string | undefined =>
  optString(bag, key, 1, max);

export function reqInt(bag: Bag, key: string, min: number, max: number): number {
  const v = bag[key];
  if (typeof v !== "number" || !Number.isInteger(v) || v < min || v > max) {
    throw invalid(`${key} must be an integer between ${min} and ${max}.`);
  }
  return v;
}

export function optInt(bag: Bag, key: string, min: number, max: number): number | undefined {
  return absent(bag[key]) ? undefined : reqInt(bag, key, min, max);
}

export function optNum(bag: Bag, key: string, min: number, max: number): number | undefined {
  const v = bag[key];
  if (absent(v)) return undefined;
  if (typeof v !== "number" || !Number.isFinite(v) || v < min || v > max) {
    throw invalid(`${key} must be a number between ${min} and ${max}.`);
  }
  return v;
}

export function parseDate(v: unknown, key: string): string {
  if (typeof v !== "string" || !DATE_RE.test(v)) {
    throw invalid(`${key} must be a date (YYYY-MM-DD).`);
  }
  const d = new Date(`${v}T00:00:00Z`);
  if (Number.isNaN(d.getTime()) || d.toISOString().slice(0, 10) !== v) {
    throw invalid(`${key} must be a valid date.`);
  }
  return v;
}

export const reqDate = (bag: Bag, key: string): string => parseDate(bag[key], key);

/** ISO-8601 timestamp, normalised to UTC; undefined when not provided. */
export function optTimestamp(bag: Bag, key: string): string | undefined {
  const v = bag[key];
  if (absent(v)) return undefined;
  const ms = typeof v === "string" ? Date.parse(v) : Number.NaN;
  if (Number.isNaN(ms)) throw invalid(`${key} must be an ISO-8601 timestamp.`);
  return new Date(ms).toISOString();
}

/** Optional value restricted to [allowed]; undefined when not provided. */
export function optEnum<T extends string>(
  bag: Bag,
  key: string,
  allowed: readonly T[],
): T | undefined {
  const v = bag[key];
  if (absent(v)) return undefined;
  if (typeof v !== "string" || !(allowed as readonly string[]).includes(v)) {
    throw invalid(`${key} must be one of: ${allowed.join(", ")}.`);
  }
  return v as T;
}

export interface Page {
  limit: number;
  offset: number;
}

export function pageVars(bag: Bag): Page {
  return { limit: reqInt(bag, "limit", 1, 1000), offset: reqInt(bag, "offset", 0, 10_000_000) };
}
