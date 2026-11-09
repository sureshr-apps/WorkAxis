import { withIdentityLocks } from "../accounts/identityLocks";
import { logger } from "firebase-functions/v2";
import { onCall } from "firebase-functions/v2/https";
import {
  queueIdentitySync,
  syncIdentityWithinLock,
} from "../accounts/identitySync";
import { resolveActor } from "../auth/actor";
import { parseBranchSave, validateManagerPlan } from "../branches/savePlan";
import { callableOptions } from "../config";
import { conflict, guarded, notFound } from "../errors";
import { getBranch } from "../sql/branches";
import {
  branchCreation,
  commitBranchSave,
  loadBranchManagers,
} from "../sql/branchSave";
import { isUniqueViolation } from "../sql/client";
import { listMembersOfOrganization } from "../sql/members";

export const saveBranch = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    const plan = parseBranchSave(actor, request.data);
    if (plan.creating) {
      const replay = await branchCreation(plan.data.id);
      if (replay) {
        if (replay.creationFingerprint !== plan.creationFingerprint)
          throw conflict(
            "This request id was used for different branch details.",
          );
        return { id: replay.id, code: replay.code, projectionPending: true };
      }
    }
    const before = plan.creating ? null : await getBranch(plan.data.id);
    if (
      !plan.creating &&
      (!before || before.organizationId !== actor.organizationId)
    )
      throw notFound("Branch not found.");
    const managers = await loadBranchManagers(plan.data.organizationId);
    const current = managers.filter((m) => m.branchIds.includes(plan.data.id));
    const wanted = managers.filter((m) => plan.managerIds.includes(m.id));
    validateManagerPlan(
      plan.data.organizationId,
      plan.data.id,
      current,
      wanted,
      plan.managerIds,
    );
    const affected = new Set([...current, ...wanted].map((m) => m.authUid));
    // A branch suspension/reactivation changes employee claims as well.
    if (before && before.status !== plan.data.status) {
      for (const member of await listMembersOfOrganization(
        plan.data.organizationId,
      )) {
        if (member.branchIds.includes(plan.data.id))
          affected.add(member.authUid);
      }
    }
    // Durable jobs precede SQL. If SQL fails, projecting its unchanged state is harmless.
    return withIdentityLocks([...affected], async () => {
      const jobs: { uid: string; ref: FirebaseFirestore.DocumentReference }[] =
        [];
      for (const uid of affected)
        jobs.push({ uid, ref: await queueIdentitySync(uid) });
      try {
        await commitBranchSave(
          plan,
          current.map((m) => m.id),
        );
      } catch (error) {
        if (plan.creating) {
          const replay = await branchCreation(plan.data.id);
          if (
            replay &&
            replay.creationFingerprint === plan.creationFingerprint
          ) {
            return {
              id: replay.id,
              code: replay.code,
              projectionPending: true,
            };
          }
        }
        if (isUniqueViolation(error))
          throw conflict("That branch code is already in use.");
        throw error;
      }
      let projectionPending = false;
      for (const job of jobs) {
        try {
          await syncIdentityWithinLock(job.uid);
          await job.ref.delete();
        } catch (error) {
          projectionPending = true;
          logger.error("Branch identity projection pending", {
            jobId: job.ref.id,
            errorType: error instanceof Error ? error.name : "unknown",
          });
        }
      }
      return { id: plan.data.id, code: plan.data.code, projectionPending };
    });
  }),
);
