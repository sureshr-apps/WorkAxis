# AGENTS.md

## Purpose

This file defines the permanent engineering, architecture, implementation, and code-quality rules for this repository.

These instructions apply to **every implementation task in this project**.
Treat them as **non-negotiable engineering constraints**, not optional recommendations.

Before implementing or modifying any feature:

1. Read this file completely.
2. Inspect the existing repository structure.
3. Review existing architecture, shared components, and tests.
4. Read `README.md` and `docs/architecture.md` if they exist.
5. Read `STITCH_FIDELITY_RULES.md` completely before implementing or modifying any UI screen or component.
6. Review the relevant Stitch design/reference for the feature when one exists.
7. Understand the requested change before writing code.
8. Preserve established project conventions unless there is a strong reason to improve them.

Optimize for:

- Correctness
- Simplicity
- Maintainability
- Testability
- Readability
- Extensibility
- Consistency

Do not optimize merely for the fastest way to make a screen work.

---

# 1. Product and Platform Context

This repository contains **one Flutter application**.

The same Flutter application serves all supported roles and must adapt its UI and capabilities based on the authenticated user's role, organization, branch context, permissions, and device form factor.

Supported targets:

- Android smartphones
- Android tablets
- Web browsers
- Smartphone portrait and landscape
- Tablet portrait and landscape
- Responsive browser widths

There is **no separate customer app and platform-console app** in this architecture.
Platform administration and customer operations are part of the same Flutter application with role-based navigation and access.

Use **Material Design 3** unless explicitly instructed otherwise.

---

# 2. Current User Roles

The initial roles are:

- Platform Owner
- Platform Administrator
- Organization Admin
- Branch Manager
- Employee

Role behavior must be implemented through explicit permissions and scoped data access, not by UI visibility alone.

## Platform Owner

Platform-level role responsible for overall platform administration and Platform Administrator management.

## Platform Administrator

Platform-level role responsible for permitted platform operations such as customer-organization administration.

Platform Owner and Platform Administrator are **platform-level users**. They may manage multiple customer organizations as platform objects. This is not customer-organization membership switching.

## Organization Admin

Belongs to exactly one customer organization.
May perform permitted organization-wide operations for that organization.
May create Organization Admin, Branch Manager, and Employee accounts within that organization.

## Branch Manager

Belongs to exactly one customer organization.
May be assigned to **one or more branches** within that organization.

A Branch Manager must never receive access to branches outside their assigned set.

When assigned to multiple branches:

- The manager must select a branch before entering branch-scoped operational screens.
- The selected branch becomes the active branch context until changed.
- Do not aggregate all assigned branches by default unless a future requirement explicitly asks for it.
- Employee, attendance, return, reporting, and other branch-scoped operations must use the active branch context.

A Branch Manager may create Employee accounts only for a branch they are authorized to manage.

## Employee

Belongs to exactly one customer organization and accesses only their permitted self-service/operational functions.

Customer-side users, including Organization Admins, Branch Managers, and Employees, do **not** belong to multiple customer organizations and do not use an organization-switching flow.

---

# 3. Authentication and Account Rules

The application uses **identifier + password** authentication.

Do not implement OTP login unless the requirements explicitly change in the future.

A user may sign in using any login identifier associated with the same account:

- Chosen username
- Email address, when provided
- Phone number, when provided

These are login aliases for **one account**, not separate accounts.

Login identifiers must resolve uniquely across the application.

The login UI should conceptually support:

```text
Username, email, or phone number
Password
```

Account rules:

- There is no public self-registration.
- Accounts are created only by authorized administrators/managers.
- Platform Owner may create/manage Platform Administrators.
- Organization Admin may create permitted organization users.
- Branch Manager may create Employees only within authorized branch scope.
- The account creator sets the initial password.
- Authorized administrators may reset forgotten passwords according to their scope.
- There is no email-based password recovery flow.
- Users may voluntarily change their own password after login.
- Do not force a password change merely because an administrator set or reset the password.

Never store plaintext passwords in PostgreSQL, Firestore, local storage, logs, analytics, or application state.

