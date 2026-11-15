import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { FieldValue } from "firebase-admin/firestore";
import { buildPrivatePatch, buildProfilePatch } from "../firestore/userStore";

const isDelete = (v: unknown) => v instanceof Object && (v as FieldValue).isEqual(FieldValue.delete());

describe("buildProfilePatch", () => {
  it("sets values, deletes nulls and skips undefined", () => {
    const patch = buildProfilePatch({
      designation: "Lead",
      address: null,
      gender: null,
      profilePhotoUrl: null,
      relievingDate: null,
      assetDetails: undefined,
    });
    assert.equal(patch.designation, "Lead");
    for (const k of ["address", "gender", "profilePhotoUrl", "relievingDate"]) {
      assert.ok(isDelete(patch[k]), k);
    }
    assert.equal("assetDetails" in patch, false);
    assert.equal("salary" in patch, false, "private keys never land on users/{uid}");
  });
});

describe("buildPrivatePatch", () => {
  it("deletes cleared private fields and sets given ones", () => {
    const patch = buildPrivatePatch({ salary: null, aadhaarNumber: "123412341234", aadhaarPhotoUrl: null });
    assert.ok(isDelete(patch.salary));
    assert.ok(isDelete(patch.aadhaarPhotoUrl));
    assert.equal(patch.aadhaarNumber, "123412341234");
  });

  it("is empty when nothing is supplied", () => {
    assert.deepEqual(buildPrivatePatch(undefined), {});
    assert.deepEqual(buildPrivatePatch({}), {});
  });
});
