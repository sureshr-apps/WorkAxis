import { normalizeEmail, normalizePhone, normalizeUsername, syntheticEmailFor } from "../util/identifiers";

export interface IdentityInput {
  username: string;
  email?: string;
  phone?: string;
}

export interface NormalizedIdentity {
  username: string;
  /** Email stored in Auth/SQL: the real one, or a synthetic address. */
  loginEmail: string;
  hasRealEmail: boolean;
  phone?: string;
  /** All alias document ids that resolve to this account. */
  aliasKeys: string[];
}

export function normalizeIdentity(input: IdentityInput): NormalizedIdentity {
  const username = normalizeUsername(input.username);
  const email = input.email ? normalizeEmail(input.email) : undefined;
  const phone = input.phone ? normalizePhone(input.phone) : undefined;
  const aliasKeys = [username];
  if (email) aliasKeys.push(email);
  if (phone) aliasKeys.push(phone);
  return {
    username,
    loginEmail: email ?? syntheticEmailFor(username),
    hasRealEmail: email !== undefined,
    phone,
    aliasKeys,
  };
}
