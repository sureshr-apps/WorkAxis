# WorkAxis Backend API

Server-side contract for the Flutter client. Region everywhere: `asia-south1`.
Status of this document: describes the code in `dataconnect/`, `functions/`
and `firestore.rules` as written. Nothing here has been deployed; SQL Connect
operations were compiled (`firebase dataconnect:compile`, which also validates
every CEL expression) and Firestore rules and pure function logic are
unit-tested. Callables and SQL Connect `@auth` expressions have not been
exercised against a live project.

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
  or its organization is suspended. Every SQL Connect operation and Firestore
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
| `setUserStatus` | `{targetUid, status: 'active'\|'suspended'}` | `{uid, status}` | see matrix |
| `setOrganizationStatus` | `{organizationId, status}` | `{organizationId, status, membersUpdated, membersFailed}` | platform roles |
| `resolveLoginIdentifier` | `{identifier}` | `{email}` | unauthenticated |
| `recordAttendancePunch` | `{kind: 'checkIn'\|'checkOut'\|'breakStart'\|'breakEnd', branchId, latitude, longitude, accuracyMeters}` | `{entryId, kind, recordedAt, workDate, distanceMeters}` | Employee |
| `createKioskPairingToken` | `{branchId}` | `{token, expiresAt, branchId}` | Org Admin of the org, Branch Manager of the branch |

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
member (`role: "platformOwner"`, no organization, `authUid` = uid) via
`executeGraphql`; set claims `{role: "platformOwner", branchIds: [], status:
"active"}`; write `users/{uid}` and aliases `user_aliases/{username}` =
`{userId, email}`. Seed members (`dataconnect/seed_data.*`) have
`auth_uid = NULL` and cannot call any function until linked.

## 3. SQL Connect operations

Connector `workaxis-connector`. Claims: `S` = `status == 'active'`,
`P` = role is platformOwner/platformAdmin. Unset optional variables must be
omitted (not sent as null). Identity writes (members, assignments, role,
status) have no client operation: use the callables.

### Queries

| Operation | Variables | Auth |
|---|---|---|
| `ListOrganizations` (unchanged) | - | S and P |
| `ListOrganizationsPaged` (new) | `limit, offset, nameContains?, status?`; also returns `total {_count}` | S and P |
| `GetOrganizationById` (+`taxIdentification`, `description`, `contactName`, `contactEmail`, `contactPhone`, `address`) | `id` | S and (P or own org) |
| `GetOrganizationStats` (new) | `orgId` -> `branchCount`, `memberCount` | S and (P or Org Admin of org) |
| `GetPlatformStats` (new) | - -> `organizationsByStatus`, `platformAdminCount` | S and P |
| `ListBranchesByOrg` (unchanged vars) | `orgId` | S and (P or own org, any customer role) |
| `GetBranchById` (new) | `id` | S; P, Org Admin of owning org, or Branch Manager/Employee with `id in branchIds` |
| `ListMyBranchAssignments` (new) | - -> active assigned branches via `auth.uid` | S |
| `GetMyMember` (new) | - -> caller's member row (incl. `authUid`) + organization `{id,name,code,status}` | S |
| `ListMembersByOrg` (unchanged vars) | `orgId` | S and (P or Org Admin of org). Branch Managers: use `ListMembersByBranchPaged` |
| `ListMembersByOrgPaged` (new) | `orgId, limit, offset, nameContains?, status?, role?`; `total` | S and (P or Org Admin of org) |
| `ListMembersByBranchPaged` (new) | `branchId, limit, offset, nameContains?, status?`; `total` | S; Org Admin of owning org or Branch Manager of branch |
| `GetMemberById` (new; incl. `createdAt`) | `id` | S; self, P, Org Admin of org, or Branch Manager sharing a branch |
| `ListPlatformMembersPaged` (new) | `limit, offset, nameContains?, status?`; `total`; platform administrators only | S and P |
| `ListReturnsByBranch` (limit 200; extra fields) | `branchId` | S; Org Admin of owning org or Branch Manager of branch (employees use `ListMyReturns`) |
| `ListReturnsByBranchPaged` (new) | `branchId, limit, offset, status?`; `total` | same |
| `ListMyReturns` (new) | `limit, offset, status?`; `total` | S; rows where `employeeUid == auth.uid` |
| `GetOrganizationDashboardCounts` (new) | `orgId` -> `branchesByStatus`, `membersByRole`, `returnsByStatus` | S and (P or Org Admin of org) |
| `ListReturnsByOrgPaged` (new) | `orgId, limit, offset, status?, branchId?`; rows as `ListReturnsByBranchPaged` plus `branch { id name }`; `total` | S and (P or Org Admin of orgId). Replaces the per-branch fan-out for Org Admins |
| `GetReturnCountsByBranch` | `orgId, from?, to?` -> grouped `returnRecords (branchId,status,_count)` and `returnsByReason (returnReason,_count)` | same. `from` inclusive, `to` exclusive (`createdAt`); omit both for all time |
| `GetBranchStats` | `branchId, from?, to?` -> `memberCount`, `returnsByStatus`, `returnsByReason` | S; Org Admin / Branch Manager of branch. Same date semantics |
| `GetCommercialAgreementByOrg`, `ListLicenseEventsByOrg` | `orgId` | S and (P or Org Admin of org) |

