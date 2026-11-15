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
import { FieldValue } from "firebase-admin/firestore";
import {
  buildProfilePatch,
  privateKeyScrub,
  releaseAliases,
  reserveAliasesTx,
  usersCol,
  writeEmployeePrivate,
} from "../firestore/userStore";
import { assertOrgAndBranchesValid } from "../provisioning/scope";
import { isUniqueViolation } from "../db";
import {
  getMemberByAuthUid,
  updateMemberWithAssignments,
} from "../sql/members";
import { assertNoSelfEmploymentEdit, parseEmployeeExtras } from "../util/employeeProfile";
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
 * Optional employee profile fields: omitted = unchanged, explicit null = clear
 * (never for dailyWorkHours/shiftHours/employeeCode). See docs/backend-api.md.
 * Same authorization matrix as provisionUser; refreshes claims, profile and
 * aliases; revokes sessions when role or branch scope changes.
 */
export const updateUserAccount = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    const bag = asBag(request.data);
    const targetUid = reqString(bag, "targetUid", 1, 128);
    // Validate optional profile fields up front: validation after the SQL commit
    // would be reported as a pending projection instead of rejecting the request.
    const extras = parseEmployeeExtras(bag);
    assertNoSelfEmploymentEdit(actor.uid, targetUid, extras);
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
                  employeeCode: extras.employeeCode,
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
              // Patch semantics: value = set, null = delete the field, omitted = keep.
              const updates: Record<string, unknown> = {
                updatedAt: FieldValue.serverTimestamp(),
                ...buildProfilePatch(extras),
              };

              // employeeCode is projected from SQL by refreshProjection; sensitive
              // HR fields live only in employee_private.
              await writeEmployeePrivate(targetUid, member.organizationId, extras);
              await usersCol()
                .doc(targetUid)
                .set({ ...updates, ...privateKeyScrub() }, { merge: true });
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
