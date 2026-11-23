import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { readDbSettings, tcpSslOptions } from "../db/connection";

const tcp = { DB_MODE: "tcp", DB_NAME: "workaxis", DB_USER: "app", DB_HOST: "db.example.com", DB_PASSWORD: "x" };

describe("TCP database TLS", () => {
  it("verifies the server certificate by default", () => {
    const settings = readDbSettings(tcp);
    assert.equal(settings.ssl, "verify");
    assert.deepEqual(tcpSslOptions(settings), { rejectUnauthorized: true });
  });

  it("verifies against a private CA when one is given", () => {
    const ca = "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----";
    const settings = readDbSettings({ ...tcp, DB_SSL: "true", DB_SSL_CA: ca });
    assert.deepEqual(tcpSslOptions(settings), { rejectUnauthorized: true, ca });
  });

  it("skips verification only when explicitly asked", () => {
    assert.deepEqual(tcpSslOptions(readDbSettings({ ...tcp, DB_SSL: "no-verify" })), {
      rejectUnauthorized: false,
    });
    assert.equal(tcpSslOptions(readDbSettings({ ...tcp, DB_SSL: "false" })), false);
  });

  it("rejects an unknown DB_SSL value instead of guessing", () => {
    assert.throws(() => readDbSettings({ ...tcp, DB_SSL: "require" }), /DB_SSL must be/);
  });
});
