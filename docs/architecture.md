# WorkAxis Architecture Documentation

This document records the current architectural foundation and engineering decisions for the Flutter application. It complements the constraints in `AGENTS.md` and must reflect the codebase as it actually exists.

## 1. Application Model

WorkAxis is **one Flutter application** with role-based navigation and permissions.

Primary targets:

- Android smartphones
- Android tablets
- Web browsers

Initial roles:

- Platform Owner
- Platform Administrator
- Organization Admin
- Branch Manager
- Employee

Platform-level and customer-level experiences live in the same Flutter codebase. Separate admin and customer applications must not be introduced unless the product direction changes explicitly.

Customer-side users (`Organization Admin`, `Branch Manager`, and `Employee`) belong to exactly **one customer organization**. They do not select or switch between customer organizations.

`Platform Owner` and `Platform Administrator` are platform-level users. They may manage multiple customer organizations through platform administration, but they do not switch customer-organization membership contexts.

A `Branch Manager` may be assigned to multiple branches inside their organization. When more than one active branch is assigned, the manager must select a branch before entering branch-scoped operational screens. The selected branch becomes the active branch context until changed.

## 2. Project Organization

WorkAxis follows a **feature-first, clean, pragmatic architecture**:

```text
lib/
├── app/
│   ├── app.dart                   # Root application widget
│   ├── bootstrap/                 # Application startup and dependency registration
│   ├── routing/                   # Centralized GoRouter configuration, guards and role destinations
│   ├── session/                   # SessionController: sign-out and per-session state lifecycle
│   ├── startup/                   # Splash shown while a previous session is restored
│   ├── shell/                     # Adaptive authenticated application shells
│   └── theme/                     # Material 3 theme and shared visual tokens
│
├── core/
│   ├── constants/                 # Breakpoints and genuinely shared constants
│   ├── errors/                    # Typed application failures, backend error mapper, user-safe messages
│   ├── formatting/                # Cached date/time/number formatters (AppFormatters)
│   ├── session/                   # SessionScoped contract implemented by controllers
│   ├── state/                     # RequestGeneration (stale-response guard), SafeNotifier
│   ├── time/                      # Injectable clock (Now / Clock)
│   ├── responsive/                # Adaptive layout helpers and breakpoints
│   ├── services/                  # Cross-cutting services
│   ├── utils/                     # Focused validators / formatters
│   └── widgets/                   # Genuinely reusable application widgets
│
├── features/
│   ├── authentication/
│   ├── access/
│   ├── platform/
│   ├── branches/
│   ├── employees/
│   ├── attendance/
│   ├── returns/
│   ├── reports/
│   ├── notifications/
│   └── profile/
│
└── main.dart                      # Flutter entry point
```

This is a guideline, not a requirement to create empty folders. Feature-specific code stays inside its feature until genuine cross-feature reuse exists.

## 3. State Management Strategy

The project uses a **single pragmatic state-management approach**:

- `Provider` for dependency / state exposure.
- `ChangeNotifier` and `ValueNotifier` for controllers and state where appropriate.
- UI state, feature/application state, business rules, and data access remain separate responsibilities.
- Widgets must not directly query Firebase, PostgreSQL, Firestore, or mock collections.

If the implementation later proves this approach insufficient, any replacement must be treated as an architectural change and documented before introducing a competing state-management pattern.

## 4. Mock-First Data Architecture

The first implementation phase uses **mock data**, but the architecture is production-oriented from the beginning.

Presentation and state-management code call stable repository/service functions. They never consume mock literals directly.

Conceptual flow during UI development:

```text
Presentation
    ↓
Controller / State
    ↓
Repository contract
    ↓
Mock data source
```

Later backend integration:

```text
Presentation
    ↓
Same Controller / State
    ↓
Same Repository contract
    ↓
Real Firebase / PostgreSQL / Firestore data source
```

The goal is to preserve, wherever practical:

- Function names
- Function signatures
- Return models
- State/controller calling code
- Presentation code

Only the underlying repository/data-source implementation should change when real backend integration begins.

### Implemented Repository Contracts

WorkAxis defines stable domain repository contracts in `lib/features/*/domain/repositories/`:

- `AuthenticationRepository`:
  - `Future<AuthenticationResult> signIn({required String identifier, required String password})`
  - `Future<void> signOut()`
  - `Future<void> changePassword({required String currentPassword, required String newPassword})`
  - `Future<AppUser?> getCurrentUser()` and `Stream<AppUser?> authStateChanges()`
- `AccessRepository`:
  - `Future<UserAccessContext> resolveCurrentUserAccess(AppUser user)`
  - `Future<List<BranchSummary>> getAssignedBranches(String userId)`
  - `Future<bool> validateBranchAccess({required String userId, required String branchId})`
- `PlatformDashboardRepository`:
  - `Future<PlatformDashboardSummary> getPlatformDashboardSummary()`
  - `Future<List<RecentOrganizationSummary>> getRecentOrganizations({int limit})`
