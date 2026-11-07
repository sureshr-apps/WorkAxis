# WorkAxis Code Review — 2026-11-07

Read-only review of `lib/` (excluding generated `lib/dataconnect_generated`), `test/`, `dataconnect/`, and `firestore.rules` at commit `2235c5f`.

**Baseline:** `flutter analyze` → no issues. `flutter test` → 210/210 pass.
The clean baseline is misleading: most tests exercise mock repositories that enforce rules the production repositories do not (see T1).

Legend: ✅ = re-verified against source by the lead reviewer; others were confirmed by a sub-reviewer reading the file.

---

## Summary (fix in this order)

| # | Sev | Cat | Issue |
|---|-----|-----|-------|
| C1 ✅ | Critical | Security | SQL Connect: every query/mutation is `@auth(level: USER)` with client-supplied `orgId`/`branchId` — no tenant isolation |
| C2 ✅ | Critical | Security | `SqlConnectAccessRepository`: Branch Managers get **all** org branches; `getAssignedBranches` hardcodes `'org-acme'` |
| C3 | Critical | Security | Production dashboards/reports hardcoded to `org-acme`; branch dashboard falls back to another branch |
| C4 ✅ | Critical | Security | Firestore `user_aliases` writable by any Org Admin across tenants; `allow get: if true` enables enumeration |
| C5 ✅ | Critical | Security | Mock auth has universal passwords; mock backend is the default build mode with no release guard |
| C6 ✅ | Critical | Bug | `getOrganizationById` always throws (`QueryResult` cast to `*Data`) → org details + status changes broken |
| C7 ✅ | Critical | Bug | Employee check-in is fake in production (`FirestoreEmployeeHomeRepository` hardcoded, write swallowed, simulator exposed) |
| C8 | Critical | Bug/Security | Account creation never creates a Firebase Auth identity; Firestore writes violate rules schema |
| C9 ✅ | Critical | Security | Password change is a `Future.delayed` that always reports success |
| C10 | Critical | Security | Sign-out leaves previous user's data in app-wide controllers (shared device leak) |
| M1 ✅ | Major | Security | Router branch gate only fires for multi-branch managers |
| M2 ✅ | Major | Security | Demo credentials hardcoded and shown on the production sign-in screen |
| M3 | Major | Security | Suspension enforced only client-side; status parsing fails open |
| M4 | Major | Security | Firestore rules can never authorize a Branch Manager (`assignedBranches` forbidden by `isValidUser`) |
| M5 | Major | Bug | Stale-response races in Access/Branch/Attendance/Members/Reports/Returns controllers |
| M6 | Major | Bug | Sign-out implemented 3× with different ordering; shell version races |
| M7 ✅ | Major | Bug | Branch Manager editing a member silently demotes role & strips branch assignments |
| M8 | Major | Bug | Member/branch "save" is insert-only in SQL repos; mock enforces validation the real repo skips |
| M9 | Major | Security | Return review has no access scope; reviewer name is client-supplied |
| M10 ✅ | Major | Bug | `ReturnsController` mutates a `const []` → successful submit reported as failure |
| M11 | Major | Security | Attendance timestamps from device clock; rules accept any timestamp |
| M12 | Major | Architecture | Identity/role has two sources of truth (Firestore `users` vs SQL `OrganizationMember`) |
| M13 | Major | Bug | Raw exception text shown to users; errors swallowed and replaced with fake numbers |
| M14 | Major | Architecture | `AuthController` never restores/monitors the Firebase session |
| M15 | Major | Architecture | `WorkAxisApp` defaults every repo to a mock → silent mock/prod mixing |
| M16 ✅ | Major | Architecture | Fake saves / hardcoded demo data in production widgets & repos (settings, profile, geofence, reports) |
| M17 | Major | Bug | Action failures never surfaced (attendance, returns, members, platform users) |
| M18 | Major | Bug | Group check-in can double-record `late` entries |
| M19 | Major | Bug | New branch geofence defaults to 0,0 (UI) / Bangalore (repo) |
| M20 | Major | Bug | Edit Organization loses changes on system/browser back; Tax ID not editable |
| M21 | Major | Bug | Search box / controller query drift on list screens; per-keystroke backend search |
| M22 | Major | UI/A11y | `AppButton` loading state invisible; KPI cards overflow under text scaling |
| P1 | Major | Performance | N+1 queries, full-list downloads for counts, no pagination anywhere |
| P2 | Major | Performance | Non-lazy lists (`Column`/`Wrap`/shrinkWrap `ListView`) for employees, attendance, returns, orgs |
| A1 | Major | Architecture | Monolithic, duplicated files (shell 844, license tab 1122, edit org 1038, etc.) |
| T1–T5 | Major | Tests | Tests lock in fake data, pass via network failure, and don't cover the real repos' scoping |
| m1–m8 | Minor | Various | Design-system bypass, tap targets, raw breakpoints, `DateFormat` in build, dead code |

---

## Critical

### C1 ✅ SQL Connect has no tenant isolation
- **Category:** Security
- **Location:** `dataconnect/connector/queries.gql:3,16,30,45,57,71,87`; `dataconnect/connector/mutations.gql:11,29,52,76,99,116`
- **Description:** Every operation is `@auth(level: USER)` and takes `orgId`/`branchId`/`id` as client variables. Any signed-in user, including an Employee or a suspended user (see M3), can call the GraphQL endpoint directly. They can list all organizations, read any org's members (PII), commercial agreements and license pricing, create or suspend organizations, create `platformOwner` members, and approve any return. UI role checks are not a security boundary (AGENTS §25).
- **Fix:** Put role, org and branches into custom claims set by a trusted function (see C8). Scope every operation server-side:
  ```graphql
  query ListBranchesForMyOrg @auth(expr: "auth.token.organizationId != null") {
    branches(where: { organization: { id: { eq_expr: "auth.token.organizationId" } } }) { id name code }
  }
  mutation CreateOrganization(...) @auth(expr: "auth.token.role in ['platformOwner','platformAdmin']") { ... }
  ```
  Use `@check`/`@redact` lookups for branch-manager scope. Make privileged mutations `NO_ACCESS` and run them via the Admin SDK.

