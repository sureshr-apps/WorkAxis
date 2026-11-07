import { SYNTHETIC_EMAIL_DOMAIN } from "../config";
import { invalid } from "../errors";

/**
 * Alias normalization (document ids in `user_aliases`):
 *  - username: trimmed, lowercased; 3-50 chars of [a-z0-9._-], must contain a
 *    letter (so it can never look like a phone number) and no '@'.
 *  - email: trimmed, lowercased.
 *  - phone: digits with an optional leading '+', all other characters
 *    stripped; E.164-ish: '+' followed by 7-15 digits (country code
 *    required). A number without '+' is rejected as ambiguous.
 */
export type IdentifierKind = "username" | "email" | "phone";

const USERNAME_RE = /^[a-z0-9._-]{3,50}$/;
const EMAIL_RE = /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/;
const PHONE_LOOKS_RE = /^[+\d][\d\s().-]*$/;

export function normalizeUsername(raw: string): string {
  const v = raw.trim().toLowerCase();
  if (!USERNAME_RE.test(v) || !/[a-z]/.test(v)) {
    throw invalid(
      "Username must be 3-50 characters (letters, digits, . _ -) and include a letter.",
    );
  }
  return v;
}

export function normalizeEmail(raw: string): string {
  const v = raw.trim().toLowerCase();
  if (v.length > 100 || !EMAIL_RE.test(v)) throw invalid("Enter a valid email address.");
  return v;
}

export function normalizePhone(raw: string): string {
  const stripped = raw.trim().replace(/[\s().-]/g, "");
  if (!/^\+\d{7,15}$/.test(stripped)) {
    throw invalid("Enter the phone number with country code, e.g. +919876543210.");
  }
  return stripped;
}

/** Classifies and normalizes a login identifier typed by a user. */
export function classifyIdentifier(
  raw: string,
): { kind: IdentifierKind; key: string } | null {
  const v = raw.trim();
  if (v.length === 0 || v.length > 120) return null;
  try {
    if (v.includes("@")) return { kind: "email", key: normalizeEmail(v) };
    if (PHONE_LOOKS_RE.test(v)) return { kind: "phone", key: normalizePhone(v) };
    return { kind: "username", key: normalizeUsername(v) };
  } catch {
    return null;
  }
}

export const syntheticEmailFor = (username: string): string =>
  `${username}@${SYNTHETIC_EMAIL_DOMAIN}`;
