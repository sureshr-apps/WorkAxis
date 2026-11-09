import type { NormalizedIdentity } from "../auth/aliasKeys";

/** Small seam for fault-injection tests of cross-store update/compensation. */
export interface AccountUpdateSteps {
  reserve(identity: NormalizedIdentity): Promise<void>;
  updateAuth(identity: NormalizedIdentity, name: string): Promise<void>;
  commitSql(): Promise<void>;
  release(keys: string[]): Promise<void>;
  project(): Promise<void>;
  complete(): Promise<void>;
  recordRecoveryFailure(error: unknown): void;
}

export async function runAccountUpdate(
  before: NormalizedIdentity,
  after: NormalizedIdentity,
  oldName: string,
  newName: string,
  steps: AccountUpdateSteps,
): Promise<{ projectionPending: boolean }> {
  try {
    await steps.reserve(after);
    await steps.updateAuth(after, newName);
    await steps.commitSql();
  } catch (error) {
    // Attempt every compensation; a durable job repairs any failed step.
    for (const compensate of [
      () => steps.updateAuth(before, oldName),
      () => steps.reserve(before),
      () =>
        steps.release(
          after.aliasKeys.filter((key) => !before.aliasKeys.includes(key)),
        ),
    ]) {
      try {
        await compensate();
      } catch (failure) {
        steps.recordRecoveryFailure(failure);
      }
    }
    throw error;
  }
  try {
    await steps.release(
      before.aliasKeys.filter((key) => !after.aliasKeys.includes(key)),
    );
    await steps.project();
    await steps.complete();
    return { projectionPending: false };
  } catch (error) {
    // The SQL transaction succeeded. Do not report the business update as failed.
    steps.recordRecoveryFailure(error);
    return { projectionPending: true };
  }
}