Keep authentication identity and application authorization as separate concerns.
Successful authentication does not automatically imply access to application data.

---

# 4. Firebase and Backend Direction

The project uses the **Firebase ecosystem**, with a hybrid persistence model.

Current direction:

- Firebase Authentication for authentication identity/password flows
- Firebase SQL Connect / PostgreSQL for relational data
- Cloud Firestore for high-growth/event-oriented data
- Firebase Storage / Cloud Storage for files and images
- Trusted Firebase/server-side functions where privileged or cross-store operations require them

Do **not** replace this direction with Firestore-only or PostgreSQL-only unless explicitly instructed.

## PostgreSQL / SQL Connect

Prefer PostgreSQL for data that benefits from:

- Relational integrity
- Strong relationships
- Uniqueness constraints
- Structured reporting
- Membership/role relationships
- Organization/branch/employee relationships
- Transactional relational updates

## Firestore

Prefer Firestore for data that grows continuously or benefits from document/event access patterns, for example high-volume event histories or notifications when appropriate.

Do not choose a database merely because a collection is large. Consider query shape, reporting, transactional requirements, authorization, and lifecycle.

## Single source of truth

Each business entity must have one authoritative home.

Do not independently maintain the same authoritative employee, organization, membership, branch, or other record in both PostgreSQL and Firestore.

If a projection/derived copy is required:

- Define its authoritative source.
- Define who updates it.
- Keep it minimal.
- Document the synchronization strategy.

## Cross-store operations

Do not assume a transaction can atomically update PostgreSQL and Firestore together.

For operations spanning multiple stores:

- Use trusted server-side orchestration where necessary.
- Define failure/retry behavior.
- Prefer idempotent operations.
- Document consistency expectations.

---

# 5. Mock-First Implementation Approach

The current implementation phase is **UI-first with mock data** unless the user explicitly asks to connect a real backend feature.

Build production-quality UI architecture now, while using mock repositories/services behind stable contracts.

Preferred progression:

```text
Stitch design/reference
    ↓
Flutter UI
    ↓
Typed models
    ↓
Repository/service contracts
    ↓
Mock implementations
    ↓
Real Firebase/PostgreSQL/Firestore implementations later
```

Rules for mock data:

- Do not hardcode large mock datasets directly inside widgets.
- Keep mock data in dedicated mock repositories/data sources/fixtures.
- Use realistic typed models.
- Simulate loading, empty, success, and error states where relevant.
- Support representative role and branch scenarios.
- Keep presentation code unaware of whether data comes from mock or real implementations.
- Make replacing a mock repository with a real repository possible without rewriting the screen.

Do not connect Firebase merely to make a mock-only UI task appear more complete.

Do not introduce fake production behavior such as accepting any password or bypassing authorization inside production code. Development fakes must be clearly isolated.

---

# 6. Stitch Design Source of Truth

When a Stitch design exists for a screen or flow, treat it as the **visual and interaction source of truth** for that task.

**MANDATORY: Read `STITCH_FIDELITY_RULES.md` completely before implementing or modifying any UI component or screen.**

Stitch controls visual intent such as:

- Information hierarchy
- Layout composition and element geometry
- Typography hierarchy and font pairings
- Spacing, padding, and gutters
- Cards and panel surface treatments
- Buttons, chips, and badges
- Inputs and form controls
- Navigation patterns (sidebar, top console header, bottom nav)
- Responsive composition
- Phone/tablet/web screen behavior

`AGENTS.md` controls engineering quality and architecture.

### Non-Negotiable Fidelity Rules:

- **Never substitute generic Material Design component templates for the approved Stitch layout.** For example, do not invert KPI cards by putting icons top-left and titles below numbers when Stitch puts titles top-left and icons top-right.
- **Decompose every component geometrically** into Top Row, Middle Row (with inline badges and semantic data colors), and Bottom Row (with status indicator dots/icons and metadata) as detailed in `STITCH_FIDELITY_RULES.md`.
- **Inline badges belong beside metrics**, not in arbitrary card corners, whenever the Stitch design displays them inline.
- **Semantic colors must apply to data metrics** (e.g. urgent or suspended counts in bold crimson red `#ba1a1a`).
- Recreate the approved design using clean Flutter architecture and reusable Flutter components that adapt to the design, not by forcing the design into preconceived generic widgets.
- Do not blindly copy generated web/HTML/CSS implementation patterns into Flutter.
- If the Stitch reference conflicts with a confirmed business requirement, the confirmed requirement wins and the conflict should be reported.
- If a design is missing a required state, implement the state consistently with the established design system rather than inventing a completely different visual language.

---

# 7. Core Engineering Principles

All implementation must follow:

- SOLID principles
- Clean Code
- Separation of Concerns
- DRY
- KISS
- YAGNI
- Dependency inversion where it provides real value
- Composition over unnecessary inheritance
- Clear responsibility boundaries

Apply these principles pragmatically.
Do not create abstractions purely for theoretical purity.

---

# 8. SOLID

## Single Responsibility Principle

A class, widget, service, repository, controller, state object, or file should have one clear responsibility.

Do not combine unrelated responsibilities simply because placing everything in one file is convenient.

## Open/Closed Principle

Prefer designs that can be extended without repeatedly rewriting stable code.
Do not introduce unnecessary abstraction solely for hypothetical future requirements.

## Liskov Substitution Principle

Implement abstractions consistently.
Do not create inheritance hierarchies where implementations violate parent expectations.

## Interface Segregation Principle

Prefer small, focused contracts.
Do not create enormous interfaces containing unrelated methods.

## Dependency Inversion Principle

High-level business logic should not depend directly on low-level infrastructure details.
Where appropriate, depend on repository/service contracts rather than Firebase, SQL Connect, Firestore, storage, or platform-specific implementations directly.

---

# 9. Clean Code

Prefer:

- Clear names
- Small cohesive functions
- Focused classes
- Explicit behavior
- Predictable control flow
- Minimal side effects
- Consistent conventions

Avoid:

- Deep nesting
- Massive functions
- Hidden side effects
- Ambiguous naming
- Duplicate logic
- Dead code
- Commented-out production code
- Temporary hacks left permanently in the codebase

Comments should explain **why** something exists when the reason is not obvious.
Good naming and structure should explain **what** the code does.

---

# 10. Never Create Monolithic Files

This rule is critical.

Do **not** implement entire features inside one enormous Dart file.

Do not combine all of the following into one screen file:

- UI
- Business logic
- Data access
- Validation
- State management
- Models
- Mapping
- Navigation
- Permissions

Split code when responsibilities differ or readability suffers.

Appropriate extraction may include:

- Page/screen
- Screen section
- Reusable widget
- Form section
- Controller/notifier/view model
- State object
- Repository
- Service
- Data source
- Model/entity/DTO
- Mapper
- Validator
- Extension
- Focused utility

Do not keep appending code to a file merely because it already exists.

If a file becomes difficult to understand or navigate, **stop and refactor it before continuing**.

There is no goal to minimize the number of files.
The goal is clear responsibilities and discoverability.

---

# 11. Avoid Over-Engineering

Splitting responsibilities does not mean creating unnecessary layers.

Avoid patterns such as:

```text
Interface
  ↓
Abstract base
  ↓
Base implementation
  ↓
Adapter
  ↓
Wrapper
  ↓
Concrete implementation
```

for a trivial operation.

Use abstractions when they provide real value for testing, infrastructure replacement, business boundaries, or maintainability.

---

# 12. Preferred Project Organization

Prefer a **feature-first** structure.

A typical structure may look like:

```text
lib/
├── app/
│   ├── app.dart
│   ├── bootstrap/
│   ├── config/
│   ├── routing/
│   └── theme/
│
├── core/
│   ├── errors/
│   ├── extensions/
│   ├── services/
│   ├── storage/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── authentication/
│   ├── platform/
│   ├── dashboard/
│   ├── branches/
│   ├── employees/
│   ├── attendance/
│   ├── returns/
│   ├── reports/
│   ├── notifications/
│   └── profile/
│
└── shared/
    ├── models/
    └── widgets/
```