- `OrganizationDashboardRepository`:
  - `Future<OrganizationDashboardSummary> getOrganizationDashboardSummary(String orgId)`
  - `Future<AttendanceSummary> getOrganizationAttendanceSummary(String orgId)`
  - `Future<List<AttentionItem>> getOrganizationAttentionItems(String orgId)`
- `BranchDashboardRepository`:
  - `Future<BranchDashboardSummary> getBranchDashboardSummary(String branchId)`
  - `Future<AttendanceSummary> getBranchAttendanceSummary(String branchId)`
  - `Future<List<AttentionItem>> getBranchAttentionItems(String branchId)`
- `EmployeeHomeRepository`:
  - `Future<EmployeeHomeSummary> getEmployeeHomeSummary()`
  - `Future<EmployeeHomeSummary> recordAttendanceAction(AttendanceAction action)`
- `BranchManagementRepository`:
  - organization-scoped branch listing, lookup, and save operations
  - branch manager choices, kiosk pairing token generation, and mock pairing completion
- `OrganizationMembersRepository`:
  - account listing and lookup scoped by organization, active branch, and current role
  - account profile save with an initial password passed transiently to the repository
- `AttendanceRepository`:
  - date-scoped attendance listing for an organization, active branch, or employee
  - exception verification and dismissal with role and branch checks

### Mock Isolation

Mock implementations live exclusively under `lib/features/*/data/`:
- `MockAuthDataSource` and `MockAuthRepository`: Provide realistic latency, user records with alias resolution (`username`, `email`, `phone`), and authentication failure modes.
- `MockAccessDataSource` and `MockAccessRepository`: Provide realistic role and branch mappings (e.g. single-branch vs multi-branch assignments, organization metadata).
- `MockPlatformDashboardDataSource` and `MockPlatformDashboardRepository`: Provide realistic platform overview metrics (Total Organizations, Active Organizations, Suspended Organizations, Platform Administrators) and recent customer organization onboarding items.
- `MockPlatformUsersDataSource` and `MockPlatformUsersRepository`: Provide fictional Platform Administrator profiles for owner-managed search, profile updates, and reversible access suspension. Initial passwords remain transient and are never stored in mock profile data.
- `MockOrganizationDashboardDataSource` and `MockOrganizationDashboardRepository`: Provide organization-wide KPIs, today's attendance breakdown, and prioritized attention items.
- `MockBranchDashboardDataSource` and `MockBranchDashboardRepository`: Provide branch-isolated operational KPIs, attendance rates, and localized attention items.
- `MockEmployeeHomeDataSource` and `MockEmployeeHomeRepository`: Provide action-oriented attendance actions (Check In, Start Break, End Break, Check Out), shift progress, geofence status, and pending returns.
- `MockBranchManagementRepository`: Uses `MockAccessDataSource` as the authoritative branch and user-to-branch assignment source; keeps geofence and kiosk state in branch-specific mock settings. Pairing codes are generated in memory and not persisted.
- `MockOrganizationMembersRepository`: Stores typed organization member fixtures, enforces role and branch scopes, and updates the access projection after mock profile changes. The initial password is discarded; newly created mock profiles do not authenticate until a future auth integration wires them to Firebase Authentication.
- `MockAttendanceRepository`: Stores typed daily/history fixtures, scopes employee reads to the current employee and manager reads to the active assigned branch, and supports mock exception review.

Controllers interact strictly with the abstract repository interfaces injected via `Provider`. Replacing mock data with real Firebase / SQL Connect data sources requires zero modifications to presentation widgets or controllers.

Mock data must:

- Use the same typed models expected by real implementations.
- Support realistic loading, empty, success, and failure states where useful.
- Stay outside widgets.
- Be replaceable without rewriting presentation code.

## 5. Authentication Architecture

Authentication uses an identifier plus password.

A user may sign in using any identifier attached to the same account:

- Chosen username
- Email address, when provided
- Phone number, when provided

All available identifiers use the same account password.

The application does **not** use:

- OTP login
- Google sign-in
- Public registration
- Email-based password recovery
- Self-service forgotten-password recovery

Accounts are created only by authorized administrators. The creating administrator sets the initial password. Authorized administrators may reset forgotten passwords. Users may voluntarily change their own password after signing in. Administrator-set or reset passwords do not require a forced change on next login.

Passwords must never be stored in PostgreSQL, Firestore, local mock data intended to mirror production records, logs, or presentation models. Production password handling remains the responsibility of Firebase Authentication / trusted authentication services.

The presentation layer calls a stable contract such as:

```text
signIn(identifier, password)
```

The future production implementation may internally resolve the supplied username/email/phone alias before completing Firebase Authentication. That implementation detail must not leak into the UI.

## 6. Account Creation Permissions

Current account-creation boundaries:

