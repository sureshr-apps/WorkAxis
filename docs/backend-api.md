# WorkAxis Backend API

Server-side contract for the Flutter client. Region everywhere: `asia-south1`.
Status of this document: describes the code in `functions/`, `functions/db/`
and `firestore.rules` as written. Relational data lives in plain PostgreSQL and
is reached only from Cloud Functions (the app calls the single `dataOp`
callable); Firebase Data Connect is no longer used. Firestore rules and pure
function logic are unit-tested, and SQL-facing code is tested against an
in-memory `FakeDb`. The deployment checklist (section 5) targets the separate
Firebase project `workaxis-app`.

## 1. Identity model

| Concern | Authority | Projection |
|---|---|---|
| Membership, role, status, branch assignments | SQL `OrganizationMember` / `UserBranchAssignment` | - |
| Sign-in credential | Firebase Auth | - |
| Authorization claims | SQL | Auth custom claims (written only by functions) |
| Profile for client reads | SQL | Firestore `users/{uid}` (written only by functions) |
| Login alias lookup | SQL (username/email/phone) | Firestore `user_aliases/*` (written only by functions) |

`OrganizationMember.authUid` is the Firebase uid (unique). It is nullable only
so seed rows can exist before an Auth identity does. Platform roles have
`organization = null`.

### Custom claims

```json
{ "role": "orgAdmin", "organizationId": "org-1", "branchIds": ["b1","b2"], "status": "active" }
```

- `role`: `platformOwner | platformAdmin | orgAdmin | branchManager | employee`
- `organizationId`: absent for platform roles
- `branchIds`: active assigned branches (empty for org-wide roles)
- `status`: `active | suspended`. Effective status is `suspended` if the member
  or its organization is suspended, or its organization has no usable license
  (see License enforcement). Every `dataOp` operation and Firestore
  rule requires `status == 'active'`.

Claims change only through functions. After a role/branch/status change the
function revokes refresh tokens, so the client must call
`getIdToken(true)` / re-authenticate when it sees `permission-denied` or
`unauthenticated`. Functions never trust claims: they re-read the caller from
SQL (`resolveActor`), so a stale token cannot act after suspension.

### Alias normalization (`user_aliases/{key}` = `{ userId, email }`)

- username: trim + lowercase; 3-50 of `[a-z0-9._-]`, must contain a letter.
- email: trim + lowercase.
- phone: `+` followed by 7-15 digits (spaces, dashes, brackets stripped).
  Country code required; `9876543210` is rejected.
- No username can contain `@` or look like a phone, so keys never collide
  across kinds.
- If no email is supplied, the account's login email (Auth + SQL `email`) is
  the synthetic `<username>@login.workaxis.invalid`. The UI should not display
  addresses ending in `.invalid`.

## 2. Callable functions

All are `onCall` v2 in `asia-south1`. Set `ENFORCE_APP_CHECK=true` in the
functions environment (`functions/.env.<project>`) to require App Check on
every callable (default `false` so development works without it; enable it
before production once App Check is registered in the app).
Errors are `HttpsError` codes; internal details are never returned:
`unauthenticated`, `permission-denied`, `invalid-argument`, `not-found`,
`already-exists`, `failed-precondition`, `aborted`, `resource-exhausted`,
`internal`.

| Callable | Request | Response | Who |
|---|---|---|---|
| `provisionUser` | `{requestId, fullName, username, email?, phone?, password, role, organizationId?, branchIds?}` | `{uid, memberId, username, loginEmail}` | see matrix |
| `updateUserAccount` | `{targetUid, fullName?, email?, phone? (null clears), role?, branchIds?}` | `{uid}` | see matrix |
| `resetUserPassword` | `{targetUid, newPassword}` | `{uid}` | see matrix |
| `setUserStatus` | `{targetUid, status: 'active'\|'suspended'}` | `{uid, status}` | see matrix; refuses to suspend an organization's only active administrator |
| `deletePlatformAdministrator` | `{targetUid}` | `{uid, deleted}` | Platform Owner only; not self; platform administrators only |
| `deleteOrganizationAdmin` | `{targetUid}` | `{uid, deleted}` | Platform staff or an Organization Admin deleting a peer in the same organization; refused for self or the organization's only active administrator |
| `deleteOrganizationMember` | `{targetUid}` | `{uid, deleted}` | Employees and branch managers; by their organization admin or branch manager; refused while the account has returns, leave, or attendance |
| `setOrganizationStatus` | `{organizationId, status}` | `{organizationId, status, membersUpdated, membersFailed}` | platform roles |
| `resolveLoginIdentifier` | `{identifier}` | `{email}` | unauthenticated |
| `recordAttendancePunch` | `{kind: 'checkIn'\|'checkOut'\|'breakStart'\|'breakEnd', branchId, latitude, longitude, accuracyMeters}` | `{entryId, kind, recordedAt, workDate, distanceMeters}` | Employee |
| `createKioskPairingToken` | `{branchId}` | `{token, expiresAt, branchId}` | Org Admin of the org, Branch Manager of the branch |

