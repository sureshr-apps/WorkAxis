export const ROLES = [
  "platformOwner",
  "platformAdmin",
  "orgAdmin",
  "branchManager",
  "employee",
] as const;
export type Role = (typeof ROLES)[number];

export type AccountStatus = "active" | "suspended";

export const isRole = (v: unknown): v is Role =>
  typeof v === "string" && (ROLES as readonly string[]).includes(v);

export const isPlatformRole = (r: Role): boolean =>
  r === "platformOwner" || r === "platformAdmin";

/** Authoritative view of a caller, built from SQL (never from stale claims). */
export interface Actor {
  uid: string;
  role: Role;
  organizationId?: string;
  branchIds: string[];
}

/** The subject of a provisioning or account-management request. */
export interface Target {
  uid?: string;
  role: Role;
  organizationId?: string;
  branchIds: string[];
}