This is a guideline, not a requirement to create empty folders.

If the existing project already has a sensible structure, preserve and extend it rather than reorganizing everything unnecessarily.

Feature-specific code should remain inside its feature until genuine reuse justifies moving it to shared/core infrastructure.

---

# 13. Layer Responsibilities

## Presentation

Responsible for:

- Flutter widgets
- Screen composition
- UI state
- User interactions
- Responsive/adaptive layout
- Navigation events

Do not place significant business rules, Firebase queries, SQL queries, JSON parsing, or persistence decisions directly in `build()` methods.

## Domain / Business Logic

Responsible for business rules such as:

- Role permissions
- Organization restrictions
- Branch authorization
- Attendance eligibility
- Geofence validation
- Employee lifecycle rules
- Return approval rules
- Date/time rules

Where practical, business rules should be testable without rendering Flutter widgets.

## Data / Infrastructure

Responsible for:

- Repository implementations
- Mock repositories/data sources
- Firebase Authentication integration
- SQL Connect/PostgreSQL integration
- Firestore integration
- Storage uploads
- Serialization/mapping
- Local persistence/caching

Presentation should communicate through clear application contracts rather than directly querying infrastructure everywhere.

---

# 14. Typed Models

Prefer typed Dart models over large untyped maps.

Avoid excessive use of:

```dart
Map<String, dynamic>
```

outside serialization/infrastructure boundaries.

Use models/entities/DTOs when the separation provides value.
Do not create separate DTO/domain/UI models automatically for every object.

---

# 15. State Management

Use one primary state-management approach consistently.

Do not mix multiple state-management libraries without a strong reason.

Separate:

- UI state
- Application context
- Business logic
- Persistence
- Remote/mock data access

Document the selected state-management approach in `docs/architecture.md` once chosen.

---

# 16. Routing and Application Context

Use centralized, structured routing.

Avoid scattering route strings throughout widgets.

Routing must support:

- Authentication
- Protected routes
- Role-based navigation
- Platform vs customer areas
- Branch Manager branch selection
- Active branch context
- Deep links when required
- Smartphone navigation
- Tablet navigation
- Web navigation

Do not allow protected screens to become accessible merely by navigating directly to a route.

Application context should explicitly represent relevant state such as:

- Authenticated user
- Role
- Customer organization, when applicable
- Assigned branches, when applicable
- Active branch for Branch Manager workflows
- Permissions

---

# 17. Responsive and Adaptive Design

Responsive behavior is mandatory across **phone, tablet, and web**.

Do not build a desktop layout and compress it onto a phone.
Do not build a phone layout and merely stretch it onto a tablet or browser.

Use available width rather than only checking device type.

Default breakpoints unless the project establishes better centralized values:

```text
Compact:  < 600dp
Medium:   600dp – 839dp
Expanded: >= 840dp
```

For very wide browser layouts, also use sensible maximum content widths and multi-column composition where the Stitch design calls for it.

Breakpoints must be centralized.
Do not duplicate raw breakpoint numbers throughout widgets.

---

# 18. Smartphone Layout Rules

For compact widths, generally prefer:

- Compact app bars
- Bottom navigation where appropriate
- Single-column content
- Full-screen forms
- Bottom sheets
- Touch-friendly controls
- Compact cards
- Horizontal carousels only where the approved design uses them
- Minimal vertical scrolling for daily-use screens

Avoid:

- Desktop toolbars squeezed into narrow widths
- Six or more primary bottom-navigation items
- Large full-width KPI cards stacked endlessly
- Excessively verbose cards
- Tiny labels
- Dense tables

Smartphone layout must feel intentionally designed for one-handed/touch use.

---

# 19. Tablet Layout Rules

Tablet is a first-class experience.

For medium/expanded tablet widths, consider:

- Navigation rail
- Wider content areas
- Two-column compositions
- Multi-column forms
- Master-detail layouts
- Wider list rows
- Side sheets
- Multiple visible KPI tiles where appropriate

Do not simply enlarge smartphone widgets.