#### Optional employee profile fields: omit vs null

`updateUserAccount` treats the optional profile fields (`aadhaarNumber`, `aadhaarPhotoUrl`, `dateOfBirth`, `gender`, `address`, `profilePhotoUrl`, `designation`, `joiningDate`, `relievingDate`, `salary`, `assetDetails`) as a patch:

- key **omitted** (or an empty string): unchanged;
- explicit **`null`**: clear the stored value (`FieldValue.delete()`; `salary`, `aadhaarNumber` and `aadhaarPhotoUrl` are removed from `employee_private/{uid}`, the rest from `users/{uid}`);
- a value: set it (validated as before).

`dailyWorkHours`, `shiftHours` and `employeeCode` can never be cleared (`null` is rejected with `invalid-argument`). Clearing an employment-control field counts as editing it, so `assertNoSelfEmploymentEdit` denies it on one's own account. The client sends `null` only for a field the user emptied whose stored value was known and non-empty; private values outside a Branch Manager's active branch scope remain unknown and are never cleared. `provisionUser` ignores `null`. It also rejects creating an `employee` without `aadhaarNumber`, `aadhaarPhotoUrl`, `designation`, `salary`, `dailyWorkHours` and `shiftHours` (same rule as `OrganizationMemberPolicy.requiredFields`).

Authorization matrix (`functions/src/auth/authorization.ts`, unit-tested):

- Create: Platform Owner -> platformAdmin, orgAdmin (any org). Platform
  Admin -> orgAdmin (any org). Org Admin -> orgAdmin/branchManager/employee in
  own org. Branch Manager -> employee only for branches inside own
  `branchIds`. Nobody creates `platformOwner`. Employees create nobody.
- Manage (update / reset password / set status): Platform Owner -> platform
  admins and org admins. Platform Admin -> org admins. Org Admin -> any
  customer user in own org. Branch Manager -> employees sharing one of their
  branches; may only grant branches within own scope and never change roles.
  Nobody manages the Platform Owner. No self role/branch/status changes.
- Branch and org targets are validated against SQL: branches must belong to
  the organization and be active; the organization must be active.
- Passwords: 8-128 chars. Set as given; no forced change.

Details:

- `resolveLoginIdentifier`: unknown identifiers return `unauthenticated`
  "Invalid username or password." (same text the client shows for a wrong
  password). Rate limited to 30 lookups per IP per 15 minutes
  (`resource-exhausted`). Because a successful lookup returns the email, this
  is not enumeration-proof on its own; App Check plus rate limiting are the
  mitigations.
- `recordAttendancePunch`: server stamps time and the `workDate`
  (`YYYY-MM-DD`) in `Asia/Kolkata` (`BUSINESS_TIMEZONE` in `config.ts`).
  Geofence uses the branch coordinates/radius from SQL, requires GPS accuracy
  <= 100 m (`MAX_GPS_ACCURACY_METERS`), and rejects branches with no (or 0,0)
  coordinates. Writes `attendance_entries/{uid}_{workDate}` (one per employee
  per day) and enforces the check-in/break/check-out state machine.
  Entries gain `breaks: [{startAt, endAt?}]`. Status is always `present`
  (no shift schedule exists in the data model yet).
- `createKioskPairingToken`: 256-bit random token, 10-minute expiry, only the
  SHA-256 is stored in `kiosk_pairing_tokens/{hash}`. Redemption by the kiosk
  device is not implemented yet.
- `setOrganizationStatus` replaces status changes through `UpdateOrganization`
  (which now rejects `status`), because suspension must also push
  `status: suspended` claims, disable sign-in and revoke sessions for every
  member.

### provisionUser: consistency and idempotency

Auth, SQL and Firestore cannot be updated atomically. Strategy:

1. Authorize (SQL-resolved actor + matrix) and validate scope. No writes yet.
2. Claim the ledger entry `provision_requests/{callerUid}_{requestId}` in a
   transaction. `done` returns the stored result (idempotent replay). A fresh
   `pending` entry returns `aborted`. `failed` or a stale `pending` (>120 s)
   is retried reusing the pre-generated `uid`.