### C2 ✅ Branch scoping is not implemented in the production access repository
- **Category:** Security
- **Location:** `lib/features/access/data/sql_connect_access_repository.dart:98-99, 118, 154-159, 177-182`
- **Description:**
  - Line 99: `assignedBranches = allBranches;` gives every Branch Manager every branch in the org.
  - Line 118: an Employee is pinned to `allBranches.first`, which is arbitrary.
  - Line 154: `getAssignedBranches(userId)` ignores `userId` and queries `orgId: 'org-acme'`, so `validateBranchAccess` validates every tenant against Acme's branches.
  - Org Admins are also auto-scoped to the first branch (lines 87-95), so org-wide screens show only one branch.
  - Inactive branches are not excluded.
  - The mock does all of this correctly, so tests pass.
- **Fix:** Add a `ListMyBranchAssignments` query (on `UserBranchAssignment`, filtered by `auth.uid`) and build `assignedBranches` from it:
  ```dart
  case UserRole.branchManager:
    final res = await _connector.listMyBranchAssignments().execute();
    assignedBranches = res.data.userBranchAssignments
        .map((a) => _toSummary(a.branch, orgId))
        .where((b) => b.isActive)
        .toList();
    final active = assignedBranches;
    if (active.length == 1) activeBranch = _toContext(active.single, orgId);
  ```
  Delete the `'org-acme'` literal. For Org Admins, leave `activeBranch` null (org-wide scope).

### C3 Production dashboards and reports are hardcoded to `org-acme`
- **Category:** Security
- **Location:**
  - `lib/features/organization_dashboard/data/sql_connect_organization_dashboard_repository.dart:14,27,30`
  - `lib/features/branch_dashboard/data/sql_connect_branch_dashboard_repository.dart:14,34-40`
  - `lib/features/reports/data/sql_connect_reports_repository.dart:12,30`
- **Description:** Every Org Admin sees Acme's counts, which is a cross-tenant leak. The branch dashboard silently falls back to `branches.first` when the requested branch isn't found. The contracts take no `UserAccessContext`.
- **Fix:** Add `UserAccessContext access` to `OrganizationDashboardRepository` and `BranchDashboardRepository`. Derive the org from `access.organization!.id`. Throw `NotFoundException` instead of falling back.

### C4 ✅ `user_aliases` writable across tenants and readable unauthenticated
- **Category:** Security
- **Location:** `firestore.rules` (the `match /user_aliases` block: `allow get: if true;` and `create/update/delete: if isOperator()`, where `isOperator()` includes any Org Admin); `lib/features/authentication/data/firebase_auth_repository.dart:54`
- **Description:**
  - Any Org Admin can repoint or delete the Platform Owner's alias, or another org's alias. This enables login hijack or lockout.
  - Anyone can probe identifiers and receive the email and uid.
  - The sign-in error message confirms whether an identifier exists.
- **Fix:** Set `allow write: if false;` and write aliases only from the trusted user-provisioning function. Resolve identifiers through a callable function with App Check and rate limiting. Always return a generic "Invalid username or password".

### C5 ✅ Universal password backdoor in mock auth; mock is the default build
- **Category:** Security
- **Location:** `lib/features/authentication/data/mock_auth_repository.dart:40-44`; `lib/app/config/backend_config.dart:19-21`
- **Description:** `password == 'password123' || password == 'Password123'` accepts any account. Any release built without `--dart-define=BACKEND_MODE=firebase` ships this backdoor. AGENTS §5 forbids "accepting any password".
- **Fix:**
  ```dart
  final isPasswordMatch = record != null && record.password == password;
  ```
  ```dart
  // main.dart
  if (kReleaseMode && BackendConfig.isMock) {
    throw StateError('Mock backend is not permitted in release builds.');
  }
  ```

### C6 ✅ `getOrganizationById` always throws
- **Category:** Bug
- **Location:** `lib/features/platform_organizations/data/sql_connect_platform_organizations_repository.dart:61-65`
- **Description:** `execute()` returns `QueryResult<Data, Vars>` (confirmed in `firebase_data_connect-0.4.1/lib/src/core/ref.dart:252`), so `results[0] as ListBranchesByOrgData` throws `TypeError`, which then becomes `DatabaseException`. Effects:
  - The org details page fails for every org.
  - `updateOrganizationStatus` commits the change and then reports failure, which invites retries.
  - A latent `description`↔`category` round-trip bug (line 76 vs 179) is masked by this one: each save would re-prefix `"Category: "`.
- **Fix:**
  ```dart
  final (branches, members) = await (
    _connector.listBranchesByOrg(orgId: id).execute(),
    _connector.listMembersByOrg(orgId: id).execute(),
  ).wait;
  final branchCount = branches.data.branches.length;
  final memberCount = members.data.organizationMembers.length;
  ```
  Longer term, replace with an aggregate count query (P1).

### C7 ✅ Employee attendance is never recorded in production
- **Category:** Bug / Security
- **Location:**
  - `lib/features/employee_home/data/firestore_employee_home_repository.dart:15, 67-107, 133-141, 147`
  - `lib/features/employee_home/presentation/screens/employee_home_screen.dart:220-223`
- **Description:**
  - The "Firestore" repository returns a hardcoded summary (`'Alex Rivera'`, `usr-acme-emp`, "Inside Geofence").
  - It writes punches to `attendance_punches`, which has no rule (default deny), and swallows the error with `catch (_) {}`. The UI then shows success.
  - `ShiftSimulatorBar` renders unconditionally, so any employee can set their own status through `setSimulatedStatus`.
- **Fix:**
  - Remove `setSimulatedStatus` from `EmployeeHomeRepository` (keep it on the mock only). Render the bar only when `BackendConfig.isMock && kDebugMode`.
  - Pass `UserAccessContext` into the contract.
  - Record check-ins in `attendance_entries` through a callable function that validates the geofence and stamps server time.
  - Add matching rules.

### C8 Account creation never creates a login identity
- **Category:** Bug / Security
- **Location:**
  - `lib/features/employees/data/sql_connect_organization_members_repository.dart:80, 94-107`
  - `lib/features/platform_users/data/firestore_platform_users_repository.dart:74, 96, 106-134`
  - `firestore.rules` (`isValidUser`, `isValidAlias`)
