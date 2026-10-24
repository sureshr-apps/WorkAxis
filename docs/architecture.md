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
│   ├── routing/                   # Centralized GoRouter configuration and guards
│   ├── shell/                     # Adaptive authenticated application shells
│   └── theme/                     # Material 3 theme and shared visual tokens
│
├── core/
│   ├── constants/                 # Breakpoints and genuinely shared constants
│   ├── errors/                    # Typed application failures / exceptions
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
  - `AppUser? get currentUser`
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
3. Branch Managers with multiple branches and no active branch context are redirected to `/select-branch`.
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

## 15. Architecture Change Policy

Before making a significant architectural change:

1. Inspect the current implementation.
2. Read `AGENTS.md` and this document.
3. Explain why the existing approach is insufficient.
4. Avoid introducing a competing pattern alongside an existing one without justification.
5. Update this document after the change is accepted and implemented.

This document must describe **actual current architecture**, not aspirational features that have not been adopted.