3. Reserve alias docs in a Firestore transaction (create-only; a key owned by
   another uid raises `already-exists`). This is the uniqueness gate.
4. Insert SQL member + assignments in one SQL transaction with
   `authUid = uid` (SQL unique constraints on username, email, phone are the
   second gate).
5. Create the Auth user with the pre-generated uid (or update it on retry).
6. Set custom claims.
7. Write `users/{uid}` and mark the ledger `done`.

Every step is idempotent for the same uid. On any failure the function
compensates best-effort in reverse (delete Auth user, delete SQL member and
assignments, release only aliases owned by that uid), marks the ledger
`failed`, and rethrows. If compensation itself fails it is logged and the
ledger stays `failed`; a retry with the same `requestId` resumes cleanly
because steps 3-7 are upserts. Clients must generate one `requestId`
(8-100 chars, e.g. a UUID) per user-initiated create and reuse it on retry.

### Bootstrapping the first Platform Owner

No function can create a `platformOwner`. Once, using the Admin SDK or the
console with a trusted credential: create the Auth user; insert the SQL
member (`role: "platformOwner"`, no organization, `authUid` = uid) directly
in SQL; set claims `{role: "platformOwner", branchIds: [], status:
"active"}`; write `users/{uid}` and aliases `user_aliases/{username}` =
`{userId, email}`. Seed members (`functions/db/seed/seed_data.sql`) have
`auth_uid = NULL` and cannot call any function until linked.

## 3. dataOp operations

One callable, `dataOp` (region `asia-south1`): request `{ op, vars }`, response
`{ data }`. Implementations: `functions/src/data/ops/*.ts`, registered in
`functions/src/data/registry.ts`. The caller is resolved from SQL on every call
(role, organization, active branches, status) and each operation authorizes
itself. Unset optional variables must be omitted (not sent as null). Identity
writes (members, assignments, role, status) and branch saves have no `dataOp`
operation: use the callables. Name filters are case-insensitive (`ILIKE`).
Platform = platformOwner or platformAdmin; Org Admin = own organization only;
Branch Manager (BM) = assigned branches only. Paged operations take
`limit`/`offset` and also return `total`.

### Organizations (`ops/organizations.ts`)

| Operation | Who may call | Key vars | Response keys |
| --- | --- | --- | --- |
| `ListOrganizations` | Platform | none | `organizations` |
| `ListOrganizationsPaged` | Platform | `nameContains` (matches name or code), `status`, `limit`, `offset` | `organizations` (each with `branchCount`, `memberCount`), `total` |
| `GetOrganizationById` | Platform; members of that organization | `id` | `organization` (includes `planId`, `planName`) |
| `GetOrganizationStats` | Platform; Org Admin | `orgId` | `branchCount`, `memberCount` |
| `GetPlatformStats` | Platform | none | `organizationsByStatus`, `platformAdminCount` |
| `CreateOrganization` | Platform | `name`, `code`, optional profile fields, `status`, `id` | `organization_insert` |
| `UpdateOrganization` | Platform (status cannot be changed; use `setOrganizationStatus`) | `id`, profile fields | `organization_update` |

### Branches (`ops/branches.ts`)

| Operation | Who may call | Key vars | Response keys |
| --- | --- | --- | --- |
| `ListBranchesByOrg` | Platform; Org Admin | `orgId` | `branches` |
| `GetBranchById` | Platform; Org Admin of its org; BM/Employee assigned to it | `id` | `branch` |
| `ListMyBranchAssignments` | Any signed-in member (own active branches) | none | `userBranchAssignments` |

### Members (`ops/members.ts`)

| Operation | Who may call | Key vars | Response keys |
| --- | --- | --- | --- |
| `GetMyMember` | Any signed-in member (own record) | none | `organizationMembers` |
| `ListMembersByOrg` | Platform; Org Admin | `orgId` | `organizationMembers` |
| `ListMembersByOrgPaged` | Platform; Org Admin | `orgId`, `nameContains`, `status`, `role` | `organizationMembers`, `total` |
| `ListMembersByBranchPaged` | Org Admin of its org; BM assigned (platform excluded) | `branchId`, `nameContains`, `status` | `userBranchAssignments`, `total` |
| `GetMemberById` | Self; Platform; Org Admin of its org; BM sharing a branch | `id` | `organizationMember` |
| `ListPlatformMembersPaged` | Platform | `nameContains`, `status` | `organizationMembers`, `total` |

