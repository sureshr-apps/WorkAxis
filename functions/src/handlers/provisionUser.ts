import { onCall } from "firebase-functions/v2/https";
import { resolveActor } from "../auth/actor";
import { normalizeIdentity } from "../auth/aliasKeys";
import { assertCanProvision } from "../auth/authorization";
import { ROLES } from "../auth/roles";
import { MIN_PASSWORD_LENGTH, callableOptions } from "../config";
import { guarded } from "../errors";
import { assertOrgAndBranchesValid } from "../provisioning/scope";
import { claimRequest, markDone, markFailed } from "../provisioning/requestLedger";
import { compensate, runProvision, type ProvisionPlan } from "../provisioning/provisionWorkflow";
import { asBag, optString, optStringArray, reqEnum, reqString } from "../util/input";

/**
 * provisionUser (callable, asia-south1)
 * Request:  { requestId, fullName, username, email?, phone?, password, role,
 *             organizationId?, branchIds? }
 * Response: { uid, memberId, username, loginEmail }
 */
export const provisionUser = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    const bag = asBag(request.data);
    const requestId = reqString(bag, "requestId", 8, 100);
    const role = reqEnum(bag, "role", ROLES);
    const password = reqString(bag, "password", MIN_PASSWORD_LENGTH, 128);
    const identity = normalizeIdentity({
      username: reqString(bag, "username", 3, 50),
      email: optString(bag, "email", 3, 100),
      phone: optString(bag, "phone", 7, 30),
    });
    const target = {
      role,
      organizationId: optString(bag, "organizationId", 1, 100),
      branchIds: optStringArray(bag, "branchIds") ?? [],
    };
    // orgAdmin has org-wide scope; branches are only meaningful for lower roles.
    if (role === "orgAdmin") target.branchIds = [];

    assertCanProvision(actor, target);
    if (target.organizationId) {
      await assertOrgAndBranchesValid(target.organizationId, target.branchIds);
    }

    const claim = await claimRequest(actor.uid, requestId);
    if (claim.kind === "done") return claim.result;

    const plan: ProvisionPlan = {
      uid: claim.uid,
      identity,
      fullName: reqString(bag, "fullName", 1, 100),
      password,
      role,
      organizationId: target.organizationId,
      branchIds: target.branchIds,
    };
    try {
      const result = await runProvision(plan);
      await markDone(claim.ref, result);
      return result;
    } catch (e) {
      await compensate(plan);
      await markFailed(claim.ref, e instanceof Error ? e.name : "error");
      throw e;
    }
  }),
);
