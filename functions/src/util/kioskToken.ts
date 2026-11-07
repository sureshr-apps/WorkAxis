import { createHash, randomBytes } from "node:crypto";

/** Only the hash is stored server-side. */
export const hashKioskToken = (token: string): string =>
  createHash("sha256").update(token).digest("hex");

export function newKioskToken(): { token: string; hash: string } {
  const token = randomBytes(32).toString("base64url");
  return { token, hash: hashKioskToken(token) };
}