### Returns (`ops/returns.ts`)

| Operation | Who may call | Key vars | Response keys |
| --- | --- | --- | --- |
| `ListReturnsByBranch` | Org Admin of its org; BM assigned (latest 200) | `branchId` | `returnRecords` |
| `ListReturnsByBranchPaged` | Org Admin; BM assigned | `branchId`, `status` | `returnRecords`, `total` |
| `ListReturnsByOrgPaged` | Platform; Org Admin | `orgId`, `branchId`, `status` | `returnRecords`, `total` |
| `ListMyReturns` | Any signed-in member (own submissions) | `status` | `returnRecords`, `total` |
| `SubmitReturn` | Employee, BM (own active branch) | `branchId`, `productTitle`, `quantity`, `unit`, `invoiceNumber`, `returnReason`, `billImageUrl`, `remarks` | `returnRecord_insert` |
| `CreateReturnRecord` | Employee, BM (legacy; client-supplied id) | `id`, `orgId`, `branchId`, `employeeId`, `customerName`, `amount`, `invoiceNumber`, `returnReason` | `returnRecord_insert` |
| `UpdateReturnRecordReview` | Org Admin of its org; another BM assigned to the branch (pending only) | `id`, `status` (approved/rejected), `reviewerNotes` | `returnRecord_update` |
| `UpdateReturnRecordStatus` | Same as review (legacy, no notes) | `id`, `status` | `returnRecord_update` |

Submitter and reviewer identity, organization and timestamps are stamped server-side.
Branch Managers cannot review returns they submitted themselves; an Organization Admin or another Branch Manager assigned to that branch must review them.

### Leaves (`ops/leaves.ts`)

Apply `functions/db/migrations/005_leave_requests.sql` before deploying the leave
screen and operations. PostgreSQL is authoritative for leave requests.

| Operation | Who may call | Key vars | Response keys |
| --- | --- | --- | --- |
| `ListMyLeaveRequests` | Employee or Branch Manager | `limit`, `offset`, optional `status` | `leaveRequests`, `total` |
| `ListOrganizationLeaveRequestsPaged` | Organization Admin of its organization | `limit`, `offset`, optional `branchId`, `status` | `leaveRequests`, `total` |
| `ListEmployeeLeaveRequestsByBranchPaged` | Branch Manager assigned to the active branch | `branchId`, `limit`, `offset`, optional `status` | `leaveRequests`, `total` |
| `SubmitLeaveRequest` | Employee or Branch Manager for an active assigned branch | `branchId`, `leaveType`, `startDate`, `endDate`, `reason`; Branch Manager also sends `activeBranchId` | `leaveRequest` |
| `UpdateMyPendingLeaveRequest` | Applicant, while request is pending | `id`, `leaveType`, `startDate`, `endDate`, `reason`; Branch Manager also sends `activeBranchId` | `leaveRequest` |
| `ReviewLeaveRequest` | Organization Admin in its organization; Branch Manager for an employee in the active assigned branch | `id`, `status` (`approved`/`rejected`), optional `reviewerNotes`; Branch Manager also sends `activeBranchId` | `leaveRequest` |

The server derives applicant/reviewer identity and organization. Branch Managers
cannot review a Branch Manager's request; only an Organization Admin can.
Applicants can edit only pending requests. The SQL trigger prevents any update
to an approved request, including changes to its review details.

### Dashboards (`ops/dashboards.ts`)

| Operation | Who may call | Key vars | Response keys |
| --- | --- | --- | --- |
| `GetOrganizationDashboardCounts` | Platform; Org Admin | `orgId` | `branchesByStatus`, `membersByRole`, `returnsByStatus` |
| `GetReturnCountsByBranch` | Platform; Org Admin | `orgId`, optional `from`, `to` | `returnRecords`, `returnsByReason` |
| `GetBranchStats` | Org Admin of its org; BM assigned | `branchId`, optional `from`, `to` | `memberCount`, `returnsByStatus`, `returnsByReason` |

`from` is inclusive and `to` exclusive (business-timezone period).

### License plans (`ops/licensePlans.ts`)

Platform-only catalogue of license plans (`license_plan`, migration
`db/migrations/003_license_plans.sql`). Plans carry no prices and no colours.
Plan codes are generated by the server (`PLN-<12 hex>-<NAME>`, regenerated on
a collision). Levels are unique and plan names are unique regardless of case.
Deactivating a plan is a status change. A plan referenced by any license or
history row cannot be deleted.