- `Platform Owner` may create and manage `Platform Administrator` accounts.
- `Organization Admin` may create other `Organization Admin`, `Branch Manager`, and `Employee` accounts inside their organization.
- `Branch Manager` may create `Employee` accounts only for branches they are authorized to manage.
- `Employee` cannot create login accounts.

Account-creation permissions do not automatically imply password-reset or broader user-administration permissions unless those rights are explicitly defined.

## 7. Access Context

After authentication, the application resolves a typed access context rather than making role decisions independently inside individual screens.

The context may include:

```text
Authenticated user
Account status
Role
Organization context (customer-side roles)
Assigned branch IDs (Branch Manager)
Active branch ID (when branch-scoped)
Permissions
```

For customer users, organization context is fixed to their single organization.

### Active Branch Context Management

Branch context is managed via `BranchContextController`:
- Stored as an immutable `ActiveBranchContext` instance holding `branchId`, `branchName`, `branchCode`, and `organizationId`.
- Set only from verified assigned branches via `selectBranch(BranchSummary)`.
- Validated to ensure Branch Managers can never select a branch outside their authorized assignment set.
- Cleared upon sign-out or when explicitly changing active branches.
- Branch-scoped dashboards automatically refresh their data when the active branch context changes.

## 8. Routing, Navigation Shells & Guards

Centralized routing uses **GoRouter** with role-based `ShellRoute` compositions in `lib/app/routing/app_router.dart`:

```text
/sign-in               -> SignInScreen
/access-verification   -> AccessVerificationScreen
/select-branch         -> BranchSelectionScreen

// Platform Shell
/platform                        -> PlatformHomeScreen
/platform/organizations          -> OrganizationsListScreen
/platform/organizations/add      -> AddOrganizationScreen
/platform/organizations/:id      -> OrganizationDetailsScreen
/platform/organizations/:id/edit -> EditOrganizationScreen
/platform/users                  -> PlatformUsersListScreen (Platform Owner only)
/platform/users/add              -> PlatformAdministratorFormScreen
/platform/users/:id              -> PlatformAdministratorDetailsScreen
/platform/users/:id/edit         -> PlatformAdministratorFormScreen

// Organization Admin Shell
/organization                    -> OrganizationHomeScreen
/organization/branches           -> BranchManagementScreen
/organization/employees          -> EmployeeDirectoryScreen
/organization/attendance         -> AttendanceOperationsScreen
/organization/returns            -> FeaturePlaceholderScreen
/organization/reports            -> FeaturePlaceholderScreen
/organization/settings           -> FeaturePlaceholderScreen

// Branch Manager Shell
/branch-manager                  -> BranchHomeScreen
/branch-manager/employees        -> EmployeeDirectoryScreen (active branch only)
/branch-manager/attendance       -> AttendanceOperationsScreen (active branch only)
/branch-manager/returns          -> FeaturePlaceholderScreen
/branch-manager/reports          -> FeaturePlaceholderScreen

// Employee Shell
/employee                        -> EmployeeHomeScreen
/employee/attendance             -> AttendanceOperationsScreen (self only)
/employee/returns                -> FeaturePlaceholderScreen
/employee/profile                -> FeaturePlaceholderScreen
```

### AdaptiveAppShell

The authenticated application shell dynamically adapts based on screen width:
- **Compact (`<600dp`)**: Collapsible navigation side pane (drawer) opened via hamburger menu button in the app bar, with role-specific items.
- **Medium (`600–839dp`)**: Collapsible navigation side pane (drawer) opened via hamburger menu button in the app bar.
- **Expanded (`≥840dp`)**: Persistent navigation sidebar with organization branding, role chip, item list with active indicators, active branch context banner (for Branch Manager), top console header bar, and user profile menu.

The router includes a centralized redirect guard reacting to `AuthController`, `AccessController`, and `BranchContextController`:
1. Unauthenticated users are redirected to `/sign-in`.
2. Authenticated users without resolved access are redirected to `/access-verification`.
3. Branch Managers without an active branch context are always gated (`/no-branch-assigned` when no active branch is assigned, otherwise `/select-branch`). See section 17.
4. Users attempting to access a route for a different role are redirected to their permitted workspace.

Conceptual routing flow:

```text
Sign In
  ↓
Verify / Resolve Access
  ↓
Role Resolution
  ├── Platform Owner → Platform shell (/platform)
  ├── Platform Administrator → Platform shell (/platform)
  ├── Organization Admin → Organization Admin shell (/org-admin)
  ├── Branch Manager
  │      ├── one active assigned branch → Branch Manager shell (/branch-manager)
  │      └── multiple active assigned branches → Branch Selection (/select-branch) → Branch Manager shell (/branch-manager)
  └── Employee → Employee shell (/employee)
```

Protected routes must not depend solely on hidden navigation items. Guards and backend authorization must enforce access boundaries.

No customer organization-selection or organization-switching route should exist for Organization Admins, Branch Managers, or Employees.