- **Description:**
  - `initialPassword` is ignored, so no Firebase Auth user is ever created.
  - Platform admins are written under a random doc id, not an Auth uid.
  - The fields written (`id`, `createdAt`, `uid`, `type`) violate `isValidUser`/`isValidAlias` (which expects `userId`), so the batch fails with PERMISSION_DENIED.
  - The members repo returns `id: ''`.
  - Privileged identity operations run on the client (AGENTS §4).
- **Fix:** Add one idempotent callable Cloud Function `provisionUser`. It runs Admin SDK `createUser`, sets custom claims `{role, organizationId, assignedBranches}`, creates the `users/{uid}` profile and `user_aliases` (create-only, inside a transaction), and inserts the SQL `OrganizationMember` with `authUid = uid`. Use the same pattern for `resetPassword`.

### C9 ✅ Password change is fake
- **Category:** Security
- **Location:** `lib/features/profile/presentation/screens/employee_profile_screen.dart:77-92`
- **Description:** `await Future.delayed(300ms)` then "Your password has been changed successfully." A user rotating a leaked password still has the old one.
- **Fix:** Add `Future<void> changePassword({required String current, required String next})` to `AuthenticationRepository`. Firebase implementation: `reauthenticateWithCredential` then `updatePassword`. Call it via `AuthController` and show its result. Until then, disable the card ("Not available yet").

### C10 Sign-out leaves the previous user's data in memory
- **Category:** Security
- **Location:** `lib/app/app.dart:186-307` (11 app-lifetime controllers); `lib/app/shell/adaptive_app_shell.dart:839-843`; `lib/features/employee_home/presentation/screens/employee_home_screen.dart:31-35`; `lib/features/organization_dashboard/presentation/screens/organization_home_screen.dart:27-31`
- **Description:**
  - Sign-out clears only the auth, access and branch controllers. `BranchDashboardController.reset()` exists but is never called.
  - Employee Home and Org Dashboard load only when `status == initial`, so on a shared tablet user B sees user A's summary indefinitely.
  - Other screens show A's rows until the post-frame reload completes.
  - Filters and search queries also persist.
- **Fix:** Preferred: create role-specific controllers inside each `ShellRoute` builder (`MultiProvider`) so they are disposed with the session. Minimum: give every controller `reset()` and call them from one `SessionController.signOut()` (see M6). Also reset branch-scoped controllers whenever `BranchContextController.activeBranch` changes.

---

## Major — Security & Correctness

### M1 ✅ Branch gate only fires for multi-branch managers
- **Category:** Security
- **Location:** `lib/app/routing/app_router.dart:73-84`
- **Description:** `if (!hasActiveBranch && hasMultipleBranches)` lets a Branch Manager into `/branch-manager/*` with no active branch. This happens with zero branches, or with one active plus one inactive branch. Screens then pass `activeBranchId: null`, and some repositories skip the filter when that is null (`MockReturnsRepository`). `/select-branch` and `/verify-access` are not role-guarded either (`app_router.dart:434-454`).
- **Fix:**
  ```dart
  if (isBranchManager && !branchController.hasActiveBranch && !isVerifyLocation) {
    if (!accessContext.hasAssignedBranches) return AppRoutes.noBranchAssigned;
    if (matched != AppRoutes.selectBranch) return AppRoutes.selectBranch;
  }
  if (matched == AppRoutes.selectBranch && !isBranchManager) return _defaultRouteForRole(userRole);
  ```
  Make `BranchContextController` the single owner of the active branch. Repositories must not fall back to `access.activeBranch` (`sql_connect_returns_repository.dart:27-29`).

### M2 ✅ Demo credentials on the production sign-in screen
- **Category:** Security
- **Location:** `lib/features/authentication/presentation/screens/sign_in_screen.dart:297-300`
- **Description:** `_buildDemoChip('Platform Owner', 'owner', 'Password123!')` renders in every build. It discloses privileged usernames and puts a password in source (AGENTS §5, §30).
- **Fix:** `if (BackendConfig.isMock && kDebugMode) _DemoAccountsPanel(accounts: MockAuthDataSource.demoAccounts)`. Keep the credentials in the mock fixture, not in the screen.

### M3 Suspension is client-side only; status parsing fails open
- **Category:** Security
- **Location:**
  - `lib/features/authentication/data/firebase_auth_repository.dart:88-108, 196-199`
  - `lib/features/platform_users/data/firestore_platform_users_repository.dart:192, 204-207`
  - `OrganizationStatus.fromString`
  - `sql_connect_access_repository.dart:45-55`
- **Description:**
  - Status is checked after `signInWithEmailAndPassword`, so the Firebase session is still valid for SQL Connect and Firestore.
  - A missing profile is treated as `employee/active`.
  - An unknown status string is treated as `active`.
  - Users of a suspended org (seeded `org-crest`) can still sign in.
  - The rules never check `status`.
- **Fix:**
  - Suspend with Admin SDK `updateUser(uid, disabled: true)` plus `revokeRefreshTokens`.
  - Add `status == 'active'` to the rule helpers.
  - Map unknown or missing values to deny.
  - Reject `orgData.status != 'active'` in access resolution.

### M4 Firestore rules can never authorize a Branch Manager
- **Category:** Security / Bug
- **Location:** `firestore.rules` (`isBranchManager` around lines 242-247; `isValidUser` around line 311)
- **Description:** `isBranchManager` requires `assignedBranches` in the token or in the user doc. `isValidUser` forbids that field, and nothing sets the claim. All Branch Manager attendance reads and writes are denied in Firebase mode, after the client-side checks have passed.
- **Fix:** Issue `assignedBranches` and `organizationId` as custom claims from `provisionUser` (C8). Refresh them when assignments change.

### M5 Stale-response races in controllers
- **Category:** Bug
- **Location:**
  - `access_controller.dart:23-43`
  - `branch_dashboard_controller.dart:45-48`
  - `attendance_controller.dart:39-44`
  - `organization_members_controller.dart:31-52`
  - `reports_controller.dart:31-36`
  - `returns_controller.dart:69-73`
  - `platform_organizations_controller.dart:90-113` (which also shares `_isLoading`/`_errorMessage` between the list and the detail views)
