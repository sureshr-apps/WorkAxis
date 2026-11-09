// Run only under the local SQL Connect emulator; never contact a cloud service.
const assert = require('node:assert/strict');
const { beforeEach, test } = require('node:test');
const { initializeApp } = require('firebase-admin/app');
const { getDataConnect } = require('firebase-admin/data-connect');
const { parseBranchSave } = require('../lib/branches/savePlan');
const { branchCreation, commitBranchSave } = require('../lib/sql/branchSave');
const { updateMemberWithAssignments } = require('../lib/sql/members');

assert.ok(process.env.DATA_CONNECT_EMULATOR_HOST, 'SQL emulator is required');
initializeApp({ projectId: 'demo-workaxis' });
const sql = getDataConnect({ location: 'asia-south1', serviceId: 'workaxis-service', connector: 'workaxis-connector' });
const actor = { uid: 'admin', role: 'orgAdmin', organizationId: 'o1', branchIds: [] };
const draft = { id: 'b1', name: 'Renamed', code: 'B1', location: 'City', status: 'active',
  isMainBranch: false, geofenceRadiusMeters: 100, latitude: null, longitude: null, managerIds: [] };
const claims = (role) => ({ impersonate: { authClaims: {
  sub: role, role, status: 'active', organizationId: 'o1', branchIds: ['b1'],
} } });

beforeEach(async () => {
  await sql.executeGraphql(`mutation Reset @transaction {
    organizationMember_deleteMany(where: { organization: { id: { eq: "o1" } } })
    organization_delete(id: "o1")
  }`);
  await sql.executeGraphql(`mutation Seed @transaction {
    organization_insert(data: { id: "o1", name: "Org", code: "ORG", status: "active" })
    a: branch_insert(data: { id: "b1", organizationId: "o1", name: "Original", code: "B1", latitude: 12, longitude: 77 })
    b: branch_insert(data: { id: "b2", organizationId: "o1", name: "Other", code: "B2" })
    m: organizationMember_insert(data: { id: "manager", authUid: "mgr", organizationId: "o1", fullName: "Manager", username: "manager", email: "manager@example.com", role: "branchManager", status: "active" })
    e: organizationMember_insert(data: { id: "employee", authUid: "emp", organizationId: "o1", fullName: "Employee", username: "employee", email: "employee@example.com", role: "employee", status: "active" })
    s: organizationMember_insert(data: { id: "suspended", authUid: "sus", organizationId: "o1", fullName: "Suspended", username: "suspended", email: "suspended@example.com", role: "employee", status: "suspended" })
    userBranchAssignment_insertMany(data: [
      { memberId: "manager", branchId: "b1" }, { memberId: "employee", branchId: "b1" }, { memberId: "suspended", branchId: "b1" }
    ])
  }`);
});

test('last-branch validation rolls back branch fields and every assignment', async () => {
  const plan = parseBranchSave(actor, draft);
  await assert.rejects(commitBranchSave(plan, ['manager']));
  const { data } = await sql.executeGraphqlRead(`query { branch(id: "b1") { name latitude longitude } userBranchAssignments { member { id } branch { id } } }`);
  assert.equal(data.branch.name, 'Original');
  assert.equal(data.branch.latitude, 12);
  assert.equal(data.userBranchAssignments.length, 3);
});

test('branch fields, cleared coordinates and manager removal commit together', async () => {
  await sql.executeGraphql(`mutation { userBranchAssignment_insert(data: { memberId: "manager", branchId: "b2" }) }`);
  await commitBranchSave(parseBranchSave(actor, draft), ['manager']);
  const { data } = await sql.executeGraphqlRead(`query { branch(id: "b1") { name latitude longitude } userBranchAssignments(where: { member: { id: { eq: "manager" } } }) { branch { id } } }`);
  assert.equal(data.branch.name, 'Renamed');
  assert.equal(data.branch.latitude, null);
  assert.equal(data.branch.longitude, null);
  assert.deepEqual(data.userBranchAssignments.map((a) => a.branch.id), ['b2']);
});

test('organization branch listing denies branch managers and employees', async () => {
  for (const role of ['branchManager', 'employee']) {
    await assert.rejects(sql.executeQuery('ListBranchesByOrg', { orgId: 'o1' }, claims(role)));
  }
  const { data } = await sql.executeQuery('ListBranchesByOrg', { orgId: 'o1' }, claims('orgAdmin'));
  assert.equal(data.branches.length, 2);
});

test('direct branch mutations cannot bypass trusted orchestration', async () => {
  for (const role of ['orgAdmin', 'platformOwner']) {
    await assert.rejects(sql.executeMutation('UpdateBranch', { id: 'b1', status: 'suspended' }, claims(role)));
    await assert.rejects(sql.executeMutation('AddBranch', { orgId: 'o1', name: 'Bypass', code: 'B3' }, claims(role)));
  }
});

test('dashboard headcount counts active employees only', async () => {
  const { data } = await sql.executeQuery('GetBranchStats', { branchId: 'b1' }, claims('orgAdmin'));
  assert.equal(data.memberCount.reduce((sum, row) => sum + row._count, 0), 1);
});

test('account SQL failure rolls back fields and assignments together', async () => {
  await assert.rejects(updateMemberWithAssignments('employee', { email: 'manager@example.com' }, []));
  const { data } = await sql.executeGraphqlRead(`query { organizationMember(id: "employee") { email userBranchAssignments_on_member { branch { id } } } }`);
  assert.equal(data.organizationMember.email, 'employee@example.com');
  assert.equal(data.organizationMember.userBranchAssignments_on_member[0].branch.id, 'b1');
});

test('branch creation stores stable retry identity and payload fingerprint', async () => {
  const input = { ...draft, id: undefined, requestId: 'create-1', code: 'NEW', managerIds: ['manager'] };
  const plan = parseBranchSave(actor, input);
  const retry = parseBranchSave(actor, input);
  assert.equal(plan.data.id, retry.data.id);
  await commitBranchSave(plan, []);
  const replay = await branchCreation(retry.data.id);
  assert.equal(replay.creationFingerprint, retry.creationFingerprint);
  assert.notEqual(parseBranchSave(actor, { ...input, name: 'Changed' }).creationFingerprint, replay.creationFingerprint);
});