## 9. Backend Direction

The production backend uses the Firebase ecosystem with a **hybrid persistence strategy**.

Planned services:

- **Firebase Authentication** — authenticated identity and password handling.
- **Firebase SQL Connect / PostgreSQL** — relational business data where relationships, constraints, and relational reporting are important.
- **Cloud Firestore** — high-growth or event-oriented data where document access patterns are a better fit.
- **Firebase Storage** — photos, documents, receipts, and other binary files.
- **Trusted server-side functions/services** — privileged or security-sensitive operations when required.

Do not convert the architecture into Firestore-only or PostgreSQL-only without an explicit architectural decision.

The exact PostgreSQL/Firestore boundary is finalized feature by feature. Data volume alone is not sufficient reason to choose one store.

Every business datum must have **one authoritative source of truth**. If a derived projection or cache is introduced in the other store, its owner and synchronization strategy must be documented.

Do not assume a single atomic transaction can span PostgreSQL and Firestore. Cross-store workflows must be designed explicitly when they arise.

## 10. Data Access Rules

UI widgets must not know whether a repository is using:

- Mock data
- PostgreSQL
- Firestore
- Firebase Storage
- A trusted server-side function

Repositories expose business-oriented operations and typed models.

Data-store-specific details remain inside concrete data-source/repository implementations.

Avoid generic repository APIs that merely mirror database CRUD. Prefer operations that express the feature's needs clearly.

## 11. Organization and Branch Scoping

Customer data queries are always scoped to the user's single organization.

There is no customer-side organization switching, so code should not introduce unnecessary organization-switching state or cache-reset flows.

Branch Manager access is additionally scoped to the set of assigned branches.

When a Branch Manager selects an active branch:

- Branch-scoped state uses that branch ID.
- Employee, attendance, returns, and other branch-scoped queries use that context.
- Changing branches invalidates / refreshes branch-scoped state as needed.
- Data from the previous branch must not remain displayed under the new branch context.

Backend authorization remains authoritative. UI filtering alone is not a security boundary.

## 12. Responsive & Adaptive Strategy

WorkAxis treats **smartphone, tablet, and web layouts as intentional experiences**, not scaled copies of one another.

Centralized default breakpoints:

- **Compact (`<600dp`)** — smartphone-oriented layouts.
- **Medium (`600–839dp`)** — tablet-oriented layouts.
- **Expanded (`≥840dp`)** — large tablet / web-oriented layouts.

### Compact / Smartphone

Prefer:

- Single-column layouts
- Collapsible navigation drawer opened via hamburger menu
- Compact cards and list rows
- Full-screen forms where appropriate
- Horizontal carousels for selected dashboard summaries when established by the Stitch design
- Touch-friendly controls
- Minimal vertical clutter

Do not compress desktop dashboards into a phone screen.

### Medium / Tablet

Prefer:

- Collapsible navigation drawer opened via hamburger menu
- Wider content regions
- Multiple columns where useful
- Horizontal summary rows/carousels where established by design
- List/detail composition when appropriate

Do not simply stretch smartphone cards.

### Expanded / Large Tablet and Web

Prefer:

- Persistent side navigation when appropriate
- Multi-column layouts
- Master-detail patterns
- Wider structured lists and forms
- Comfortable maximum content widths

On sufficiently wide web layouts, avoid unnecessary horizontal carousels when all relevant summary information fits cleanly.

Web does not require feature parity with Android when a specific capability is disproportionately complex or inappropriate in the browser. Such exclusions are decided feature by feature and must not silently remove core business requirements from Android.

## 13. Stitch Design Integration

Approved Google Stitch screens are the visual and interaction source of truth for implemented screens.

When a Stitch design exists:

- Match its information hierarchy and visual language closely.
- Implement smartphone and tablet behavior intentionally.
- Do not blindly reproduce desktop composition on mobile.
- Reuse centralized Material 3 theme and design tokens rather than hardcoding generated styles into individual widgets.
- Adapt implementation details when necessary for accessibility, responsiveness, or Flutter platform conventions without unnecessarily redesigning the approved screen.

## 14. Security Boundaries

- Authentication success does not automatically grant unrestricted application access.
- Role, organization, branch, and permission checks must be enforced beyond UI visibility.
- Never place Firebase administrative credentials or service-account secrets in the Flutter application.
- Never log passwords, authentication tokens, sensitive documents, or other secrets.
- Sensitive business data must be exposed only to roles authorized to see it.
- Backend rules / trusted services remain authoritative for privileged mutations.

## 16. Session Lifecycle

App-lifetime controllers hold per-user data, so the session boundary is explicit:

- `AuthController.init()` runs once at startup (`WorkAxisApp.initState`). While it restores the previous session (`getCurrentUser()`) `isInitializing` is true and the router shows `SplashScreen` (`/initializing`) instead of redirecting. After init it subscribes to `authStateChanges()` (cancelled in `dispose`). A provider-side sign-out (revoked token, disabled account) ends the session; a stream *error* is logged and never treated as a sign-out. Non-null stream events never sign a user in: only `signIn()` does, because it enforces all checks.
- `AccessController` takes an `onResolved` callback that initialises `BranchContextController` *before* listeners are notified, so the router never sees "access resolved, branch not yet initialised". Every resolve carries a generation token; `clear()` invalidates in-flight resolutions so user A's context can never land after user B signs in.
- `SessionController` (`lib/app/session/`) is the single sign-out path (shell, verification, branch selection, no-branch and profile screens). `signOut()` starts `AuthController.signOut()` (which nulls the user synchronously and then calls the identity provider inside try/catch), clears access and branch context, and calls `reset()` on every feature controller. Provider failures are logged; local state is wiped regardless. Identity-provider-initiated sign-out runs the same cleanup.
- Every feature controller implements `SessionScoped.reset()`: it invalidates in-flight requests, restores the initial state and clears filters/queries/errors. `SessionController` also resets the branch-scoped controllers (branch dashboard, attendance, returns, members, reports) whenever `BranchContextController.activeBranch` changes, so data from the previous branch is never shown under the new one.
- Screens that show summaries (Employee Home, Organization Home) load on entry rather than only when status is `initial`.

### Stale responses

Mutating controllers capture a session/branch epoch before calling repositories and check it before every state update, error/finalization and follow-up load. Settings persistence callbacks apply values only while their save token remains current. Auth initialization never creates a subscription after disposal.

Controllers that load asynchronously use `RequestGeneration` (`lib/core/state/`): `final token = _requests.next(); ... if (!_requests.isCurrent(token)) return;`. `PlatformOrganizationsController` keeps separate list and detail state (`isListLoading`/`listErrorMessage` vs `isDetailLoading`/`detailErrorMessage`); `isLoading`/`errorMessage` remain as legacy combined getters until screens migrate. `OrganizationMembersController.setQuery` is debounced (300 ms). Controllers expose their current filter/query so screens seed their text fields from them.

## 17. Routing Guards (current)

`resolveRedirect` in `app_router.dart` is a pure function, unit-tested per role:

1. Initializing -> `/initializing`.
2. Unauthenticated -> `/signin`.
3. Authenticated on `/signin` or splash -> `/verify-access`; access unresolved -> `/verify-access`.
4. A Branch Manager without an active branch is always gated: no active assigned branch -> `/no-branch-assigned`, otherwise `/select-branch`.
5. `/select-branch` is Branch-Manager-only; `/verify-access` and `/no-branch-assigned` redirect away once resolved.
6. Role-area protection (`redirectForRoleRoute`), including the Owner-only `/platform/users`.

Unknown locations render `RouteErrorScreen`. Role destination lists live in `lib/app/routing/role_destinations.dart`. A deep link is not preserved across a session restore (the user lands on their role workspace).

## 18. Error Handling

Repositories and infrastructure may throw anything; presentation shows only safe text.

- `AppException` (`lib/core/errors/app_exceptions.dart`) carries a developer-facing `message` and a user-safe `userMessage`. Types: `AuthenticationException`, `AccessResolutionException`, `BranchAuthorizationException`, `AccessDeniedException`, `NotFoundException`, `DatabaseException`, `NetworkException`, `RequestTimeoutException`.
- `mapBackendError(error, [stackTrace])` (`backend_error_mapper.dart`) maps `FirebaseException`, `FirebaseAuthException` and Data Connect errors (`DataConnectError.dataConnectErrorCode`) to those types and logs the raw error through `dart:developer` (never `print`). Unknown errors become a generic `DatabaseException`.
- `userMessageFor(error, stackTrace, fallback: ...)` is what controllers call: typed failures with a specific category show their `userMessage`; raw exceptions collapse to the controller's fallback text. Controllers never interpolate `$e`/`toString()`.
- Load errors (`errorMessage`) are separate from action errors (`actionErrorMessage`, `clearActionError()`), so a failed submit never replaces a loaded list.
- Authentication fails closed: `FirebaseAuthRepository` denies a missing profile or unknown role/status, returns the same "Invalid username or password." for unknown identifiers and wrong passwords, and surfaces transient failures from `getCurrentUser`/`authStateChanges` instead of reporting "signed out".

## 19. Clock, Formatting and Theme Tokens