- **Description:** With rapid branch, date or query changes, or a sign-out mid-resolve, a late response overwrites the newer state. For example, user A's access context can land after user B signs in. The branch dashboard can also show branch A's summary while `_loadedBranchId == B`.
- **Fix:**
  ```dart
  int _generation = 0;
  Future<void> load(String branchId) async {
    final token = ++_generation;
    _status = Status.loading; notifyListeners();
    try {
      final data = await repository.fetch(branchId);
      if (token != _generation) return;
      _data = data; _status = Status.loaded;
    } catch (e) {
      if (token != _generation) return;
      _status = Status.error; _error = mapError(e);
    }
    notifyListeners();
  }
  void reset() { _generation++; _data = null; _status = Status.initial; notifyListeners(); }
  ```
  Debounce members search by about 300 ms.

### M6 Three different sign-out implementations
- **Category:** Bug
- **Location:** `adaptive_app_shell.dart:839-843` (not awaited; clears branch, then access, then calls signOut); `access_verification_screen.dart:103-115` and `branch_selection_screen.dart:45-57` (await signOut first)
- **Description:** In the shell order, each `clear()` triggers a redirect:
  1. Clearing the branch sends the user to `/select-branch`.
  2. Clearing access sends them to `/verify-access`.
  3. That screen calls `resolveAccess` for the user who is signing out, because `currentUser` is only nulled in `finally`.
  `AuthController.signOut` uses `try/finally` with no `catch`, so failures surface as unhandled async errors.
- **Fix:** Create one `SessionController.signOut()`. It nulls the user first, bumps the access generation, resets all scoped controllers, and wraps `authRepository.signOut()` in `try/catch`. All three call sites use it.

### M7 ✅ Branch Manager's member edit silently demotes and strips branches
- **Category:** Bug / Security
- **Location:** `lib/features/employees/presentation/screens/widgets/organization_member_editor_dialog.dart:58-60, 297-301`; `employee_directory_screen.dart:194-200`
- **Description:**
  - `_role = _isBranchManager ? UserRole.employee : ...` saves a co-manager or Org Admin as an Employee.
  - `_branches..clear()..add(activeBranchId)` removes the employee's other branch assignments.
  - Edit is offered on every row.
  - Email is also required (line 284), although it is an optional alias (AGENTS §3).
- **Fix:**
  - Show Edit only when `member.role == UserRole.employee && member.branchIds.contains(activeBranchId)`.
  - Preserve `member.role` and the other `branchIds`.
  - Validate email only when it is non-empty.
  - Enforce the same rules in the repository and backend.

### M8 Real repositories are insert-only and skip the mock's validation
- **Category:** Bug / Architecture
- **Location:**
  - `sql_connect_organization_members_repository.dart:85-107`
  - `sql_connect_branch_management_repository.dart:80-95, 119-148`
  - Compare with `mock_organization_members_repository.dart:151-218` and `mock_branch_management_repository.dart:62-98`
- **Description:**
  - "Save" always calls `create*`, so editing an existing record causes a primary-key conflict.
  - An Org Admin can create `platformOwner` members.
  - No `UserBranchAssignment` is written.
  - `isActive`, `isMainBranch` and `managerIds` are not persisted.
  - IDs come from `Random().nextInt(90000)`, so collisions are likely after a few hundred rows.
  - Kiosk pairing is an in-memory map with a non-cryptographic token.
  - Missing coordinates default to Bangalore (`?? 12.9716`).
- **Fix:**
  - Add `Update*` and `UserBranchAssignment_insert/delete` mutations, checked server-side.
  - Generate IDs with UUIDs (`gen_random_uuid()` default in the schema).
  - Move validation into domain validators (`OrganizationMemberValidator`, `BranchGeofenceValidator`) that both implementations call.
  - Make coordinates nullable.

### M9 Return review is unscoped and reviewer identity is client-supplied
- **Category:** Security
- **Location:** `lib/features/returns/presentation/controllers/returns_controller.dart:108-124`; `returns_operations_screen.dart:59-64`; `sql_connect_returns_repository.dart:27-29, 43-45, 66-82, 127-144`
- **Description:**
  - The review has no `access` or `activeBranchId`, and `reviewerName` is `access?.user.name ?? 'Manager Reviewer'`.
  - Employees download the whole branch's returns and filter them on the device.
  - The fallback IDs `'br-main'`/`'org-default'` are used.
  - Fields are mis-mapped: `customerName: input.productTitle`, `amount: input.quantity`.
  - `reviewReturn` returns a fabricated item.
- **Fix:**
  - Pass `access` to the controller, repository and mutation, and derive the reviewer from `auth.uid` server-side.
  - Add `ListMyReturns`/`ListReturnsByBranch` queries with `@check`.
  - Add the missing columns and fix the mapping.

### M10 ✅ Return submit mutates a `const []`
- **Category:** Bug
- **Location:** `lib/features/returns/presentation/controllers/returns_controller.dart:96` (also line ~127); `sql_connect_returns_repository.dart:32`
- **Description:** `_items.insert(0, created)` throws `UnsupportedError` when the repository returned `const []`. The server has already saved the return, but the user sees "Failed to submit".
- **Fix:** `_items = [created, ..._items];` and `_items = [...await repository.getReturns(...)];`

### M11 Business-critical timestamps from the device clock
- **Category:** Security
- **Location:** `lib/features/attendance/data/firestore_attendance_repository.dart:111-128, 153-154, 180, 202`; `firestore.rules` (attendance create)
- **Description:**
  - `checkInAt` and `workDate` come from the client, and the rules accept any value (AGENTS §27).
  - `access.organization?.id ?? 'org-platform'` writes junk org IDs.
  - `reviewException` runs outside `try`, so a raw `FirebaseException` escapes.
- **Fix:**
  - Use `FieldValue.serverTimestamp()` and require `request.resource.data.checkInAt == request.time` in the rules.
  - Compute the business-timezone `workDate` server-side.
  - Reject users without an org.
  - Wrap the body in `try` and map errors.

