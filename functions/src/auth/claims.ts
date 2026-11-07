import { getAuth } from "firebase-admin/auth";
import type { AccountStatus, Role } from "./roles";

/** Custom claims projection. SQL OrganizationMember is authoritative. */
export interface UserClaims {
  role: Role;
  organizationId?: string;
  branchIds: string[];
  status: AccountStatus;
}

export function buildClaims(input: {
  role: Role;
  organizationId?: string;
  branchIds: string[];
  status: AccountStatus;
}): UserClaims {
  const claims: UserClaims = {
    role: input.role,
    branchIds: [...new Set(input.branchIds)].sort(),
    status: input.status,
  };
  if (input.organizationId) claims.organizationId = input.organizationId;
  return claims;
}

export async function applyClaims(uid: string, claims: UserClaims): Promise<void> {
  // Replaces all custom claims; WorkAxis uses no others.
  await getAuth().setCustomUserClaims(uid, { ...claims });
}

/** Disable/enable sign-in and invalidate existing sessions when suspending. */
export async function setSignInState(uid: string, status: AccountStatus): Promise<void> {
  await getAuth().updateUser(uid, { disabled: status !== "active" });
  if (status !== "active") await getAuth().revokeRefreshTokens(uid);
}
