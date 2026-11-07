import { sqlMutate, sqlQuery } from "./client";

export interface BranchRecord {
  id: string;
  organizationId: string;
  status: string;
  latitude?: number;
  longitude?: number;
  geofenceRadiusMeters?: number;
}

interface BranchRow {
  id: string;
  status: string;
  latitude?: number | null;
  longitude?: number | null;
  geofenceRadiusMeters?: number | null;
  organization: { id: string };
}

export async function getBranches(ids: string[]): Promise<BranchRecord[]> {
  if (ids.length === 0) return [];
  const data = await sqlQuery<{ branches: BranchRow[] }>(
    `query BranchesByIds($ids: [String!]!) {
       branches(where: { id: { in: $ids } }) {
         id status latitude longitude geofenceRadiusMeters organization { id }
       }
     }`,
    { ids },
  );
  return data.branches.map((b) => ({
    id: b.id,
    organizationId: b.organization.id,
    status: b.status,
    latitude: b.latitude ?? undefined,
    longitude: b.longitude ?? undefined,
    geofenceRadiusMeters: b.geofenceRadiusMeters ?? undefined,
  }));
}

export async function getBranch(id: string): Promise<BranchRecord | null> {
  return (await getBranches([id]))[0] ?? null;
}

export interface OrganizationRecord {
  id: string;
  status: string;
}

export async function getOrganization(id: string): Promise<OrganizationRecord | null> {
  const data = await sqlQuery<{ organization: OrganizationRecord | null }>(
    `query OrgById($id: String!) { organization(id: $id) { id status } }`,
    { id },
  );
  return data.organization;
}

export async function setOrganizationStatusSql(id: string, status: string): Promise<void> {
  await sqlMutate(
    `mutation SetOrgStatus($id: String!, $status: String!) {
       organization_update(id: $id, data: { status: $status })
     }`,
    { id, status },
  );
}