### M12 Two sources of truth for identity and role
- **Category:** Architecture
- **Location:** Firestore `users/{uid}` vs `dataconnect/schema/schema.gql:30-40` (`OrganizationMember`); `sql_connect_returns_repository.dart:77`
- **Description:** Role, org and status live in both stores with no link: `OrganizationMember.id` (`usr-…`) is not the Firebase uid. Returns store the uid, so they can't be joined to members. This violates AGENTS §4 (one authoritative home).
- **Fix:**
  - Make SQL authoritative for membership, role and branches. Add `authUid: String! @unique`.
  - Treat custom claims and the Firestore profile as documented projections, written only by the trusted function.
  - Update `docs/architecture.md`.

### M13 Raw exception text in the UI; errors swallowed into fake numbers
- **Category:** Bug / Security
- **Location:**
  - Raw text reaching users:
    - `firebase_auth_repository.dart:118` (`'Sign-in encountered an error: ${e.toString()}'`)
    - `branch_dashboard_controller.dart:50`, `employee_home_controller.dart:36,53,82`, `organization_dashboard_controller.dart:33`, `platform_dashboard_controller.dart:40`, `platform_organizations_controller.dart:54,107,133,154,180`
    - All `DatabaseException('...: ${e.toString()}')`
  - Errors replaced by fake values:
    - `sql_connect_reports_repository.dart:36-38,52` (`returnCount = 2`)
    - `sql_connect_platform_dashboard_repository.dart:42-44` (`adminCount = 2`)
  - `getCurrentUser`/`authStateChanges` return `null` on any Firestore error.
  - `main.dart:12-18` swallows a Firebase init failure and then builds Firebase repositories anyway.
  - `PlatformUsersFailure` does not extend `AppException`.
- **Fix:** Add `lib/core/errors/backend_error_mapper.dart`:
  ```dart
  AppException mapBackendError(Object e, StackTrace st) {
    _log.severe('backend error', e, st);
    return switch (e) {
      AppException() => e,
      FirebaseException(code: 'permission-denied') => const AccessDeniedException(),
      FirebaseException(code: 'unavailable' || 'deadline-exceeded') => const NetworkException(),
      DataConnectError(code: DataConnectErrorCode.unavailable) => const NetworkException(),
      _ => const DatabaseException('Something went wrong. Please try again.'),
    };
  }
  ```
  Never substitute fake values. Controllers display only `AppException.userMessage`, as `PlatformUsersController._friendlyError` already does.

### M14 `AuthController` never restores or monitors the session
- **Category:** Architecture
- **Location:** `lib/features/authentication/presentation/controllers/auth_controller.dart`
- **Description:** `getCurrentUser()` and `authStateChanges()` exist and are implemented but are never called. After a web refresh, the user lands on Sign In and deep links are lost. A revoked token leaves the app "authenticated".
- **Fix:** Add `init()`, awaited before the first redirect, with a splash/`initializing` state in the router. Subscribe to `authStateChanges()` and cancel the subscription in `dispose()`.

### M15 Root widget defaults to mocks
- **Category:** Architecture
- **Location:** `lib/app/app.dart:7-47, 66-173`
- **Description:** `WorkAxisApp` imports about 13 mock classes. Every repository parameter is optional and defaults to a mock. `_extractOrgsDataSource` type-checks concrete mocks. Forgetting one argument in Firebase mode silently mixes mock and production data (AGENTS §8).
- **Fix:** `const WorkAxisApp({required this.repositories})` with a `BackendRepositories` value object. Keep shared-mock wiring inside `BackendFactory`'s mock branch and the test helpers.

### M16 ✅ Fake behaviour and hardcoded demo data in production code
- **Category:** Architecture
- **Location:**
  - Fake saves (`Future.delayed` followed by a success message):
    - `settings/presentation/screens/organization_settings_screen.dart:43`
    - `platform_settings_screen.dart:34`
    - `employee_profile_screen.dart:79`
  - Hardcoded data in widgets:
    - `hero_attendance_card.dart:358-381, 420-430` ("Terminal Verified", "±3.2m")
    - `active_geofence_card.dart:78,124,229,285,321` ("5G Mesh"; `.split(' ').first[0]` throws on an empty name)
    - `employee_profile_screen.dart:138-141,269,327-375` ("Marcus Vance")
    - `attendance_summary_card.dart:162,307,398-422,551-640`
    - `return_details_dialog.dart:206-216` ("OCR bill · 1.2 MB")
    - `submit_return_dialog.dart:74` (`'mock_bill_scan.jpg'`)
    - `operational_reports_screen.dart:44-51` (export does nothing)
    - `attention_items_section.dart:299` (`onTap: () {}`)
    - `adaptive_app_shell.dart:67-72,412-427,558-645` (`'Alex Vance'`, `'APEX LOGISTICS'`, `'v2.4'`)
  - Hardcoded data in production repositories:
    - `sql_connect_organization_dashboard_repository.dart:44-100`
    - `sql_connect_branch_dashboard_repository.dart:51-85`
    - `sql_connect_reports_repository.dart:59-101`
    - `sql_connect_platform_organizations_repository.dart:103-124, 157-162`
- **Description:** AGENTS §5 forbids fake production behaviour and mock data inside widgets. Users see fabricated security signals (geofence precision, terminal verification), which is actively misleading.
- **Fix:**
  - Add `SettingsRepository` with mock and real implementations, plus `SettingsController`.
  - Drive every displayed value from a model. Hide or disable features that aren't implemented, e.g. `AppButton.outlined(onPressed: null, label: 'Export (coming soon)')`.
  - Move demo values into mock data sources.

### M17 Action failures are never surfaced
- **Category:** Bug
- **Location:**
  - Results ignored or unhandled:
    - `attendance_operations_screen.dart:356-361` (bool result ignored)
    - `group_attendance_dialog.dart:220-223` (no `else`)
    - `return_details_dialog.dart:35-44` (pops whether the review succeeded or failed)
    - `organization_details_screen.dart:559-562,587-589`
    - `platform_users_list_screen.dart:345-348,387-390`
    - `platform_administrator_details_screen.dart:160`
  - `ReturnsController.reviewReturn` writes the shared `_errorMessage`, which replaces the whole list with an error state.
  - A stale `actionErrorMessage` leaks into `PlatformAdministratorFormScreen` (line 212).
