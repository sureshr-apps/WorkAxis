import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { DomainError } from "../errors";
import {
  REQUIRED_EMPLOYEE_CREATION_FIELDS,
  SELF_LOCKED_FIELDS,
  assertEmployeeCreationComplete,
  assertNoSelfEmploymentEdit,
  parseEmployeeExtras,
  validateEmployeeCode,
  withoutClears,
} from "../util/employeeProfile";

const denies = (fn: () => void, code: string) =>
  assert.throws(fn, (e) => e instanceof DomainError && e.code === code);

describe("assertNoSelfEmploymentEdit", () => {
  it("blocks each employment-control field on the actor's own account", () => {
    const samples: Record<string, unknown> = {
      salary: 1,
      designation: "Lead",
      joiningDate: "2026-01-01",
      relievingDate: "2026-12-01",
      employeeCode: "EMP-1",
      dailyWorkHours: 8,
      shiftHours: "9-5",
      weeklyDaysOff: [0, 6],
      assetDetails: "Laptop",
    };
    assert.deepEqual(Object.keys(samples).sort(), [...SELF_LOCKED_FIELDS].sort());
    for (const [field, value] of Object.entries(samples)) {
      denies(
        () => assertNoSelfEmploymentEdit("u1", "u1", { [field]: value }),
        "permission-denied",
      );
    }
  });

  it("treats clearing the relieving date as an employment edit", () => {
    denies(
      () => assertNoSelfEmploymentEdit("u1", "u1", { relievingDate: null }),
      "permission-denied",
    );
  });

  it("allows personal fields on one's own account", () => {
    assertNoSelfEmploymentEdit("u1", "u1", {
      dateOfBirth: "1990-01-01",
      gender: "F",
      address: "Somewhere",
      profilePhotoUrl: "https://x/y.png",
      aadhaarNumber: "123412341234",
      aadhaarPhotoUrl: "https://x/a.png",
    });
    assertNoSelfEmploymentEdit("u1", "u1", {});
  });

  it("allows managing someone else's employment details", () => {
    assertNoSelfEmploymentEdit("manager", "u1", { salary: 5, employeeCode: "EMP-9" });
  });
});

describe("employee code validation", () => {
  it("accepts 1-32 chars of letters, digits, dot, underscore, hyphen", () => {
    assert.equal(validateEmployeeCode(" EMP-10001 "), "EMP-10001");
    assert.equal(validateEmployeeCode("a.b_c-9"), "a.b_c-9");
    assert.equal(validateEmployeeCode("x".repeat(32)), "x".repeat(32));
  });

  it("rejects empty, too long and unsafe characters", () => {
    for (const bad of ["", "x".repeat(33), "EMP 1", "EMP/1", "é1"]) {
      denies(() => validateEmployeeCode(bad), "invalid-argument");
    }
  });

  it("normalizes weekly days off and rejects the replaced single-day field", () => {
    assert.deepEqual(parseEmployeeExtras({ weeklyDaysOff: [6, 0, 6] }).weeklyDaysOff, [0, 6]);
    assert.deepEqual(parseEmployeeExtras({ weeklyDaysOff: [] }).weeklyDaysOff, []);
    for (const bad of [[7], [-1], [1.5], ["1"], 3, null]) {
      denies(() => parseEmployeeExtras({ weeklyDaysOff: bad }), "invalid-argument");
    }
    denies(() => parseEmployeeExtras({ weeklyDayOff: 0 }), "invalid-argument");
  });

  it("is applied when parsing request extras", () => {
    assert.equal(parseEmployeeExtras({ employeeCode: "EMP-7" }).employeeCode, "EMP-7");
    denies(() => parseEmployeeExtras({ employeeCode: "bad id" }), "invalid-argument");
  });
});

