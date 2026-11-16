import assert from "node:assert/strict";
import { afterEach, describe, it } from "node:test";
import { BRANCH_HAS_HISTORY_MESSAGE, branchDeletionBlocker } from "../branches/branchDeletion";
import { setDbForTests } from "../db";
import { FakeDb } from "./fakeDb";

afterEach(() => setDbForTests(undefined));

describe("branch deletion", () => {
  it("is allowed for a branch with no employees, returns or attendance", async () => {
    setDbForTests(new FakeDb().when("count(*)", [{ n: 0 }]));
    assert.equal(await branchDeletionBlocker("b1", async () => false), null);
  });

  it("is refused while employees or branch managers are assigned", async () => {
    setDbForTests(
      new FakeDb().when("user_branch_assignment", [{ n: 1 }]).when("return_record", [{ n: 0 }]),
    );
    assert.equal(await branchDeletionBlocker("b1", async () => false), BRANCH_HAS_HISTORY_MESSAGE);
  });

  it("is refused while returns exist for the branch", async () => {
    setDbForTests(
      new FakeDb().when("user_branch_assignment", [{ n: 0 }]).when("return_record", [{ n: 3 }]),
    );
    assert.equal(await branchDeletionBlocker("b1", async () => false), BRANCH_HAS_HISTORY_MESSAGE);
  });

  it("is refused while attendance exists for the branch", async () => {
    setDbForTests(
      new FakeDb().when("user_branch_assignment", [{ n: 0 }]).when("return_record", [{ n: 0 }]),
    );
    assert.equal(await branchDeletionBlocker("b1", async () => true), BRANCH_HAS_HISTORY_MESSAGE);
  });
});