| Operation | Who may call | Key vars | Response keys |
| --- | --- | --- | --- |
| `ListLicensePlans` | Platform | optional `status` (`active` or `inactive`), optional `query` (name or plan code contains, case-insensitive) | `licensePlans` (by level: `id, planCode, name, description, level, maxStores, maxUsers, status, assignedOrganizations`), `summary` (`totalPlans, activePlans, inactivePlans, assignedOrganizations`; platform-wide, ignores the filters) |
| `CreateLicensePlan` | Platform | `name` (2 to 60 characters), `level`, `maxStores`, `maxUsers` (integers 1 to 1000000), `status` (`active` or `inactive`), optional `description` (max 200) | `licensePlan_insert` (`{id, planCode}`) |
| `UpdateLicensePlan` | Platform | `id`, `name`, `level`, `maxStores`, `maxUsers`, optional `description` (omit to keep it, empty to clear it) | `licensePlan_update` (`{id}`, or `null` when the plan does not exist) |
| `ChangeLicensePlanStatus` | Platform | `id`, `status` (`active` or `inactive`) | `licensePlan_update` (`{id, status}`, or `null`) |
| `DeleteLicensePlan` | Platform | `id` | `licensePlan_delete` (`{id}`, or `null`); `failed-precondition` with "This plan is referenced by existing licenses or history and cannot be deleted. Deactivate it instead." |

Duplicates are `already-exists` ("A license plan with this level already exists."
or "A license plan with this name already exists."). Validation errors are
`invalid-argument`.

### Organization licenses (`ops/organizationLicenses.ts`)

Each organization has at most one license (`organization_license`): a plan, a
start and expiry date (`YYYY-MM-DD`, expiry after start), a one-time
`negotiatedPrice` and a yearly `maintenancePrice` (INR, 0 to 1e12). Platform
only. Every change writes one `license_history` row holding the dates and prices
in force at that time. The status is derived on the server from the
Asia/Kolkata calendar day: `not_assigned`, `not_yet_active`, `active`,
`expiring_soon` (expiry within 30 days, inclusive) or `expired`.

| Operation | Who may call | Key vars | Response keys |
| --- | --- | --- | --- |
| `GetOrganizationLicense` | Platform | `organizationId` | `organizationLicense` (`null` when none; otherwise `id, organizationId, planId, startDate, expiryDate, negotiatedPrice, maintenancePrice, status, plan`) |
| `GetOrganizationLicenseHistory` | Platform | `organizationId` | `licenseHistory`, newest first (`id, eventType, eventAt, planId, planCode, planName, planLevel, maxStores, maxUsers, startDate, expiryDate, negotiatedPrice, maintenancePrice`; plan fields come from the live plan row) |
| `AssignOrganizationLicense` | Platform | `organizationId`, `planId`, `startDate`, `expiryDate`, `negotiatedPrice`, `maintenancePrice` | `organizationLicense_insert` (`{id}`). Writes `assigned`. Refused: `already-exists` "This organization already has a license."; `failed-precondition` "Select an active license plan." |
| `ChangeOrganizationLicensePlan` | Platform | `organizationId`, `targetPlanId`, `negotiatedPrice`, `maintenancePrice` | `organizationLicense_update` (`{id}`). Dates are unchanged. Writes `plan_changed`. The target must be active with a level strictly above the current plan, otherwise `failed-precondition` "Only a higher-level active plan can be selected." |
| `ModifyOrganizationCommercialTerms` | Platform | `organizationId`, `negotiatedPrice`, `maintenancePrice` | `organizationLicense_update` (`{id}`). Unchanged prices write nothing. Otherwise writes `commercial_terms_modified`. |
| `RenewOrganizationLicense` | Platform | `organizationId`, `planId`, `newStartDate`, `newExpiryDate`, `negotiatedPrice`, `maintenancePrice` | `organizationLicense_update` (`{id}`). The new start must be after the current expiry and the new expiry after the new start (`invalid-argument`). The plan must be active. If the current term is usable today and the new start is the day after its expiry, the current start is kept and only the expiry moves; otherwise the new start is stored. Writes `renewed`. |

Changing, modifying or renewing an organization without a license is
`failed-precondition` "This organization does not have a license."

### License enforcement

- A license is **usable** when its plan is `active` and today (Asia/Kolkata, read
  in SQL) falls within `startDate..expiryDate` inclusive. An expiring-soon license
  remains usable.