- `lib/core/time/clock.dart`: `typedef Now = DateTime Function()` plus `Clock` (`Clock.fixed(...)` for tests). Controllers that need "today" (e.g. `AttendanceController`) take a `Now`; tests use `test/helpers/fixed_clock.dart`. Business-critical timestamps must still be server-confirmed once the backend is connected.
- `AppFormatters` (`lib/core/formatting/date_time_formatters.dart`): cached `DateFormat`/`NumberFormat` helpers with one canonical `formatTime` (`h:mm a`), dates and INR currency. Do not construct formatters in `build()`.
- Tokens: `AppColors.kpi*` (semantic KPI triplets and slate neutrals), `AppColors.consoleBadge*`, `AppShadows.card`/`topBar`, and named content breakpoints in `AppBreakpoints` (`formSplit`, `wideContent`, `detailsSplit`, `wideTable`, `employeeHomeWide`, `sidebarWidth`, `topBarHeight`).
- Core widgets: `AppButton` keeps variant colors and a visible spinner while loading; `AppKpiCard` has a minimum height and scales its value; `ResponsiveKpiSection` and `AppPageHeader` choose their layout from `ContentWidthScope` (the width left after the sidebar, published by the shell and `ResponsivePageContent`) instead of the screen width. A `LayoutBuilder` is deliberately not used there because these widgets are embedded in `IntrinsicHeight`.

## 20. App Wiring

`WorkAxisApp` takes one required `BackendRepositories` value (`repositories:`) built by `BackendFactory`. There are no per-repository mock defaults, so a mock and a production repository can never be mixed by omission. `BackendFactory.createMockRepositories({delay})` is the single place where mock fixtures are shared (one `MockAccessDataSource`, one `MockPlatformOrganizationsDataSource`); tests use `test/helpers/test_backend.dart`. `main()` calls `BackendConfig.assertReleaseSafe()` (a release build with the mock backend throws) and lets a Firebase initialisation failure propagate. Sign-in quick-fill accounts are shown only when `BackendConfig.isMock && kDebugMode`, and come from `MockAuthDataSource.demoAccounts`; the mock backend has no universal password.

`AuthenticationRepository.changePassword({currentPassword, newPassword})` re-authenticates (Firebase: `reauthenticateWithCredential` + `updatePassword`) before applying the change; `AuthController.changePassword` exposes the result to the profile screen.

### Shell

`AdaptiveAppShell` picks `ExpandedShell` (>= 840dp: `ShellSidebar` + `TopConsoleBar`) or `CompactShell` (app bar + `AppNavigationDrawer`). `BranchContextCard`, `OrgScopeCard`, `NavTile` and `UserProfileMenu` are shared by the sidebar and drawer. Identity text comes only from the access context; nothing is shown until it resolves. Selected navigation items expose `Semantics(selected: true)` and all icon actions are at least 48dp with tooltips.

## 21. Accounts, Organizations and Branches Data Layer

Applies to `access`, `authentication`, `employees`, `platform_users`, `platform_organizations` and `branches`. Server contract: `docs/backend-api.md`.

**Remote data sources.** Each SQL-backed repository depends on a thin `*RemoteDataSource` interface (`AccessRemoteDataSource`, `OrganizationMembersRemoteDataSource`, `PlatformUsersRemoteDataSource`, `PlatformOrganizationsRemoteDataSource`, `BranchesRemoteDataSource`) with one `SqlConnect*RemoteDataSource` implementation that is the only code touching the generated connector. Repositories hold the rules and error mapping, so they are unit-tested with in-memory fakes (`test/helpers/fake_*`). Identity writes never use SQL Connect or Firestore from the client: `AccountCallables` wraps `provisionUser`, `updateUserAccount`, `resetUserPassword` and `setUserStatus`; organization status uses `setOrganizationStatus`; kiosk codes use `createKioskPairingToken`. Branch fields and manager assignments use `saveBranch`, an Org Admin callable with one SQL transaction; direct branch mutations are closed to clients. The transaction rechecks manager scope, unchanged assignments and the last-branch invariant before writing. Create drafts carry a stable request ID; SQL stores its server-derived creation key and payload fingerprint to recognize retries without duplicate branches. `BackendFactory` injects `FirebaseCallableFunctions` (lazy, region `asia-south1`); mocks stay hermetic.

**Sign-in.** `FirebaseAuthRepository` resolves username/email/phone through `resolveLoginIdentifier` (never reads `user_aliases`). Role, organization and status come from ID-token custom claims and fail closed when missing or unknown. The profile document supplies display fields only. Any identifier failure shows "Invalid username or password."; network and rate-limit failures show their own safe text.

**Access.** `AccessResolver` (pure) is shared by `MockAccessRepository` and `SqlConnectAccessRepository`: members and organizations must be active; Organization Admins are organization-wide (all active branches in `assignedBranches`, no `activeBranch`); Branch Managers get their active assigned branches (one is auto-selected); Employees get their active assigned branches and work in the first. The production repository additionally cross-checks the token role/organization and member status against `GetMyMember` (SQL is authoritative) and takes assignments from `ListMyBranchAssignments`. `validateBranchAccess` denies on any error. Permissions are the `AppPermission` enum via `AppPermissionSet.forRole`.

