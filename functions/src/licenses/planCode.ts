import { randomBytes } from "node:crypto";

const SUFFIX_LENGTH = 10;
const FALLBACK_SUFFIX = "PLAN";

/**
 * Plan code: `PLN-<12 hex>-<NAME>`. The hex part is random, and the suffix is
 * the name's upper-case letters and digits, truncated to 10 characters.
 * `entropy` (12 hex characters) is injectable for tests.
 */
export function generatePlanCode(
  name: string,
  entropy: string = randomBytes(6).toString("hex"),
): string {
  const suffix =
    name.toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, SUFFIX_LENGTH) || FALLBACK_SUFFIX;
  return `PLN-${entropy.toUpperCase()}-${suffix}`;
}