- **Sign-in and data access.** `resolveActor` (used by `dataOp` and every
  callable) denies a non-platform member whose organization has no usable
  license, exactly as for a suspended organization. `effectiveStatus` reports the
  same member as `suspended`, so claims, the Auth disabled flag and the
  `users/{uid}` projection agree. Platform roles are not affected.
- **Stores.** `saveBranch` refuses to create a store, or to make a suspended store
  active, when the organization has no usable license or its active store count
  already equals `maxStores`. Editing a store that stays active, or suspending
  one, is not checked.
- **Members.** Every path that adds an active member or sets one active refuses
  when there is no usable license or the active member count already equals
  `maxUsers`. This covers `provisionUser`, `setUserStatus` and any member update
  that sets `active`. Platform roles are never counted. The count covers every
  active organization member: Org Admins, Branch Managers and Employees.
- **Concurrency.** Each check runs inside the write transaction, after
  `SELECT ... FOR UPDATE` on the organization's `organization_license` row, so
  concurrent creations and activations cannot exceed the limit.
- **Messages** (`failed-precondition`):
  - "This organization does not have an active license plan. Assign an active license before adding or activating users."
  - "This organization has reached its plan limit of N active users. Deactivate an existing administrator or employee before adding or activating another user."
  - "This organization does not have an active license plan. Assign an active license before adding or activating stores."
  - "This organization has reached its plan limit of N active stores. Deactivate an existing store before adding or activating another store."

## 4. Firestore rules summary

- `user_aliases`: no client access (`get, list, write: false`).
- `users/{uid}`: read own profile; platform roles read all; Org Admin reads
  own org; Branch Manager reads employees sharing a branch. No client writes.
  Never holds salary or Aadhaar data (see `employee_private`).
- `employee_private/{uid}` = `{ organizationId, salary?, aadhaarNumber?,
  aadhaarPhotoUrl?, updatedAt }`: sensitive HR data written only by trusted
  functions (`writeProfile` / `updateUserAccount`). `get` is allowed to the
  active Org Admin of that organization, the employee themself, and a Branch
  Manager when the employee's `users/{uid}` projection shares one of the
  manager's assigned branches in the same organization. Branch Managers see
  details in their active branch scope; platform roles are denied. `list` and
  every client write are denied. Existing `users/{uid}` docs are scrubbed of
  these keys the next time their profile is refreshed (no separate migration
  step).
- Employee IDs: SQL `organization_member.employee_code` is authoritative
  (unique per organization). `provisionUser` allocates `EMP-<n>` from
  `organization.employee_code_seq` in the member-insert transaction when none is
  supplied, and returns `employeeCode`; `users/{uid}.employeeCode` is a
  projection of it. Actors cannot change their own employment details
  (salary, designation, joining/relieving date, employee ID, work hours, shift,
  assets) through `updateUserAccount`.
- `attendance_entries`: read by platform roles (read-only), Org Admin (org),
  Branch Manager (`branchIds`), employee (own). Create only by managers for
  group check-ins (`source == 'manager-group'`, `checkInAt` and `createdAt ==
  request.time`, workDate within the last 7 days); employees never write.
  Review updates touch only `reviewStatus, reviewedBy, reviewedById,
  reviewedAt` with `reviewedAt == request.time` and `reviewedById == uid`.
- `group_attendance_batches`: managers in scope create with `createdAt ==
  request.time`; immutable.
- `organization_settings/{orgId}`: `get` by Org Admin of that org and platform
  roles; create/update only by the Org Admin of that org. Field whitelist
  (`organizationId == orgId`, `geofenceRadiusMeters` int 10-5000,
  `gracePeriodMinutes` int 0-120, booleans `allowBreaks`/`requireGeolocation`/
  `dailyDigest`/`returnAlerts`, optional `operationsEmail`/`emergencyPhone`
  strings), `updatedBy == request.auth.uid`, `updatedAt == request.time`. No
  list, no delete.
- `platform_settings/global`: `get` by platform roles; write only by
  `platformOwner` (`sessionTimeoutMinutes` int 5-1440, `maxLoginAttempts` int
  3-10, booleans `maintenanceMode`/`enforceStrongPasswords`, same audit
  checks). Any other document id is denied.
- `attendance_punches` is removed (default deny), as are
  `provision_requests`, `auth_rate_limits`, `kiosk_pairing_tokens`.
- Every helper requires `request.auth.token.status == 'active'`.
- Tests: `functions/test-rules/` (21 tests).
- Indexes (`firestore.indexes.json`): all current attendance queries are
  equality-only on `organizationId`, `workDateString`, `branchId`,
  `employeeId`, `status` (managers/dashboards/`AttendanceDayCounter`, duplicate
  check, employee home). Composite indexes cover org+day+branch, org+day+
  employee, org+day+status (late count), org+day+branch+status and
  org+day+branch+employee. `group_attendance_batches` is write-only from the
  client (no queries), so it needs none.

