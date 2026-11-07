import { getAuth } from "firebase-admin/auth";
import { onCall } from "firebase-functions/v2/https";
import { loadTarget, refreshProjection } from "../accounts/target";
import { finalBranchIds, scopeChanged } from "../accounts/updatePlan";
import { resolveActor } from "../auth/actor";
import { normalizeIdentity } from "../auth/aliasKeys";
import { assertCanManage } from "../auth/authorization";
import { ROLES } from "../auth/roles";
import { callableOptions } from "../config";
import { conflict, guarded } from "../errors";
import { releaseAliases, reserveAliasesTx } from "../firestore/userStore";
import { assertOrgAndBranchesValid } from "../provisioning/scope";
import { isUniqueViolation } from "../sql/client";
import {
  getMemberByAuthUid,
  replaceBranchAssignments,
  updateMember,
} from "../sql/members";
import { asBag, optString, optStringArray, reqEnum, reqString } from "../util/input";

/**
 * updateUserAccount (callable, asia-south1)
 * Request:  { targetUid, fullName?, email?, phone? (string | null to clear),
 *             role?, branchIds? }   (username is immutable)
 * Response: { uid }
 * Same authorization matrix as provisionUser; refreshes claims, profile and
 * aliases; revokes sessions when role or branch scope changes.
 */
export const updateUserAccount = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    const bag = asBag(request.data);
    const targetUid = reqString(bag, "targetUid", 1, 128);
    const { member, target } = await loadTarget(targetUid);

    const role = bag.role === undefined ? member.role : reqEnum(bag, "role", ROLES);
    const requested = optStringArray(bag, "branchIds");
    const branchIds = finalBranchIds(actor, member.branchIds, requested, role);
    assertCanManage(actor, target, "update", {
      role: role !== member.role ? role : undefined,
      branchIds: requested,
    });
    if (member.organizationId && requested !== undefined) {
      await assertOrgAndBranchesValid(member.organizationId, requested);
    }

    const fullName = optString(bag, "fullName", 1, 100) ?? member.fullName;
    const phoneClear = bag.phone === null || bag.phone === "";
    const phoneIn = optString(bag, "phone", 7, 30);
    const emailIn = optString(bag, "email", 3, 100);

    const before = normalizeIdentity({
      username: member.username,
      email: member.email.endsWith(".invalid") ? undefined : member.email,
      phone: member.phone,
    });
    const after = normalizeIdentity({
      username: member.username,
      email: emailIn ?? (before.hasRealEmail ? before.loginEmail : undefined),
      phone: phoneClear ? undefined : phoneIn ?? member.phone,
    });

    const added = after.aliasKeys.filter((k) => !before.aliasKeys.includes(k));
    const removed = before.aliasKeys.filter((k) => !after.aliasKeys.includes(k));
    const emailChanged = after.loginEmail !== before.loginEmail;

    await reserveAliasesTx({ keys: after.aliasKeys, loginEmail: after.loginEmail }, targetUid);
    try {
      if (emailChanged) {
        await getAuth().updateUser(targetUid, { email: after.loginEmail, displayName: fullName });
      } else if (fullName !== member.fullName) {
        await getAuth().updateUser(targetUid, { displayName: fullName });
      }
      await updateMember(member.id, {
        fullName,
        email: after.loginEmail,
        phone: after.phone ?? null,
        role,
      });
      if (branchIds.join() !== member.branchIds.join()) {
        await replaceBranchAssignments(member.id, branchIds);
      }
    } catch (e) {
      await releaseAliases(added, targetUid);
      if (emailChanged) {
        await getAuth().updateUser(targetUid, { email: before.loginEmail }).catch(() => undefined);
      }
      if (isUniqueViolation(e)) throw conflict("That email or phone number is already in use.");
      throw e;
    }
    await releaseAliases(removed, targetUid);

    const updated = await getMemberByAuthUid(targetUid);
    if (updated) await refreshProjection(updated, scopeChanged(member, role, branchIds));
    return { uid: targetUid };
  }),
);