const CLEARABLE = [
  "aadhaarNumber",
  "aadhaarPhotoUrl",
  "dateOfBirth",
  "gender",
  "address",
  "profilePhotoUrl",
  "designation",
  "joiningDate",
  "relievingDate",
  "salary",
  "assetDetails",
] as const;

describe("clear semantics (null = clear, omitted = unchanged)", () => {
  it("accepts explicit null for every optional field", () => {
    const parsed = parseEmployeeExtras(Object.fromEntries(CLEARABLE.map((k) => [k, null])));
    for (const k of CLEARABLE) assert.equal(parsed[k], null, k);
  });

  it("leaves omitted fields undefined", () => {
    const parsed = parseEmployeeExtras({});
    for (const k of CLEARABLE) assert.equal(parsed[k], undefined, k);
  });

  it("does not let null clear always-required fields", () => {
    for (const k of ["dailyWorkHours", "shiftHours", "employeeCode"]) {
      denies(() => parseEmployeeExtras({ [k]: null }), "invalid-argument");
    }
  });

  it("still validates real values and the date ordering", () => {
    denies(() => parseEmployeeExtras({ aadhaarNumber: "12" }), "invalid-argument");
    denies(
      () => parseEmployeeExtras({ joiningDate: "2026-05-01", relievingDate: "2026-04-01" }),
      "invalid-argument",
    );
    assert.equal(parseEmployeeExtras({ joiningDate: null, relievingDate: "2026-04-01" }).relievingDate, "2026-04-01");
  });

  it("counts clearing an employment field as a self-edit but not a personal one", () => {
    for (const f of SELF_LOCKED_FIELDS.filter((x) => (CLEARABLE as readonly string[]).includes(x))) {
      denies(() => assertNoSelfEmploymentEdit("u1", "u1", { [f]: null }), "permission-denied");
    }
    assertNoSelfEmploymentEdit("u1", "u1", { gender: null, address: null, aadhaarNumber: null });
  });

  it("withoutClears drops nulls for creation", () => {
    assert.deepEqual(withoutClears({ designation: null, gender: "F", salary: 0 }), { gender: "F", salary: 0 });
  });
});

describe("employee creation requirements", () => {
  const full = {
    aadhaarNumber: "123412341234",
    aadhaarPhotoUrl: "gs://a",
    designation: "Cashier",
    salary: 100,
    dailyWorkHours: 8,
    shiftHours: "9-5",
  };

  it("rejects an employee missing each required field", () => {
    for (const f of REQUIRED_EMPLOYEE_CREATION_FIELDS) {
      const { [f]: _omit, ...rest } = full;
      denies(() => assertEmployeeCreationComplete("employee", rest), "invalid-argument");
    }
  });

  it("accepts a complete employee, and a salary of zero", () => {
    assertEmployeeCreationComplete("employee", full);
    assertEmployeeCreationComplete("employee", { ...full, salary: 0 });
  });

  it("does not require them for orgAdmin or branchManager", () => {
    assertEmployeeCreationComplete("orgAdmin", {});
    assertEmployeeCreationComplete("branchManager", {});
  });
});

describe("parseEmployeeExtras aadhaarNumber", () => {
  it("accepts 12 digits and strips spaces", () => {
    assert.equal(parseEmployeeExtras({ aadhaarNumber: "1234 5678 9012" }).aadhaarNumber, "123456789012");
    assert.equal(parseEmployeeExtras({ aadhaarNumber: "123412341234" }).aadhaarNumber, "123412341234");
  });

  it("rejects anything that is not exactly 12 digits", () => {
    for (const bad of ["12345678901", "1234567890123", "12345678901a", "ddddddddddddd"]) {
      assert.throws(() => parseEmployeeExtras({ aadhaarNumber: bad }), { code: "invalid-argument" }, bad);
    }
  });

  it("does not strip letters from a valid value", () => {
    assert.throws(() => parseEmployeeExtras({ aadhaarNumber: "s23456789012" }), { code: "invalid-argument" });
  });
});