### Reports and returns notes

- The per-reason breakdown is a plain `GROUP BY return_reason` aggregate
  (`returnsByReason`). The
  client maps stored reasons to categories (unknown legacy values count as
  "Other") and the period to `[from, to)` in the business timezone
  (Asia/Kolkata), so `returnCountsCoverPeriod` is true.
- Employee check-in location: the client obtains the GPS fix via
  `geolocator` (Android/iOS/web) and sends `latitude, longitude,
  accuracyMeters` to `recordAttendancePunch`; the server validates the
  geofence. Web requires HTTPS or localhost for geolocation.

## 5. Deployment steps

Topology: Firebase project `workaxis-app` (Auth, Firestore, Storage bucket
`workaxis-app-attachments`, Hosting site `workaxis-app`, Cloud Functions in
`asia-south1`, codebase `workaxis`) is separate from OmniRetail. Functions run
as `workaxis-sql@workaxis-app.iam.gserviceaccount.com` and reach the shared
Cloud SQL instance `omniretail-60c71:asia-south1:omniretail-sql` (PostgreSQL 18,
database `workaxis`) in the `omniretail-60c71` project. Per-project settings
are in `functions/.env.workaxis-app` (`DB_MODE`, `DB_NAME`, `DB_USER`,
`DB_INSTANCE_CONNECTION_NAME`, `RUNTIME_SERVICE_ACCOUNT`, `MAX_INSTANCES`).

1. `firebase use workaxis-app`. Enable Cloud Functions, Cloud Build, Artifact
   Registry, Cloud Run, Eventarc, Identity Platform / Auth, Firestore, Cloud
   Storage and App Check in `workaxis-app`, and the Cloud SQL Admin API in
   `omniretail-60c71` (the connector calls it).
2. Service account and cross-project grants:
   ```powershell
   gcloud iam service-accounts create workaxis-sql --project workaxis-app
   gcloud projects add-iam-policy-binding omniretail-60c71 `
     --member "serviceAccount:workaxis-sql@workaxis-app.iam.gserviceaccount.com" `
     --role roles/cloudsql.client
   gcloud projects add-iam-policy-binding omniretail-60c71 `
     --member "serviceAccount:workaxis-sql@workaxis-app.iam.gserviceaccount.com" `
     --role roles/cloudsql.instanceUser
   gcloud sql users create "workaxis-sql@workaxis-app.iam" `
     --instance omniretail-sql --project omniretail-60c71 `
     --type=cloud_iam_service_account
   ```
3. Schema and database grants. Run `functions/db/migrate.mjs` as an owner
   (see `functions/db/README.md`), then as the table owner:
   ```sql
   GRANT CONNECT ON DATABASE workaxis TO "workaxis-sql@workaxis-app.iam";
   GRANT USAGE ON SCHEMA public TO "workaxis-sql@workaxis-app.iam";
   GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public
     TO "workaxis-sql@workaxis-app.iam";
   ALTER DEFAULT PRIVILEGES IN SCHEMA public
     GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "workaxis-sql@workaxis-app.iam";
   ```
   Migration `003_license_plans.sql` drops `commercial_agreement` and
   `license_event` only when both are empty, and stops otherwise. After it runs,
   every customer organization needs a license (`AssignOrganizationLicense`), or
   its members cannot sign in (see License enforcement).
4. Functions: `cd functions && npm ci && npm test`. Set `ENFORCE_APP_CHECK` as
   desired. Build the web app first: `flutter build web --release
   --dart-define=BACKEND_MODE=firebase`.
5. `firebase deploy --only firestore,storage,functions,hosting`. Deploy
   `firestore` (rules and indexes) together with functions so clients are never
   without the callables the rules assume; index builds can take minutes.
6. Bootstrap the Platform Owner (section 2), link seed members to Auth uids or
   re-create them through `provisionUser`. Sample data, if wanted, is
   `functions/db/seed/seed_data.sql`.

The instance is a shared `db-f1-micro`, so keep `DB_POOL_MAX` at 3 and
`MAX_INSTANCES` at 5. To run on a self-hosted PostgreSQL instead, see
`docs/architecture.md` section 21c.

## 6. Required Dart-layer changes

- Sign-in: call `resolveLoginIdentifier`, then Firebase Auth with the returned
  email; map any failure to "Invalid username or password."