**Policies shared by mock and real.** `OrganizationMemberPolicy` (who may create/edit/suspend whom; edits preserve role and other branches), `PlatformAdministratorValidator`, `OrganizationValidator`, `BranchManagementPolicy` and `BranchGeofenceValidator` (radius 25-5000 m, optional coordinates, (0,0) rejected). Validation failures are `ValidationException` with user-safe text. Email and phone are optional aliases (`ContactValidators`); synthetic `*.invalid` login emails are never displayed (`LoginEmail`).

**Pagination.** Lists use `PageResult` (`items`, `total`, `offset`, `hasMore`) with server-side `limit/offset` and filters (`ListMembersByOrgPaged`, `ListMembersByBranchPaged`, `ListPlatformMembersPaged`, `ListOrganizationsPaged`). Summary counts come from aggregate queries (`GetPlatformStats`, `GetOrganizationStats`), never from downloading lists. Controllers expose `loadMore()` and apply search/status filters instantly to loaded rows, reloading from the server (debounced) when the loaded rows are not the complete result.

**Ids.** The server assigns all entity ids. The only client-generated identifier is the per-create `requestId` idempotency key (`RequestIds.uuidV4`, secure random), reused when the same create is retried.

**Tests.** `test/contracts/*_contract.dart` define behaviour once per repository interface (access, members, platform users, organizations, branches) and run against the mock and against the production repository wired to fakes.
## 21a. Operational Data Layer (attendance, returns, dashboards, reports, settings)

Repositories take the caller's `UserAccessContext` (and the active branch where relevant) and derive organization and branch from it; there are no magic ids, and no repository substitutes fabricated numbers for a failure. Every method maps errors through `mapBackendError`, so UI text is always safe.

- **Business day.** `lib/core/time/business_time.dart` holds `kBusinessTimeZone = 'Asia/Kolkata'` (UTC+05:30, same as `BUSINESS_TIMEZONE` in `functions/src/config.ts`) and `BusinessTime` (`dateOf`, `today(now)`, `keyOfInstant`, `keyOfDate`, `startOfDay`). `workDateString` keys are always computed through it from the injected `Now`, never from the device-local date. Attendance dates passed to repositories are business calendar dates; `AttendanceController` defaults to `BusinessTime.today`.
- **Attendance** (`FirestoreAttendanceRepository`): reads are constrained by organization, active assigned branch or own UID and traverse every 500-document page with a document-ID cursor; the list contract returns the complete scoped day so KPI totals are complete. Group check-ins use `recordGroupAttendance` only; Firestore rules deny all direct attendance/audit creates. The callable checks authoritative SQL caller/branch/employee membership, rejects duplicate attendees and already-recorded daily IDs in a Firestore transaction, and uses a stable request ID plus payload fingerprint for retry safety. It validates the explicitly zoned effective check-in time against the selected business date, server clock and six-day backdate window, and records `createdAt` separately with server time. Group forms convert business-calendar date/time through `BusinessTime.startOfDay`, independent of the device timezone. Employee names come from SQL, never client input.
- **Employee Home**: `EmployeeHomeRepository` takes `UserAccessContext`; the real repository reads the employee's own entry for today and records punches only via the `recordAttendancePunch` callable with the GPS fix from an `AttendanceLocationProvider`. The device fix comes from `GatewayAttendanceLocationProvider` (domain service: service-on check, one permission request when denied, blocked state, 15 s timeout, every failure a `LocationException` with a `LocationFailure` and a user-safe message) over the `DeviceLocationGateway` seam; `GeolocatorDeviceLocationGateway` (data) is the only code touching the `geolocator` plugin, and `BackendFactory` wires it for Firebase mode (the mock repository needs no provider). `UnavailableAttendanceLocationProvider` remains only as the repository default when none is injected. `EmployeeHomeSimulator` is implemented by the mock only; `EmployeeHomeController.simulator` is non-null only for a mock in debug builds and the screen renders `ShiftSimulatorBar` only then. Fields the backend does not hold are `EmployeeHomeSummary.unavailable` / null.
- **Returns**: `ReturnsScope` (domain) holds the shared authorization rules used by the mock and the real repository. Employees use `ListMyReturns`, Branch Managers `ListReturnsByBranchPaged` for the active branch, Org Admins `ListReturnsByOrgPaged` (optionally narrowed to a branch). The remote seam accepts offset/limit; repositories traverse all 100-row pages with stable createdAt/id ordering rather than silently truncating the operational queue. The current complete-list contracts keep counts/search accurate, at the cost of loading the whole scoped result; explicit UI paging can replace them when needed. `SubmitReturn` and `UpdateReturnRecordReview` take no identity (the server derives submitter/reviewer). The seam `ReturnsRemote` is faked in tests.
- **Dashboards**: SQL Connect aggregates only (`GetOrganizationDashboardCounts`, `GetBranchStats`, `GetPlatformStats`, `GetOrganizationStats` for the 5 most recent organizations) plus Firestore count queries (`AttendanceDayCounter`) for today's attendance. `AttentionItem` is a pure domain model (`AttentionKind`/`AttentionSeverity`); `attention_item_presentation.dart` maps it to icons and `StatusType`. `AttendanceSummary.onLeave` is null (no leave data); per-branch adherence snapshots are not provided.
- **Reports**: return totals per branch and per reason come from `GetReturnCountsByBranch` (Org Admin, whole organization) or `GetBranchStats` (Branch Manager, or an Org Admin narrowed to one branch), both scoped by optional `$from`/`$to` (business-calendar period via `ReportPeriodRange`, `[from, to)`), so `returnCountsCoverPeriod` is true and `returnCategories` is filled (percentages of the period total; unknown legacy reasons count as Other). Organization return volume sums the authoritative aggregate, including history from suspended branches; active branch assignments do not restrict historical organization totals. Attendance rates, hours, exceptions and trends are null/empty until the backend can compute them. `ReportPeriod` is an enum.
- **Settings**: `SettingsRepository` (mock in memory; `FirestoreSettingsRepository` on `organization_settings/{orgId}` and `platform_settings/global`), typed `OrganizationSettings`/`PlatformSettings` with `SettingsValidators` (geofence 10-5000 m, grace 0-120 min, session timeout 5-1440 min, lockout attempts 3-10), `SettingsController` (load/save, field errors, `lastSaveSucceeded`, `SessionScoped`). Organization Admins manage organization settings; platform roles read and only the Platform Owner writes platform settings. Rules (in `firestore.rules`, covered by `functions/test-rules`): `organization_settings/{orgId}` read/write when `isOrgAdminOf(orgId)` (read also for platform roles), with a field whitelist and `updatedAt == request.time`, `updatedBy == request.auth.uid`; `platform_settings/global` read for platform roles, write only for `platformOwner` with the same audit checks and numeric range checks.
- **Test seams**: remote interfaces (`ReturnsRemote`, `OrganizationDashboardRemote`, `BranchDashboardRemote`, `PlatformDashboardRemote`, `ReportsRemote`) wrap the generated connector; Firestore-backed repositories are tested with `FakeFirebaseFirestore`; the punch callable with a fake `CallableFunctions`. Contract suites run the same assertions against the mock and the real repository.