- **Fix:** Every action returns `bool` (or a `Result`). On `false`, show `controller.actionErrorMessage` in a snackbar or inline. Keep `actionError` separate from `loadError`. Pop dialogs only on success. Call `clearActionError()` when each form opens.

### M18 Group check-in double-records late entries
- **Category:** Bug
- **Location:** `lib/features/attendance/presentation/screens/widgets/group_attendance_dialog.dart:96-103, 113-117, 134-140, 782`
- **Description:**
  - "Already checked in" means only `status == present`, so `late` entries are pre-selected and recorded again.
  - Pre-selection ignores `_sameDate`.
  - The selection count includes rows hidden by the filter.
  - The eligibility logic lives in the widget.
- **Fix:** Add `domain/services/group_attendance_eligibility.dart` with `bool isRecorded(AttendanceEntry e, DateTime day) => _sameDay(e.workDate, day) && e.checkInAt != null;`, and unit-test it.

### M19 New branch geofence defaults to 0,0
- **Category:** Bug
- **Location:** `lib/features/branches/presentation/screens/widgets/branch_editor_dialog.dart:54-59, 232-241`
- **Description:** Latitude and longitude default to `0.0`, and validation accepts them, so the geofence sits at Null Island and every check-in fails. The geofence rules also live in the widget (AGENTS §13, §28).
- **Fix:** Leave the fields empty and reject 0/0. Add `BranchGeofenceValidator` in the domain layer, with tests.

### M20 Edit Organization loses edits on back; Tax ID not editable
- **Category:** Bug
- **Location:** `lib/features/platform_organizations/presentation/screens/edit_organization_screen.dart` (no `PopScope`; discard guard only at `_handleCancel` around line 237)
- **Fix:**
  ```dart
  PopScope(
    canPop: !_isDirty,
    onPopInvokedWithResult: (didPop, _) { if (!didPop) _handleCancel(org); },
    child: scaffold,
  )
  ```
  Add the `taxIdentification` field, which is collected in Add (`add_organization_screen.dart:26,488`) but missing from Edit.

### M21 Search state drift and per-keystroke backend search
- **Category:** Bug
- **Location:** `organizations_list_screen.dart:29,216-221`; `platform_users_list_screen.dart:29,185-188`; `employee_directory_screen.dart:27,113-122,146`; `returns_operations_screen.dart:27`; `core/widgets/app_text_field.dart:52-58`
- **Description:**
  - The singleton controllers keep their query while each screen creates an empty `TextEditingController`, so an invisible filter stays applied.
  - Members search hits the backend on every keystroke and swaps the list for a spinner each time.
  - The clear button in `AppTextField.search` never updates as the user types.
- **Fix:**
  - Seed the field: `TextEditingController(text: controller.searchQuery)`.
  - Debounce the search.
  - Wrap the suffix icon in `ValueListenableBuilder<TextEditingValue>(valueListenable: controller, ...)`.

### M22 `AppButton` loading invisible; KPI cards overflow
- **Category:** Bug / Accessibility
- **Location:** `lib/core/widgets/app_button.dart:136-145, 219-231`; `lib/core/widgets/kpi/responsive_kpi_section.dart:57,103,127`; `lib/core/widgets/kpi/app_kpi_card.dart:189-198`
- **Description:**
  - The spinner is always `Colors.white`, which is invisible on the outlined and tonal variants.
  - On the primary button, `onPressed: null` while loading switches to the disabled grey background with white text. This affects the Sign In button.
  - A fixed 96dp card height holds about 89dp of content at 1.0× text scale, so any text scaling overflows (AGENTS §33).
  - Breakpoints read `MediaQuery` screen width, not available width, so at 840dp with a 260dp sidebar, 4–5 cards share about 516dp (AGENTS §17).
- **Fix:**
  - Derive the spinner and text colour from the variant's foreground colour, and set `disabledBackgroundColor`/`disabledForegroundColor` for the loading state.
  - Use `ConstrainedBox(constraints: BoxConstraints(minHeight: 96))` with `FittedBox(fit: BoxFit.scaleDown)` for the value.
  - Choose columns from `LayoutBuilder` constraints, as `ResponsiveLayout` already does.

---

## Major — Performance

### P1 N+1 queries, full downloads for counts, no pagination
- **Category:** Performance
- **Location:**
  - `sql_connect_reports_repository.dart:43-52`: one sequential `listReturnsByBranch` per branch, used only for `.length`.
  - `sql_connect_platform_organizations_repository.dart:33-44,61-66`
  - `sql_connect_platform_dashboard_repository.dart:27,61`: `listOrganizations` called twice.
  - `sql_connect_organization_members_repository.dart:48-73`
  - `sql_connect_branch_management_repository.dart:47-50`
  - No `limit` anywhere in `queries.gql`; no `.limit()` on Firestore attendance queries. The platform-level `getAttendance` reads every org's attendance (`firestore_attendance_repository.dart:36-40`).
- **Fix:**
  - Use aggregate fields (`branches_on_organization { _count }`, `returnRecords_on_branch_aggregate`).
  - Add `GetBranchById`/`GetMemberById`.
  - Push `where` filters to the server (`name: { contains: $q }, status: { eq: $s }`).
  - Add `limit`/`offset` (or cursor) to every list and paginate in the controllers.

### P2 Non-lazy lists
- **Category:** Performance
- **Location:**
  - `attendance_operations_screen.dart:233-277`
  - `attendance_table.dart:71-79`
  - `returns_operations_screen.dart:324,427-459`
  - `employee_returns_screen.dart:319,418-446`
  - `employee_directory_screen.dart:182-203`
  - `branch_management_screen.dart:153-172`
  - `group_attendance_dialog.dart:689-691`
  - `organizations_list_screen.dart:326-362`
  - `platform_users_list_screen.dart:283-315`
  - `recent_organizations_list.dart:302-316`