- Member/platform-user create, edit, reset password, suspend: call the
  callables; stop writing `users`/`user_aliases` or members directly.
- Organization status: call `setOrganizationStatus`, not `UpdateOrganization`.
- Employee check-in/out/breaks: `recordAttendancePunch`; stop writing
  `attendance_entries`/`attendance_punches` from the client.
- Operations whose auth now needs claims (all of them) will fail with
  `permission-denied` for users without provisioned claims. Branch Managers
  must use `ListMembersByBranchPaged` (not `ListMembersByOrg`); Employees must
  use `ListMyReturns`; `CreateOrganizationMember` is gone for clients;
  review/submit operations no longer accept reviewer/submitter identity.

## Trusted group attendance and branch saves

`recordGroupAttendance` accepts `{ requestId, branchId, workDate: "YYYY-MM-DD", checkInAt: ISO-with-timezone, employeeIds, status: "present"|"late", shiftName, note? }` and returns `{ entryIds }`. Only an active Org Admin of the branch organization or its assigned Branch Manager may call it. Every attendee is resolved from SQL and must be an active employee assigned to that branch. The canonical UID/date records and batch fingerprint commit together; replaying an identical request is safe. Client attendance/audit creates are denied.

`saveBranch` accepts branch fields plus `managerIds`; creates also require a stable `requestId`. The authenticated Org Admin's organization is derived server-side. Coordinates may both be null to clear them. Branch fields and manager assignments commit in a SQL transaction with precondition checks; generated creation keys/fingerprints make lost-response retries safe. Response: `{ id, code, projectionPending }`. Direct Add/Create/UpdateBranch mutations are closed to clients. A pending projection is retried by the identity reconciliation worker.

`updateUserAccount` accepts `email: null` to clear a real email alias, matching phone clearing. SQL member/assignment edits are atomic; Auth/alias compensation and durable identity jobs handle cross-store failures. Identity jobs and leases are server-only, contain no passwords, and serialize edits/retries for each UID. `reconcileIdentitySync` runs every minute with delayed first attempt and retry backoff.

## Employee assets

Apply `functions/db/migrations/004_employee_assets.sql` and
`functions/db/migrations/006_asset_acknowledgement.sql` and
`functions/db/migrations/007_asset_assignment_details.sql` before deploying
the asset screen and data operations. Assets are stored in PostgreSQL and
linked to one organization, branch, and employee membership. Asset tags are
unique within an organization.

- `ListMyEmployeeAssets` resolves the signed-in Employee's membership from the
  authenticated UID and returns only that employee's assets.
- `ListOrganizationEmployeeAssets` is limited to the signed-in Organization
  Admin's organization.
- `ListBranchEmployeeAssets` requires a Branch Manager's assigned active branch
  and returns assets for employees currently assigned to that outlet.
- `SaveEmployeeAsset` and `DeleteEmployeeAsset` allow Organization Admins in
  their organization and Branch Managers only for employees and assets within
  the selected outlet. Employee accounts are read-only.
- The Organization Admin-controlled `requireEmployeeAssetAcknowledgement`
  setting lives in `organization_settings/{orgId}` in Firestore. When it is on,
  `SaveEmployeeAsset` creates a pending receipt acknowledgment. The server
  ignores any acknowledgment fields supplied by a client. The setting is read
  when an asset is first assigned, reassigned to another employee/branch, or
  reissued after being marked returned; existing assignments are not changed
  when the setting is toggled.
- `AcknowledgeMyEmployeeAsset` accepts `{ assetId }` from the assigned Employee
  only and returns `{ employeeAsset }`. The server derives the employee from the
  authenticated UID, stamps the acknowledgment time, UID, and employee name in
  PostgreSQL, and makes repeat acknowledgments idempotent. Employees cannot
  acknowledge an asset assigned to another user, and managers cannot
  acknowledge on an employee's behalf.
- Assignment writes snapshot the manager's UID and name plus the server
  assignment time. Reassigning or reissuing an asset refreshes this snapshot;
  ordinary metadata edits preserve it. Asset responses also include the
  acknowledgment UID, employee name, and time, along with the asset's existing
  serial number and notes. Older assignments have no reliable assignment audit
  data, so their assigner and time remain null. Existing acknowledgment names
  are backfilled only when the recorded UID matches the current employee.

Run the SQL-facing tests locally (they use an in-memory `FakeDb`, no database
or emulator needed) from the repository root:

```powershell
npm --prefix functions test
```
