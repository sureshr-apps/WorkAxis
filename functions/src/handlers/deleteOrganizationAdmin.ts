import { onCall } from "firebase-functions/v2/https";
import { loadTarget } from "../accounts/target";
import { resolveActor } from "../auth/actor";
import {
  assertCanDeleteOrganizationAdmin,
  assertOrganizationKeepsActiveAdmin,
} from "../auth/authorization";
import { callableOptions } from "../config";
import { guarded } from "../errors";
import { deleteMemberIdentity } from "../organizations/deletionSteps";
import { deleteMemberByAuthUid, listMembersOfOrganization } from "../sql/members";
import { asBag, reqString } from "../util/input";

/**
 * deleteOrganizationAdmin (callable, asia-south1) - platform staff or a peer
 * Organization Admin in the same organization.
 * Request:  { targetUid }
 * Response: { uid, deleted }
 * Refuses to remove an organization's only active administrator. Removes the
 * login identity and profile first and the SQL member last, so a failure
 * leaves the administrator in place and the same call can be retried.
 */
export const deleteOrganizationAdmin = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    const bag = asBag(request.data);
    const targetUid = reqString(bag, "targetUid", 1, 128);

    const { member, target } = await loadTarget(targetUid);
    assertCanDeleteOrganizationAdmin(actor, target);
    const orgMembers = member.organizationId
      ? await listMembersOfOrganization(member.organizationId)
      : [];
    assertOrganizationKeepsActiveAdmin(member, orgMembers);

    await deleteMemberIdentity(member);
    await deleteMemberByAuthUid(targetUid);
    return { uid: targetUid, deleted: true };
  }),
);