### Mutations

| Operation | Variables | Auth |
|---|---|---|
| `CreateOrganization` (+`taxIdentification`, `description`, `contactName`, `contactEmail`, `contactPhone`, `address`; `id` is now optional and server-generated, returned as `organization_insert.id`) | unchanged + optional | S and P; status in active/suspended |
| `UpdateOrganization` | `id, name?, category?, country?, currency?, logoUrl?, taxIdentification?, description?, contactName?, contactEmail?, contactPhone?, address?` (`status` accepted in the signature but rejected: use `setOrganizationStatus`) | S and P. Writes `category` as its own column |
| `CreateCommercialAgreement`, `UpdateCommercialAgreement`, `CreateLicenseEvent` (new) | see `mutations.gql` | S and P |
| `CreateBranch` (legacy, client id) / `AddBranch` (new, server uuid) | `orgId, name, code, ...geofence` | S and (P or Org Admin of orgId); radius 10-5000, lat/long ranges |
| `UpdateBranch` (new) | `id, name?, code?, location?, status?, isMainBranch?, geofenceRadiusMeters?, latitude?, longitude?, kioskEnabled?` | S; P or Org Admin of owning org (lookup `@check`) |
| `CreateOrganizationMember` | unchanged | `NO_ACCESS` (use `provisionUser`) |
| `CreateReturnRecord` (legacy) / `SubmitReturn` (new: `branchId, productTitle, returnReason, quantity, unit, invoiceNumber, billImageUrl?, remarks?`) | | S; Employee/Branch Manager with `branchId in branchIds`; org, submitter id/name, `employeeUid` derived from claims and member lookup |
| `UpdateReturnRecordReview` (new: `id, status, reviewerNotes?`) / `UpdateReturnRecordStatus` (legacy, same rules) | status in approved/rejected | S; Org Admin of owning org or Branch Manager of the return's branch; only `pending` returns; reviewer uid/name/`reviewedAt` set server-side |

Schema changes: `Organization.taxIdentification`, `description`, `contactName`, `contactEmail`, `contactPhone`, `address` (all nullable); `OrganizationMember.authUid`
(unique, nullable), `organization` nullable, `phone` unique;
`Branch (organization, code)` unique; `UserBranchAssignment (member, branch)`
unique; `ReturnRecord` gains `employeeUid, productTitle, quantity, unit,
billImageUrl, remarks, reviewerNotes, reviewerUid, reviewerName, reviewedAt`
(legacy `customerName` = product title and `amount` = quantity are still
written). All `id` columns default to `uuidV4()`. Role/status values are not
DB enums; they are validated in operation auth expressions and in functions.

## 4. Firestore rules summary

- `user_aliases`: no client access (`get, list, write: false`).
- `users/{uid}`: read own profile; platform roles read all; Org Admin reads
  own org; Branch Manager reads employees sharing a branch. No client writes.
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

- Data Connect supports grouping on a selected column with `_count`, so the
  per-reason breakdown is a plain `returnsByReason` aggregate field. The
  client maps stored reasons to categories (unknown legacy values count as
  "Other") and the period to `[from, to)` in the business timezone
  (Asia/Kolkata), so `returnCountsCoverPeriod` is true.
- Employee check-in location: the client obtains the GPS fix via
  `geolocator` (Android/iOS/web) and sends `latitude, longitude,
  accuracyMeters` to `recordAttendancePunch`; the server validates the
  geofence. Web requires HTTPS or localhost for geolocation.

## 5. Deployment steps (not executed)

1. `firebase use workaxis-cloud`; enable Cloud Functions, Cloud Build, Artifact
   Registry, Identity Platform / Auth, and App Check APIs.
2. Schema: `firebase dataconnect:sql:diff` then `dataconnect:sql:migrate` (the
   service uses `schemaValidation: COMPATIBLE`; all changes are additive or
   relax NOT NULL). Review the diff for the new unique indexes against any
   existing data first.
3. Functions: `cd functions && npm ci && npm test`. Set
   `ENFORCE_APP_CHECK` as desired. Grant the functions service account Data
   Connect access (e.g. `roles/firebasedataconnect.admin` or a narrower role
   that allows `ExecuteGraphql`).
4. `firebase deploy --only dataconnect,firestore:rules,firestore:indexes,functions`
   (this release adds `ListReturnsByOrgPaged`, the `from`/`to` variables and
   `returnsByReason` on existing aggregates, settings rules, and 3 new
   attendance indexes; index builds can take minutes, deploy them before
   clients that need them. Variables are optional, so older clients keep
   working.)
   (deploy `firestore:rules` together with functions so clients are never
   without the callables the new rules assume).
5. Bootstrap the Platform Owner (section 2), link seed members to Auth uids
   or re-create them through `provisionUser`, then run `tool/seed_database.py`
   (requires `PGUSER`) if sample data is wanted.
6. `firebase dataconnect:sdk:generate` after any connector change.

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