Tablet portrait and tablet landscape should each make meaningful use of the available width.

---

# 20. Web Layout Rules

Web is part of the same Flutter application.

For browser layouts, prefer when appropriate:

- Persistent left-side navigation
- Comfortable maximum content widths
- Multi-column dashboard composition
- Wider forms and structured lists
- Keyboard/focus accessibility
- Desktop-appropriate hover/focus states where useful

Do not duplicate an entirely separate application for web.
Use shared feature logic with adaptive composition.

Browser functionality does **not** need to match Android functionality completely.
When a capability is intentionally mobile-only or disproportionately complex on web:

- Follow the explicit product requirement for that feature.
- Do not invent unsupported browser behavior.
- Provide a clear, graceful browser state when necessary.
- Keep viewing/management functionality available when appropriate.

Do not silently omit a required web capability without reporting it.

---

# 21. Reusable Adaptive Components

Create reusable adaptive components when repetition justifies them, for example:

```text
AdaptiveScaffold
AdaptiveNavigation
ResponsivePage
ResponsiveContent
AdaptiveDialog
AdaptiveFormLayout
MasterDetailLayout
```

Do not create completely separate phone/tablet/web feature implementations when shared composition can solve the problem cleanly.

Avoid abstractions that exist only to reduce line count.

---

# 22. Material Design 3 and Theme

Use Material Design 3 consistently.

Centralize:

- Colors
- Typography
- Spacing
- Radii
- Input decoration
- Button styles
- Card treatment
- Navigation styles
- Status styling

Prefer `Theme.of(context)` and theme extensions rather than repeated hardcoded visual values.

Create focused design tokens where useful, such as:

```text
AppBreakpoints
AppSpacing
AppRadius
AppSizes
AppDurations
```

Do not scatter arbitrary spacing/color/radius values throughout the codebase.

---

# 23. Reusable Widgets

Extract genuinely reusable patterns when duplication or a stable design concept exists.

Examples may include:

- PrimaryButton
- SecondaryButton
- AppTextField
- SearchField
- StatusChip
- EmptyState
- ErrorState
- LoadingState
- OfflineBanner
- UserAvatar
- SummaryCard
- SectionHeader
- ConfirmationDialog

Do not make every tiny widget globally reusable.
Feature-specific widgets should remain inside their feature.

---

# 23A. Canonical Component & Screen Templates (Smartphone, Tablet, Desktop)

**MANDATORY RULE:** Every screen and component in this repository must use the canonical reusable templates established in `lib/core/widgets/`. Do not create ad-hoc duplicates of common UI elements.

All implementations must follow these template contracts across **Smartphone (<600dp)**, **Tablet (600dp–839dp)**, and **Desktop Web (>=840dp)**:

### 1. KPI Cards: `AppKpiCard`
- **Location**: `lib/core/widgets/kpi/app_kpi_card.dart`
- **Layout Specification**: 
  - **Top Row**: Metric title on the left (`title`).
  - **Bottom / Value Row**: Large bold metric on the left (`value`, `valueColor` for semantic alerts), and rounded 32dp icon container on the bottom right (`icon` or `customIconBox`).
  - **Clean Presentation**: Cards default to clean presentation without cluttering sub-text or extra trailing labels under numbers. Height is standardized at 96dp.
- **Rule**: Never construct custom KPI card widgets from scratch. Always instantiate `AppKpiCard`.

### 2. Responsive KPI Section: `ResponsiveKpiSection`
- **Location**: `lib/core/widgets/kpi/responsive_kpi_section.dart`
- **Default Height**: 96dp (`cardHeight = 96`).
- **Multi-Form-Factor Layout**:
  - **Smartphone (`< 600dp`)**: Full-width swipeable carousel (`PageView` with `viewportFraction: 1.0` and animated dot indicators). Cards span 100% of the content width with zero awkward margins, matching recent lists.
  - **Tablet (`600dp – 839dp`)**: Balanced 2-column grid (`Row`s of 2 `Expanded` cards) utilizing 100% width.
  - **Desktop (`>= 840dp`)**: Balanced single-row flex layout (`Row` of `Expanded` cards) spanning 100% width.
