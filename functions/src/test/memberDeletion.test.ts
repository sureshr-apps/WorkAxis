import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { MEMBER_HAS_HISTORY_MESSAGE, memberDeletionBlocker } from "../employees/memberDeletion";

describe("memberDeletionBlocker", () => {
  it("allows deleting an account with no returns and no attendance", () => {
    assert.equal(memberDeletionBlocker({ returnCount: 0, hasAttendance: false }), null);
  });

  it("refuses an account that has return records", () => {
    assert.equal(memberDeletionBlocker({ returnCount: 2, hasAttendance: false }), MEMBER_HAS_HISTORY_MESSAGE);
  });

  it("refuses an account that has attendance records", () => {
    assert.equal(memberDeletionBlocker({ returnCount: 0, hasAttendance: true }), MEMBER_HAS_HISTORY_MESSAGE);
  });
});