- **Description:** A `SingleChildScrollView` wraps a `Column`/`Wrap`/shrinkWrap `ListView` over every row. Org-wide attendance and the directory will reach hundreds of rows.
- **Fix:**
  ```dart
  CustomScrollView(slivers: [
    SliverToBoxAdapter(child: header),
    SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisExtent: 168),
      itemCount: entries.length,
      itemBuilder: (_, i) => AttendanceCardItem(entry: entries[i]),
    ),
  ])
  ```
  Use a bounded-height `ListView.builder` for the dialog roster.

### P3 (Minor) Work inside `build()`
- **Category:** Performance
- **Location:**
  - `DateFormat`/`NumberFormat` created per row or per build:
    - `organization_license_tab.dart:745,805,900`
    - `organizations_table.dart:56`
    - `organization_card_item.dart:24`
    - `platform_administrators_table.dart:288`
    - `attendance_card_item.dart:32`
  - `_formatTime` is implemented three times with different output (`attendance_operations_screen.dart:547`, `attendance_table.dart:692`, `attendance_card_item.dart:32`).
  - `recent_organizations_list.dart:70,137-173` filters and counts twice per build.
  - `add`/`edit_organization_screen` call `setState` on the whole screen for each keystroke.
  - `edit_organization_screen.dart:271-277` schedules a post-frame callback from inside `build()`.
- **Fix:** Add `lib/core/formatting/date_time_formatters.dart` with `static final` formatters. Memoise counts in the controller. Use `ValueListenableBuilder` for character counters.

---

## Major — Architecture

### A1 Monolithic and duplicated files (AGENTS §10)
- **Category:** Architecture
- **Proposed splits:**
  - **`app/shell/adaptive_app_shell.dart` (844 lines):** duplicates the branch box, org box, nav tile and badge switch with `app_navigation_drawer.dart`. Split into `ExpandedShell`, `CompactShell`, `ShellSidebar`, `TopConsoleBar`, `BranchContextCard`, `OrgScopeCard`, `NavTile` and `UserProfileMenu`, shared with the drawer. Move the role destination lists (`app_router.dart:107-425`) into `role_destinations.dart`.
  - **`add_organization_screen.dart` (848) and `edit_organization_screen.dart` (1038):** about 70% shared. Extract into `widgets/organization_form/`: `OrganizationFormSectionCard`, `OrganizationProfileFields`, `OrganizationContactFields` and `OrganizationFormFooter`, plus a form-state mapper.
  - **`organization_license_tab.dart` (1122):** split into `license_summary_card`, `license_details_panel`, `license_history_panel`, `license_empty_state` and `license_formatters`.
  - **`organization_status_dialogs.dart` (691):** merge the near-identical Suspend and Reactivate dialogs into one config-driven `OrganizationStatusChangeDialog`.
  - **`recent_organizations_list.dart` (995):** split into a filter bar, desktop/compact rows and a card. Extract a shared `TableHeaderCell`; the header is copy-pasted 7 times here and again in `organizations_table.dart:117-205`.
  - **`employee_returns_screen.dart` and `returns_operations_screen.dart`:** about 70% shared. Extract `ReturnsFilterBar`, `ReturnsTable(columns:)` and `ReturnsResponsiveList`.
  - **Remaining large files:**
    - `group_attendance_dialog.dart` (791): split into a form controller, config section and roster.
    - `attendance_table.dart` (722): use `StatusChip`/`UserAvatar`.
    - `branch_management_screen.dart`: move `_BranchDetailsDialog` out.
    - `attendance_summary_card.dart` (640): move it to `shared/`, because `branch_dashboard` imports it across features.
  - **Domain models depending on Flutter:** `AttentionItem` carries `IconData`/`StatusType`, so data repositories import `flutter/material.dart`. Replace these with a domain enum and map it to icons in the presentation layer.
  - **Business rules and string-typed logic in widgets:**
    - Email regex duplicated 4× (`add_organization_screen.dart:76`, `edit_organization_screen.dart:177`, `organization_admin_dialog.dart:69`, `platform_administrator_form_screen.dart:91-96`). The admin dialog requires both email and phone, which contradicts AGENTS §3.
    - Status compared as strings: `status.toLowerCase() == 'active'`.
    - Admin actions are a `'edit'|'reset'|'suspend'|'remove'` string protocol.
    - Thresholds in widgets: `attendanceRate >= 95`, `adherenceRate >= 0.90`.
    - Fix: move these into domain validators, enums and model getters.
  - **Permission strings differ:** mock (`org.access`) vs real (`org.manage`), and nothing reads either. Define them once as a domain enum, or delete them.

---

## Tests

### T1 Tests pass against mocks that enforce rules the real repositories skip
- **Category:** Architecture / Tests
- **Description:** Branch scoping, org matching, platform-role ban, uniqueness and password length are tested only through `Mock*Repository`. No test exercises the SQL Connect repositories' scoping, which is where C2, C3 and M8 live.
- **Fix:** Write a shared **contract test suite** per repository interface and run it against both the mock and the real implementation (the real one with an injected fake connector):
  ```dart
  void accessRepositoryContract(AccessRepository Function() create) {
    test('branch manager receives only assigned branches', () async { ... });
    test('employee cannot validate a branch outside their org', () async { ... });
  }
  ```

### T2 Tests lock in fake production data
- **Category:** Tests
- **Location:**
  - `test/features/dashboards/sql_connect_dashboards_repository_test.dart:15-44`: asserts `totalScheduled == 48` and `'Geofence Exception'`.
  - `test/features/employee_home/firestore_employee_home_repository_test.dart:17-33`: asserts `'Alex Rivera'` and `setSimulatedStatus`.
- **Description:** These tests guarantee that the hardcoded values (M16) stay in place. Removing the fakes will look like a regression.
- **Fix:** Delete them and replace them with tests that feed a fake connector or `FakeFirebaseFirestore` with seeded data and assert the mapping.