- **Rule**: Never hand-roll custom carousels or manual row splits for KPI collections. Use `ResponsiveKpiSection(cards: [...])`.

### 3. Action Buttons: `AppButton`
- **Location**: `lib/core/widgets/app_button.dart`
- **Variants**:
  - `AppButton.primary(...)`: Main call to action with filled primary background.
  - `AppButton.secondary(...)`: Secondary tonal button (`AppColors.primaryContainer`).
  - `AppButton.outlined(...)`: Outlined subtle button with border.
  - `AppButton.responsive(...)`: Automatically adapts width: full-width on smartphone (`isCompact`), intrinsic width on tablet and desktop.
- **Rules**:
  - Minimum 48dp touch target across all form factors.
  - Built-in loading state with progress indicator via `isLoading: true`.
  - Container-safe: Automatically detects unbounded horizontal constraints (such as inside a `Row`) via `LayoutBuilder` to prevent layout overflow exceptions.

### 4. Text & Password Inputs: `AppTextField` & `AppPasswordField`
- **Location**: `lib/core/widgets/app_text_field.dart`
- **Templates**:
  - `AppTextField`: Standard M3 outlined field with structured label, hint, helper text, and error states.
  - `AppTextField.search(...)`: Standard search field with leading magnifying glass and optional clear button.
  - `AppPasswordField(...)`: Standard password field with integrated obscure text toggle and lock icon prefix.
- **Rule**: Never manage manual visibility state or raw `TextField` decorations in screen files.

### 5. Page Headers: `AppPageHeader`
- **Location**: `lib/core/widgets/app_page_header.dart`
- **Layout Specification**:
  - **Eyebrow Tag**: Uppercase category tracking (11px bold, letter-spacing 1.2px, `AppColors.secondary`).
  - **Title**: Scaled typography (24px bold on smartphone, 32px bold on tablet and desktop).
  - **Subtitle**: Supporting description in `AppColors.onSurfaceVariant`.
  - **Action Placement**: Inline on the right for tablet/desktop; stacked full-width below the header on smartphone for touch ergonomics.
- **Rule**: Use `AppPageHeader` for all screen headers across all dashboards and management views.

---

# 24. Forms and Validation

Large forms must be split into logical sections.

Separate where appropriate:

- Form UI
- Form state
- Validation
- Submission
- Mapping

Do not create one huge form widget containing dozens of unrelated fields.

Create reusable validation only where there is genuine repetition.
Business-specific validation belongs near the feature that owns it.

Validation errors must preserve user-entered data and be understandable to end users.

---

# 25. Authorization and Scoping

UI visibility is not a security boundary.

Authorization must be enforced at appropriate application and backend/data boundaries.

## Customer organization scoping

Organization Admins, Branch Managers, and Employees belong to exactly one customer organization.
Do not build customer organization switching for these roles.

## Branch Manager scoping

Branch Managers may access only assigned branches.

If assigned to multiple branches:

- Require/select an active branch context before branch-scoped operations.
- Scope queries to the active authorized branch where the screen is branch-specific.
- Allow changing branch only to another branch in the manager's assigned set.
- Clear branch-scoped state when active branch changes.

Do not fetch all organization data and merely hide unauthorized rows when data can be scoped earlier.

## Employee scoping

Employees should access only their own permitted self-service data and operations unless a future requirement explicitly expands their scope.

---

# 26. Errors and User-Facing States

Implement a consistent error-handling approach.

Differentiate where useful between:

- Validation errors
- Network errors
- Authentication errors
- Authorization errors
- Timeout errors
- Backend failures
- Offline state
- Unexpected errors

Do not expose raw Firebase, SQL, Firestore, stack-trace, or technical backend errors directly to users.

Do not silently swallow exceptions.
Do not use `print(error)` as the application error-handling strategy.

Every asynchronous screen should consider relevant states such as:

- Initial loading
- Refreshing
- Data loaded
- Empty
- Error
- Offline
- Partial failure

Mock implementations should make these states testable during UI development.

