import { denied, invalid } from "../errors";
import { optString } from "./input";

type Bag = Record<string, unknown>;

/**
 * Optional profile fields on provisionUser / updateUserAccount.
 *
 * Wire semantics (updates): key omitted (or "") = unchanged, explicit `null` =
 * clear the stored value. `dailyWorkHours`, `shiftHours` and `employeeCode`
 * can never be cleared (null is rejected). On creation nulls mean "not given".
 */
export interface EmployeeProfileExtras {
  dailyWorkHours?: number;
  shiftHours?: string;
  employeeCode?: string;
  aadhaarNumber?: string | null;
  aadhaarPhotoUrl?: string | null;
  dateOfBirth?: string | null;
  gender?: string | null;
  address?: string | null;
  profilePhotoUrl?: string | null;
  designation?: string | null;
  joiningDate?: string | null;
  relievingDate?: string | null;
  salary?: number | null;
  assetDetails?: string | null;
}

/** Extras with every clear (`null`) dropped, for creation where nothing exists to clear. */
export type CreateEmployeeExtras = {
  [K in keyof EmployeeProfileExtras]?: Exclude<EmployeeProfileExtras[K], null>;
};

export function withoutClears(extras: EmployeeProfileExtras): CreateEmployeeExtras {
  return Object.fromEntries(
    Object.entries(extras).filter(([, v]) => v !== null && v !== undefined),
  ) as CreateEmployeeExtras;
}

/** Fields an employee account must be created with (mirrors the client policy). */
export const REQUIRED_EMPLOYEE_CREATION_FIELDS = [
  "aadhaarNumber",
  "aadhaarPhotoUrl",
  "designation",
  "salary",
  "dailyWorkHours",
  "shiftHours",
] as const satisfies ReadonlyArray<keyof EmployeeProfileExtras>;

/** Rejects creating an employee that lacks any mandatory profile field. */
export function assertEmployeeCreationComplete(role: string, extras: CreateEmployeeExtras): void {
  if (role !== "employee") return;
  const missing = REQUIRED_EMPLOYEE_CREATION_FIELDS.filter((f) => extras[f] === undefined);
  if (missing.length > 0) {
    throw invalid(`Employees require: ${missing.join(", ")}.`);
  }
}

const EMPLOYEE_CODE_PATTERN = /^[A-Za-z0-9._-]{1,32}$/;

/** Returns the trimmed employee ID, or throws invalid-argument when malformed. */
export function validateEmployeeCode(code: string): string {
  const trimmed = code.trim();
  if (!EMPLOYEE_CODE_PATTERN.test(trimmed)) {
    throw invalid("employeeCode must be 1-32 characters: letters, digits, '.', '_' or '-'.");
  }
  return trimmed;
}

/** Employment-control fields an actor may never change on their own account. */
export const SELF_LOCKED_FIELDS = [
  "salary",
  "designation",
  "joiningDate",
  "relievingDate",
  "employeeCode",
  "dailyWorkHours",
  "shiftHours",
  "assetDetails",
] as const satisfies ReadonlyArray<keyof EmployeeProfileExtras>;

/**
 * Throws when an actor edits their own employment-control fields (e.g. a
 * manager raising their own salary). Personal fields stay self-editable.
 */
export function assertNoSelfEmploymentEdit(
  actorUid: string,
  targetUid: string,
  extras: EmployeeProfileExtras,
): void {
  if (actorUid !== targetUid) return;
  if (SELF_LOCKED_FIELDS.some((f) => extras[f] !== undefined)) {
    throw denied("You cannot change your own employment details.");
  }
}

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;
const MAX_SALARY = 100_000_000;

function optNumber(bag: Bag, key: string, min: number, max: number): number | undefined {
  const v = bag[key];
  if (v === undefined || v === null) return undefined;
  if (typeof v !== "number" || !Number.isFinite(v) || v < min || v > max) {
    throw invalid(`${key} must be a number between ${min} and ${max}.`);
  }
  return v;
}

function optIsoDate(bag: Bag, key: string): string | undefined {
  const v = optString(bag, key, 1, 50);
  if (v === undefined) return undefined;
  if (!ISO_DATE.test(v) || Number.isNaN(Date.parse(v))) {
    throw invalid(`${key} must be a date in YYYY-MM-DD format.`);
  }
  return v;
}

function optEmployeeCode(bag: Bag): string | undefined {
  const v = optString(bag, "employeeCode", 1, 50);
  return v === undefined ? undefined : validateEmployeeCode(v);
}

/** Explicit `null` = clear; otherwise the usual optional parse. */
function clearable<T>(bag: Bag, key: string, parse: () => T | undefined): T | null | undefined {
  return bag[key] === null ? null : parse();
}

function neverNull(bag: Bag, key: string): void {
  if (bag[key] === null) throw invalid(`${key} cannot be cleared.`);
}

/**
 * Parses and validates the optional employee profile fields. Call this
 * before any write so bad input is rejected instead of being dropped after the
 * business record has already been committed.
 */
export function parseEmployeeExtras(bag: Bag): EmployeeProfileExtras {
  for (const key of ["dailyWorkHours", "shiftHours", "employeeCode"]) neverNull(bag, key);
  const aadhaarNumber = clearable(bag, "aadhaarNumber", () => optString(bag, "aadhaarNumber", 1, 20));
  if (typeof aadhaarNumber === "string" && !/^d{12}$/.test(aadhaarNumber.replace(/s+/g, ""))) {
    throw invalid("aadhaarNumber must be 12 digits.");
  }
  const joiningDate = clearable(bag, "joiningDate", () => optIsoDate(bag, "joiningDate"));
  const relievingDate = clearable(bag, "relievingDate", () => optIsoDate(bag, "relievingDate"));
  if (typeof joiningDate === "string" && typeof relievingDate === "string" && relievingDate < joiningDate) {
    throw invalid("relievingDate cannot be before joiningDate.");
  }
  return {
    dailyWorkHours: optNumber(bag, "dailyWorkHours", 0.5, 24),
    shiftHours: optString(bag, "shiftHours", 1, 100),
    employeeCode: optEmployeeCode(bag),
    aadhaarNumber: typeof aadhaarNumber === "string" ? aadhaarNumber.replace(/s+/g, "") : aadhaarNumber,
    aadhaarPhotoUrl: clearable(bag, "aadhaarPhotoUrl", () => optString(bag, "aadhaarPhotoUrl", 1, 1000)),
    dateOfBirth: clearable(bag, "dateOfBirth", () => optIsoDate(bag, "dateOfBirth")),
    gender: clearable(bag, "gender", () => optString(bag, "gender", 1, 20)),
    address: clearable(bag, "address", () => optString(bag, "address", 1, 500)),
    profilePhotoUrl: clearable(bag, "profilePhotoUrl", () => optString(bag, "profilePhotoUrl", 1, 1000)),
    designation: clearable(bag, "designation", () => optString(bag, "designation", 1, 100)),
    joiningDate,
    relievingDate,
    salary: clearable(bag, "salary", () => optNumber(bag, "salary", 0, MAX_SALARY)),
    assetDetails: clearable(bag, "assetDetails", () => optString(bag, "assetDetails", 1, 1000)),
  };
}
