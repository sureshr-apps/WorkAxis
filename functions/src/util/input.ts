import { invalid } from "../errors";

type Bag = Record<string, unknown>;

export function asBag(data: unknown): Bag {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    throw invalid("Request body must be an object.");
  }
  return data as Bag;
}

export function reqString(bag: Bag, key: string, min = 1, max = 200): string {
  const v = bag[key];
  if (typeof v !== "string") throw invalid(`${key} is required.`);
  const t = v.trim();
  if (t.length < min || t.length > max) {
    throw invalid(`${key} must be between ${min} and ${max} characters.`);
  }
  return t;
}

export function optString(bag: Bag, key: string, min = 1, max = 200): string | undefined {
  if (bag[key] === undefined || bag[key] === null || bag[key] === "") return undefined;
  return reqString(bag, key, min, max);
}

export function reqNumber(bag: Bag, key: string, min: number, max: number): number {
  const v = bag[key];
  if (typeof v !== "number" || !Number.isFinite(v) || v < min || v > max) {
    throw invalid(`${key} must be a number between ${min} and ${max}.`);
  }
  return v;
}

export function optStringArray(bag: Bag, key: string, maxItems = 100): string[] | undefined {
  const v = bag[key];
  if (v === undefined || v === null) return undefined;
  if (!Array.isArray(v) || v.length > maxItems || v.some((x) => typeof x !== "string" || x.length === 0)) {
    throw invalid(`${key} must be a list of ids.`);
  }
  return [...new Set(v as string[])];
}

export function reqEnum<T extends string>(bag: Bag, key: string, allowed: readonly T[]): T {
  const v = bag[key];
  if (typeof v !== "string" || !(allowed as readonly string[]).includes(v)) {
    throw invalid(`${key} must be one of: ${allowed.join(", ")}.`);
  }
  return v as T;
}
