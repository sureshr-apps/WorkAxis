import { withIdentityLocks } from "../accounts/identityLocks";
import { logger } from "firebase-functions/v2";
import { queueIdentitySync } from "../accounts/identitySync";
import { runAccountUpdate } from "../accounts/updateWorkflow";
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
  updateMemberWithAssignments,
} from "../sql/members";
import {
  asBag,
  optString,
  optStringArray,
  reqEnum,
  reqString,
} from "../util/input";

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
    return withIdentityLocks([targetUid], async () => {
      const { member, target } = await loadTarget(targetUid);

      const role =
        bag.role === undefined ? member.role : reqEnum(bag, "role", ROLES);
      const requested = optStringArray(bag, "branchIds");
      const branchIds = finalBranchIds(
        actor,
        member.branchIds,
        requested,
        role,
      );
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
      const emailClear = bag.email === null || bag.email === "";
      const emailIn = optString(bag, "email", 3, 100);

      const before = normalizeIdentity({
        username: member.username,
        email: member.email.endsWith(".invalid") ? undefined : member.email,
        phone: member.phone,
      });
      const after = normalizeIdentity({
        username: member.username,
        email: emailClear
          ? undefined
          : (emailIn ?? (before.hasRealEmail ? before.loginEmail : undefined)),
        phone: phoneClear ? undefined : (phoneIn ?? member.phone),
      });

      const job = await queueIdentitySync(targetUid, [
        ...new Set([...before.aliasKeys, ...after.aliasKeys]),
      ]);
      let result;
      try {
        result = await runAccountUpdate(
          before,
          after,
          member.fullName,
          fullName,
          {
            reserve: (identity) =>
              reserveAliasesTx(
                { keys: identity.aliasKeys, loginEmail: identity.loginEmail },
                targetUid,
              ),
            updateAuth: async (identity, name) => {
              await getAuth().updateUser(targetUid, {
                email: identity.loginEmail,
                displayName: name,
              });
            },
            commitSql: () =>
              updateMemberWithAssignments(
                member.id,
                {
                  fullName,
                  email: after.loginEmail,
                  phone: after.phone ?? null,
                  role,
                },
                branchIds,
              ),
            release: (keys) => releaseAliases(keys, targetUid),
            project: async () => {
              const updated = await getMemberByAuthUid(targetUid);
              if (!updated) throw new Error("Updated member missing.");
              await refreshProjection(
                updated,
                scopeChanged(member, role, branchIds),
              );
            },
            complete: async () => {
              await job.delete();
            },
            recordRecoveryFailure: (error) =>
              logger.error("Account update recovery pending", {
                jobId: job.id,
                errorType: error instanceof Error ? error.name : "unknown",
              }),
          },
        );
      } catch (error) {
        if (isUniqueViolation(error))
          throw conflict("That email or phone number is already in use.");
        throw error;
      }
      return { uid: targetUid, ...result };
    });
  }),
);