**Dependency note - `geolocator` (^14).** Attendance punches need a real GPS fix with accuracy for server-side geofence validation (AGENTS 28). Flutter has no built-in geolocation API, and `geolocator` is the maintained federated plugin covering all three targets (Android, iOS, and web through `geolocator_web`) with one permission/service/accuracy/timeout API, so a single package replaces three platform integrations. It is isolated behind `DeviceLocationGateway`; nothing else imports it. Platform config: Android `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION`, iOS `NSLocationWhenInUseUsageDescription`; the web build prompts through the browser and requires HTTPS (or localhost).

## 22. Architecture Change Policy

Before making a significant architectural change:

1. Inspect the current implementation.
2. Read `AGENTS.md` and this document.
3. Explain why the existing approach is insufficient.
4. Avoid introducing a competing pattern alongside an existing one without justification.
5. Update this document after the change is accepted and implemented.

This document must describe **actual current architecture**, not aspirational features that have not been adopted.


## Audit remediation: identity consistency and unavailable settings

Account updates explicitly distinguish omitted email from `email: null` (clear the alias and use the synthetic login email). Member fields and assignments commit together in SQL. Alias/Auth failures compensate existing alias targets as well as newly reserved aliases. Before cross-store writes, trusted functions create server-only `identity_sync_jobs` records containing the UID and candidate alias keys, never passwords. After SQL commits, projection failures leave a durable job and return saved/pending instead of claiming the business edit failed. `reconcileIdentitySync` runs every minute, projects the latest authoritative SQL record onto Auth/aliases/profile and retries failed jobs with backoff. Jobs wait three minutes before first reconciliation to avoid racing an active callable. Per-UID Firestore leases serialize account edits, branch changes and reconciliation; cleanup failures rely on lease expiry and never turn a committed save into a failure. All job/lease collections are default-denied to clients. The callable, rules and SQL connector changes must be deployed together; no deployment is part of local validation.

Unavailable policy controls are read-only and described as saved preferences: session timeout, lockout/complexity, maintenance broadcast, attendance policy defaults and notification automation do not claim runtime enforcement. Organization contact details remain editable. This preserves the mock-first scope without inventing enforcement. Employee Home has an explicit checkout action in both checked-in and on-break states. Organization list counts not returned by SQL are nullable and displayed as unavailable, not zero. Header actions stack at increased text scales while title typography retains its form-factor sizing.

Local validation includes Flutter unit/widget/app flows, Node domain/recovery tests, and `functions/test-sql` against the demo SQL Connect emulator. SQL integration covers transaction rollback, clearing coordinates, active employee counts, branch-read scoping, closed direct mutations and branch-create retry metadata.
