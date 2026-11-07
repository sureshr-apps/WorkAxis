import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { normalizeIdentity } from "../auth/aliasKeys";
import { hashKioskToken, newKioskToken } from "../util/kioskToken";
import { classifyIdentifier, normalizePhone, normalizeUsername } from "../util/identifiers";
import { workDateStart, workDateString } from "../time/workDate";

describe("identifier normalization", () => {
  it("lowercases and trims usernames and rejects phone-like or bad ones", () => {
    assert.equal(normalizeUsername("  Marcus.Chen "), "marcus.chen");
    assert.throws(() => normalizeUsername("12345678"));
    assert.throws(() => normalizeUsername("a@b"));
    assert.throws(() => normalizeUsername("ab"));
  });

  it("normalizes phones to + and digits and requires a country code", () => {
    assert.equal(normalizePhone("+91 98765-43210"), "+919876543210");
    assert.throws(() => normalizePhone("9876543210"));
  });

  it("classifies login identifiers", () => {
    assert.deepEqual(classifyIdentifier(" A@B.com "), { kind: "email", key: "a@b.com" });
    assert.deepEqual(classifyIdentifier("+91 98765 43210"), { kind: "phone", key: "+919876543210" });
    assert.deepEqual(classifyIdentifier("David.Warner"), { kind: "username", key: "david.warner" });
    assert.equal(classifyIdentifier("not valid!"), null);
  });

  it("builds alias keys and a synthetic login email when none is given", () => {
    const n = normalizeIdentity({ username: "Alex.Rivera", phone: "+919876543212" });
    assert.deepEqual(n.aliasKeys, ["alex.rivera", "+919876543212"]);
    assert.equal(n.loginEmail, "alex.rivera@login.workaxis.invalid");
    assert.equal(n.hasRealEmail, false);
    const withEmail = normalizeIdentity({ username: "alex", email: "A@Acme.com" });
    assert.equal(withEmail.loginEmail, "a@acme.com");
    assert.deepEqual(withEmail.aliasKeys, ["alex", "a@acme.com"]);
  });
});

describe("workDate (Asia/Kolkata)", () => {
  it("rolls the date at IST midnight, not UTC midnight", () => {
    assert.equal(workDateString(new Date("2026-11-06T18:29:00Z")), "2026-11-06");
    assert.equal(workDateString(new Date("2026-11-06T18:31:00Z")), "2026-11-07");
    assert.equal(workDateStart("2026-11-07").toISOString(), "2026-11-06T18:30:00.000Z");
  });
});

describe("kiosk pairing token", () => {
  it("is random, long, and only stored as a hash", () => {
    const a = newKioskToken();
    const b = newKioskToken();
    assert.notEqual(a.token, b.token);
    assert.ok(a.token.length >= 43);
    assert.equal(hashKioskToken(a.token), a.hash);
    assert.notEqual(a.hash, a.token);
  });
});
