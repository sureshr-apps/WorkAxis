import { randomUUID } from "node:crypto";
import { logger } from "firebase-functions/v2";
import { getAuth } from "firebase-admin/auth";
import { effectiveStatus } from "../auth/actor";
import { applyClaims, buildClaims } from "../auth/claims";
import type { NormalizedIdentity } from "../auth/aliasKeys";
import type { AccountStatus, Role } from "../auth/roles";
import { conflict } from "../errors";
import { releaseAliases, reserveAliasesTx, writeProfile } from "../firestore/userStore";
import {
  deleteMemberByAuthUid,
  getMemberByAuthUid,
  insertMember,
} from "../sql/members";
import { isUniqueViolation } from "../db";
import type { ProvisionResult } from "./requestLedger";

export interface ProvisionPlan {
  uid: string;
  identity: NormalizedIdentity;
  fullName: string;
  password: string;
  role: Role;
  organizationId?: string;
  branchIds: string[];
  createdByUid?: string;
  dailyWorkHours?: number;
  shiftHours?: string;
  weeklyDaysOff?: number[];
  employeeCode?: string;
  aadhaarNumber?: string;
  aadhaarPhotoUrl?: string;
  dateOfBirth?: string;
  gender?: string;
  address?: string;
  profilePhotoUrl?: string;
  designation?: string;
  joiningDate?: string;
  relievingDate?: string | null;
  salary?: number;
  assetDetails?: string;
}

/**
 * Cross-store creation order (none of Auth/SQL/Firestore is atomic):
 *   1 reserve aliases (Firestore tx, create-only)   -> uniqueness gate
 *   2 insert SQL member + assignments (SQL tx)      -> authoritative record
 *   3 create Auth user (pre-generated uid)
 *   4 set custom claims
 *   5 write users/{uid} projection
 * Every step is idempotent for the same uid, so a retry with the same
 * requestId resumes. On failure `compensate` removes what this uid created.
 */
export async function runProvision(plan: ProvisionPlan): Promise<ProvisionResult> {
  const { uid, identity } = plan;

  await reserveAliasesTx({ keys: identity.aliasKeys, loginEmail: identity.loginEmail }, uid);

  let member = await getMemberByAuthUid(uid);
  if (!member) {
    try {
      await insertMember(
        {
          id: randomUUID(),
          authUid: uid,
          organizationId: plan.organizationId,
          fullName: plan.fullName,
          username: identity.username,
          email: identity.loginEmail,
          phone: identity.phone,
          role: plan.role,
          employeeCode: plan.employeeCode,
        },
        plan.branchIds,
        plan.role === "employee" || plan.role === "branchManager"
          ? {
              createdByUid: plan.createdByUid,
              effectiveFrom: plan.joiningDate,
              dailyWorkHours: plan.dailyWorkHours,
              shiftHours: plan.shiftHours,
              weeklyDaysOff: plan.weeklyDaysOff,
              monthlySalary: plan.salary,
            }
          : undefined,
      );
    } catch (e) {
      if (isUniqueViolation(e)) {
        throw conflict("That username, email or phone number is already in use.");
      }
      throw e;
    }
    member = await getMemberByAuthUid(uid);
  }
  if (!member) throw new Error("Member row missing after insert.");

  // A resumed request must not re-enable a member whose license has lapsed.
  const status = effectiveStatus(member);
  await upsertAuthUser(plan, status);
  await applyClaims(
    uid,
    buildClaims({
      role: plan.role,
      organizationId: plan.organizationId,
      branchIds: plan.branchIds,
      status,
    }),
  );
  await writeProfile(member, {
    dailyWorkHours: plan.dailyWorkHours,
    shiftHours: plan.shiftHours,
    aadhaarNumber: plan.aadhaarNumber,
    aadhaarPhotoUrl: plan.aadhaarPhotoUrl,
    dateOfBirth: plan.dateOfBirth,
    gender: plan.gender,
    address: plan.address,
    profilePhotoUrl: plan.profilePhotoUrl,
    designation: plan.designation,
    joiningDate: plan.joiningDate,
    relievingDate: plan.relievingDate,
    salary: plan.salary,
    assetDetails: plan.assetDetails,
  });

  return {
    uid,
    memberId: member.id,
    username: identity.username,
    loginEmail: identity.loginEmail,
    ...(member.employeeCode ? { employeeCode: member.employeeCode } : {}),
  };
}

async function upsertAuthUser(plan: ProvisionPlan, status: AccountStatus): Promise<void> {
  const auth = getAuth();
  const disabled = status !== "active";
  try {
    await auth.getUser(plan.uid);
    await auth.updateUser(plan.uid, {
      email: plan.identity.loginEmail,
      password: plan.password,
      displayName: plan.fullName,
      disabled,
    });
  } catch (e) {
    if ((e as { code?: string }).code !== "auth/user-not-found") throw mapAuthError(e);
    try {
      await auth.createUser({
        uid: plan.uid,
        email: plan.identity.loginEmail,
        password: plan.password,
        displayName: plan.fullName,
        emailVerified: false,
        disabled,
      });
    } catch (ce) {
      throw mapAuthError(ce);
    }
  }
}

function mapAuthError(e: unknown): unknown {
  if ((e as { code?: string }).code === "auth/email-already-exists") {
    return conflict("That email is already in use.");
  }
  return e;
}

/** Best-effort rollback; each step logs but never throws. */
export async function compensate(plan: ProvisionPlan): Promise<void> {
  const { uid, identity } = plan;
  await attempt("delete auth user", () => getAuth().deleteUser(uid), ["auth/user-not-found"]);
  await attempt("delete sql member", () => deleteMemberByAuthUid(uid));
  await attempt("release aliases", () => releaseAliases(identity.aliasKeys, uid));
}

async function attempt(
  what: string,
  fn: () => Promise<unknown>,
  ignoreCodes: string[] = [],
): Promise<void> {
  try {
    await fn();
  } catch (e) {
    const code = (e as { code?: string }).code ?? "";
    if (!ignoreCodes.includes(code)) logger.error(`compensation failed: ${what}`, e);
  }
}