### T3 A test passes only because of network or Firebase failure (non-hermetic)
- **Category:** Tests
- **Location:** `test/features/access/sql_connect_access_repository_test.dart` (`validateBranchAccess returns false when user has no assigned branches`)
- **Description:** `SqlConnectAccessRepository()` uses `WorkaxisConnectorConnector.instance` with no Firebase app. The call throws, the blanket `catch (_) => false` returns `false`, and the test passes for the wrong reason. It would also pass for a branch the user *does* own.
- **Fix:** Inject a fake `WorkaxisConnectorConnector` (or wrap the connector behind a small `AccessRemoteDataSource` interface). Assert both the positive and the negative case.

### T4 Missing coverage for critical paths
- **Category:** Tests
- **Missing:**
  - Router redirects per role: direct navigation to another role's route, the Branch Manager with zero or one-active branch case (M1), `/select-branch` for non-managers.
  - Sign-out clears every scoped controller (C10, M6).
  - Stale-response ordering in controllers (M5).
  - `getOrganizationById` against a fake connector, which would have caught C6.
  - Suspended user or suspended org denied (M3).
  - The `ReturnsController.submitReturn` with an empty initial list (M10).
  - Member editor preserves role and branches (M7).
  - Group attendance `late` double-record (M18).
  - Error mapping produces safe messages (M13).
  - Firestore rules: no `@firebase/rules-unit-testing` suite exists. Add one for `user_aliases`, attendance and users.

### T5 Date-dependent tests
- **Category:** Tests
- **Location:** `test/features/attendance/group_attendance_test.dart:68-69,100`; `test/features/operations/operations_mock_repositories_test.dart:199`
- **Description:** These use `DateTime.now()` and are flaky around midnight and across timezones.
- **Fix:** Inject a `Clock` (`package:clock` or a small `typedef Now = DateTime Function()`) into repositories and controllers, and use a fixed date in tests.

---

## Minor

- **m1 Design-system bypass (AGENTS §23A), Code Style:**
  - About 68 raw `ElevatedButton`/`FilledButton`/`TextButton`/`OutlinedButton` across 24 screen files. Examples: `hero_attendance_card.dart:487` (main check-in CTA), `organization_details_screen.dart:323-352`, `organization_status_dialogs.dart:263-654`.
  - 6 raw search `TextField`s that should be `AppTextField.search`.
  - The profile screen hand-rolls 5 password toggles; use `AppPasswordField`.
  - About 300 `Color(0x…)` literals (worst: `attendance_table.dart` 64, `organization_overview_tab.dart` 25). KPI colour triplets and the card shadow pair are copied across screens; add `AppColors.kpi*` and `AppShadows.card` tokens.
  - About 480 literal `fontSize:` values and many `GoogleFonts.*` calls that bypass `AppTypography`.
  - Hand-built page headers in add/edit organization and employee home.
- **m2 Raw breakpoints, Code Style:** 600/620/650/900/960/980/1000/1024/1040 are scattered (e.g. `employee_home_screen.dart:75,227`, `organization_details_screen.dart:286,314,356`). Add named tokens to `AppBreakpoints`.
- **m3 Tap targets under 48dp, Accessibility:**
  - `IconButton(padding: EdgeInsets.zero, constraints: BoxConstraints())`: Change Branch (`adaptive_app_shell.dart:292-302`, drawer `179-188`) and dialog close buttons.
  - Verify/Dismiss `InkWell`s about 22dp tall (`attendance_card_item.dart:328-414`).
  - Pagination buttons at 28dp (`organizations_table.dart:339-380`).
  - `ErrorBanner` retry and dismiss (`error_banner.dart:70-89`).
  - Missing tooltips on icon buttons.
  - `AppTextField` label is not semantically linked to the field.
  - `ErrorBanner` is not a live region.
  - The selected nav item is shown by colour only.
- **m4 Responsive risks, Bug:**
  - `return_details_dialog.dart:118-137`: `Row` with no `Expanded`.
  - Fixed `SizedBox(height: 680/700)` in the editor dialogs.
  - The compact footer `Row` in edit org (938-954).
  - Status dialogs have no scroll.
  - `attendance_table.dart:31` forces at least 1150px.
  - The details header mixes `MediaQuery` and `LayoutBuilder` widths.
- **m5 Small bugs, Bug:**
  - "for null" subtitles (`attendance_operations_screen.dart:93`, `operational_reports_screen.dart:80,102`).
  - Negative "Expires in -12 days" (`organization_license_tab.dart:107,219`).
  - The details screens' first frame shows the previously selected entity.
  - Platform dashboard KPIs are never refreshed after mutations (`platform_home_screen.dart:24-29`).
  - `access.organization!` force-unwraps (`branch_management_screen.dart:196`, member editor 305).
- **m6 Dead code, Code Style:**
  - Unreferenced: `operations_kpi_card.dart`, `AttendanceEntryCard`, `OrgKpiCard`, `platform_kpi_card.dart`, both `placeholders/*` screens, `organization_admin_item.dart`.
  - The required `onEdit` on `OrganizationsTable`/`OrganizationCardItem` is never invoked, so Edit is unreachable from the list.
- **m7 `dynamic` usage, Code Style:** `employee_home_screen.dart:148` (`dynamic summary`), `adaptive_app_shell.dart:461` (`dynamic user`).
- **m8 Repo hygiene, Security:** `tool/seed_database.py:14` hardcodes a personal email as the default `PGUSER`; read it from the environment only. `fontFamily: 'JetBrains Mono'` is not bundled; use `GoogleFonts.jetBrainsMono`.
- **Suggestion (unverified intent):** `/platform/settings` (session timeout, lockout policy) is reachable by Platform Administrators. If it should be Owner-only, guard it as `/platform/users` is.

---

## What is in good shape
- `flutter analyze` is clean and all 210 tests pass.
- Repository contracts exist for every feature, and `BackendFactory` centralises mock/firebase selection.
- `TextEditingController`/`PageController` disposal and `mounted` checks after `await` were correct on every path the reviewers traced.
- The `platform_users` feature uses enums, `AppButton`, `AppPageHeader` and per-field errors, and is the best template for refactoring `platform_organizations`.
- Platform Users is correctly limited to the Platform Owner.
- `KpiCarousel` widgets correctly use `AppKpiCard` + `ResponsiveKpiSection`.
