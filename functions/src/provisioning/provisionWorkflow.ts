import { randomUUID } from "node:crypto";
import { logger } from "firebase-functions/v2";
import { getAuth } from "firebase-admin/auth";
import { applyClaims, buildClaims } from "../auth/claims";
import type { NormalizedIdentity } from "../auth/aliasKeys";
import type { Role } from "../auth/roles";
import { conflict } from "../errors";
import { releaseAliases, reserveAliasesTx, writeProfile } from "../firestore/userStore";
import {
  deleteMemberByAuthUid,
  getMemberByAuthUid,
  insertMember,
} from "../sql/members";
import { isUniqueViolation } from "../sql/client";
import type { ProvisionResult } from "./requestLedger";

export interface ProvisionPlan {
  uid: string;
  identity: NormalizedIdentity;
  fullName: string;
  password: string;
  role: Role;
  organizationId?: string;
  branchIds: string[];
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
        },
        plan.branchIds,
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

  await upsertAuthUser(plan);
  await applyClaims(
    uid,
    buildClaims({
      role: plan.role,
      organizationId: plan.organizationId,
      branchIds: plan.branchIds,
      status: "active",
    }),
  );
  await writeProfile(member);

  return {
    uid,
    memberId: member.id,
    username: identity.username,
    loginEmail: identity.loginEmail,
  };
}

async function upsertAuthUser(plan: ProvisionPlan): Promise<void> {
  const auth = getAuth();
  try {
    await auth.getUser(plan.uid);
    await auth.updateUser(plan.uid, {
      email: plan.identity.loginEmail,
      password: plan.password,
      displayName: plan.fullName,
      disabled: false,
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