---

# 27. Date and Time

Business-critical timestamps must not blindly trust the device clock.

Use server-confirmed timestamps where required once the real backend is connected.

Keep separate concerns for:

- Storage format
- Business timezone
- Display formatting

Avoid scattering date/time formatting logic throughout widgets.

---

# 28. GPS and Location

Keep location logic separate from UI rendering.

Where geofencing is required, isolate:

- Permission handling
- GPS acquisition
- Distance calculation
- Accuracy validation
- Branch coordinates
- Radius rules

Distance calculations should be independently testable.
Do not embed complex geolocation calculations directly in UI callbacks.

For mock-first UI work, use mock location states rather than prematurely integrating device APIs unless requested.

---

# 29. Images and Documents

Keep image/file upload handling separate from presentation.

Support states such as:

- Selecting
- Capturing
- Compressing
- Uploading
- Uploaded
- Failed
- Retrying

Do not keep large image bytes unnecessarily in long-lived state.
Do not expose raw backend storage URLs for sensitive documents unnecessarily.

During mock-first UI work, use local/mock assets and mock upload states unless real integration is requested.

---

# 30. Security

Never commit:

- Passwords
- API secrets
- Service-account credentials
- Private keys
- Production tokens

Do not log:

- Passwords
- Authentication tokens
- Sensitive personal identifiers
- Sensitive documents

Use the principle of least privilege.

Environment-specific configuration must not require manually editing application source code for every environment.

---

# 31. Dependencies

Do not add a package simply because it makes a small task slightly easier.

Before adding a dependency, consider:

- Is it maintained?
- Is it necessary?
- Does Flutter/Dart already provide the capability?
- Does it conflict with existing architecture?
- Does it add meaningful size/maintenance burden?

Do not add multiple packages solving the same problem.
Document significant dependency decisions in `docs/architecture.md`.

---

# 32. Performance

Write efficient Flutter code without premature optimization.

Prefer:

- Lazy lists
- Pagination when needed
- Efficient image loading
- Appropriate caching
- `const` constructors where useful
- Selective rebuilds
- Avoiding unnecessary rebuilds

Measure before performing complex optimization.

For dashboards with horizontally scrolling cards/tiles, use lazy/efficient list primitives rather than rendering large off-screen trees unnecessarily.

---

# 33. Accessibility

Accessibility is part of implementation quality.

Consider:

- Minimum touch targets
- Semantic labels
- Screen readers
- Large text
- Logical focus order
- Sufficient contrast
- Keyboard navigation on web/tablets where useful
- Hover/focus affordances on web where relevant

Never rely only on color to communicate important status.
Do not disable text scaling simply to preserve visual appearance.

---

# 34. Testing

Architecture must make important behavior testable.

Prioritize tests for:

- Business rules
- Validation
- Permissions
- Role routing
- Branch authorization/context selection
- Data mapping
- Repository contracts
- Geofence calculations
- Attendance rules
- Critical state transitions
- Important reusable widgets

For mock-first implementation, test presentation against mock repository states where it provides meaningful protection.

When fixing a reproducible bug, add a regression test when practical.

Avoid testing trivial framework behavior.

---

# 35. Analyzer, Formatting, and Validation

After implementation, run:

```bash
dart format .
flutter analyze
flutter test
```

For changes materially affecting web behavior, also run an appropriate web build/check when practical, for example:

```bash
flutter build web
```

Do not claim commands passed unless they were actually run.
Fix warnings rather than blindly suppressing analyzer rules.

---

# 36. Naming, Imports, Utilities, and Constants

Use descriptive names such as:

```text
EmployeeRepository
AttendanceController
BranchDetailsPage
ReturnRequestCard
AttendanceStatus
LocationService
```

Avoid vague names such as:

```text
Manager
Helper
Utils2
DataClass
TempService
NewPage
MyWidget
CommonThing
```

Keep imports clean and remove unused/duplicate imports.

Do not create giant miscellaneous files such as:

```text
utils.dart
helpers.dart
common.dart
```

with unrelated responsibilities.

Prefer focused utilities such as:

```text
date_extensions.dart
phone_validator.dart
distance_calculator.dart
```

Do not create one giant constants file for the whole application.
Shared constants should be centralized only when genuinely shared; feature-specific constants belong with the feature.

---

# 37. Documentation

Maintain:

```text
README.md
docs/architecture.md
```

when appropriate.

`docs/architecture.md` should describe **actual** decisions such as:

- State management
- Routing
- Dependency injection, if any
- Mock/real repository strategy
- Firebase Authentication approach
- SQL Connect/PostgreSQL integration
- Firestore integration
- Storage integration
- Responsive/adaptive strategy
- Role and branch context
- Environment configuration

Do not document aspirational architecture that the code does not follow.

Before significant architectural changes:

1. Inspect the current architecture.
2. Read `docs/architecture.md`.
3. Explain why the current approach is insufficient.
4. Describe the proposed change.
5. Avoid introducing competing patterns.
6. Update the architecture documentation afterward.

---

# 38. Preserve Working Code

When modifying an existing feature:

- Make the smallest reasonable change.
- Reuse established components.
- Preserve existing behavior unless the requirement changes it.
- Do not rewrite unrelated modules.
- Do not perform large opportunistic refactors without reason.

Refactor when it directly improves the code touched by the task.
Avoid unrelated scope expansion.

---

# 39. Implementation Workflow

For every implementation request:

## Step 1 — Inspect

Inspect:

- Relevant files
- Current architecture
- Dependencies
- Existing reusable components
- Relevant Stitch design/reference
- Existing tests

Do not assume project structure or implementation state.

## Step 2 — Understand

Determine:

- What must change
- Which feature owns the change
- Which components can be reused
- Role/permission implications
- Organization/branch implications
- Smartphone behavior
- Tablet behavior
- Web behavior
- Whether the task is mock-only or real-backend integration

## Step 3 — Plan

Before a significant implementation, briefly state:

- Files to create
- Files to modify
- Architectural approach
- Dependencies to add, if any
- Mock/repository approach
- Important assumptions

Keep the plan concise.

## Step 4 — Implement

Implement the smallest clean solution that completely satisfies the requirement.

Follow existing conventions.
Split responsibilities appropriately.
Do not create monolithic files.

## Step 5 — Review

Before considering the task complete, review:

- Stitch fidelity
- Smartphone layout
- Tablet portrait layout
- Tablet landscape layout
- Web layout
- Loading state
- Empty state
- Error state
- Permissions
- Organization/branch scoping
- Accessibility
- Duplicate code
- Oversized files/classes

Refactor where necessary.

## Step 6 — Validate

Run:

```bash
dart format .
flutter analyze
flutter test
```

Run additional relevant checks when applicable.
Report failures rather than pretending they succeeded.

---

# 40. Definition of Done

A task is not complete merely because the happy path visually works.

Where relevant, completion includes:

- Correct implementation
- Fidelity to the approved Stitch design
- Smartphone support
- Tablet portrait support
- Tablet landscape support
- Web support for the required capability
- Responsive/adaptive behavior
- Clear architecture
- Separation of concerns
- Appropriate mock or real repository integration
- Loading behavior
- Empty behavior
- Error behavior
- Permission handling
- Organization/branch scoping
- Basic accessibility
- Analyzer passing
- Relevant tests passing
- No unnecessary duplication
- No newly introduced monolithic files

---

# 41. Final Rule

Never use:

> "Put everything in one file and make it work."

as the implementation strategy.

When a feature grows, organize it.
When responsibilities differ, separate them.
When code repeats, evaluate whether it should be reused.
When architecture becomes difficult to understand, simplify it.
When tablet or web space is available, use it intentionally.
When phone space is limited, simplify rather than compress.
When requirements are simple, keep the solution simple.

Build the project so future features can be added without turning the repository into a collection of giant, tightly coupled files.

**Android smartphone, Android tablet, and web support are all part of this Flutter application.**

**SOLID, clean architecture, separation of concerns, maintainability, testability, and pragmatic simplicity must be preserved throughout implementation.**
