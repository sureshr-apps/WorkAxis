## Purpose

This file defines the permanent engineering, architecture, and code-quality rules for this repository.
These instructions apply to **every implementation task in this project**.
Treat these rules as **non-negotiable engineering constraints**, not optional recommendations.

Before implementing or modifying any feature:

1. Read this file.
2. Inspect the existing repository structure.
3. Review existing architecture and reusable components.
4. Read `docs/architecture.md` if it exists.
5. Understand the requested change before writing code.
6. Preserve established project conventions unless there is a strong reason to improve them.

Do not optimize for the fastest possible implementation.

Optimize for:

* Correctness
* Simplicity
* Maintainability
* Testability
* Readability
* Extensibility
* Consistency

---

# 1. Technology

This project is a **Flutter application**.

The application must treat the following as first-class targets:

* Android smartphones
* Android tablets
* Smartphone portrait
* Smartphone landscape
* Tablet portrait
* Tablet landscape

Do not build a phone-only application and stretch it onto tablets.

The UI must use adaptive and responsive layouts appropriate for the available screen size.

Use **Material Design 3** unless explicitly instructed otherwise.

---

# 2. Core Engineering Principles

All implementation must follow the principles below.

## SOLID

Apply SOLID principles pragmatically:

### Single Responsibility Principle

A class, widget, service, repository, controller, or file should have one clear responsibility.

Do not combine unrelated responsibilities simply because placing everything in one file is convenient.

### Open/Closed Principle

Prefer designs that can be extended without repeatedly rewriting stable code.

Do not introduce unnecessary abstraction solely for hypothetical future requirements.

### Liskov Substitution Principle

Implement abstractions consistently.

Do not create inheritance hierarchies where implementations violate the expectations of their parent abstractions.

### Interface Segregation Principle

Prefer small and focused contracts.

Do not create enormous interfaces containing unrelated methods.

### Dependency Inversion Principle

High-level business logic should not depend directly on low-level infrastructure details.

Where appropriate, depend on abstractions rather than Firebase, storage, networking, or platform-specific implementations directly.

---

# 3. Clean Code

Code must be easy for another developer to understand.

Prefer:

* Clear names
* Small cohesive functions
* Focused classes
* Explicit behavior
* Predictable control flow
* Minimal side effects
* Consistent conventions

Avoid:

* Code that is difficult to understand
* Deep nesting
* Massive functions
* Hidden side effects
* Ambiguous naming
* Duplicate logic
* Dead code
* Commented-out code
* Temporary hacks left permanently in production code

Code should explain **what it does** through naming and structure.

Comments should primarily explain **why** something exists when that reason is not obvious.

---

# 4. DRY, KISS, and YAGNI

Follow:

* DRY — Don't Repeat Yourself
* KISS — Keep It Simple
* YAGNI — You Aren't Gonna Need It

However, apply these principles pragmatically.

Do not create a reusable abstraction after seeing one trivial example.

Do refactor when:

* Logic is duplicated
* A clear reusable concept exists
* Responsibilities have become mixed
* A component is becoming difficult to understand

Avoid speculative architecture for requirements that do not exist.

---

# 5. Never Create Monolithic Files

This rule is extremely important.

Do **not** implement entire features inside one enormous Dart file.

Do not put all of the following together:

* UI
* business logic
* database access
* validation
* networking
* state management
* models
* mapping
* navigation

A screen becoming large is a signal to review its responsibilities.

Split code whenever doing so improves cohesion and readability.

Examples of appropriate extraction:

* Page
* Screen section
* Reusable widget
* Form section
* Controller
* State object
* Repository
* Service
* Data source
* Model
* DTO
* Mapper
* Validator
* Extension
* Utility

Do not keep adding code to an existing file simply because that file already exists.

If a file becomes difficult to navigate or understand:

**stop and refactor it before continuing.**

There is no goal to minimize the number of files.

The goal is to create files with clear responsibilities.

---

# 6. Avoid the Opposite Extreme

Splitting code does not mean creating unnecessary complexity.

Do not create excessive layers such as:

```text
Interface
  ↓
Abstract Base Class
  ↓
Base Implementation
  ↓
Adapter
  ↓
Wrapper
  ↓
Concrete Implementation
```

for a simple requirement.

Use abstractions when they provide real value.

Architecture must make development easier, not harder.

---

# 7. Preferred Project Organization

Prefer a **feature-first structure**.

A typical project may look like:

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
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
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

This structure is a guideline, not a requirement to create empty folders.

Create directories only when they contain meaningful responsibilities.

If the project already has a good structure, preserve and extend it rather than reorganizing everything unnecessarily.

---

# 8. Feature Ownership

Feature-specific code should normally stay inside its feature.

Example:

```text
features/
└── attendance/
    ├── data/
    ├── domain/
    └── presentation/
```

Do not move code into `core` or `shared` merely because it might possibly be reused someday.

Move something to shared infrastructure when it is genuinely used across features.

---

# 9. Presentation Layer

Flutter widgets belong to the presentation layer.

Presentation should primarily handle:

* Rendering state
* User interactions
* Navigation
* Responsive composition
* UI-specific state

Do not place significant business logic inside:

```dart
build()
```

Do not make screens directly responsible for:

* database implementation
* Firebase queries
* JSON parsing
* complicated business rules
* persistence decisions

Prefer:

```text
Widget
    ↓
Controller / State
    ↓
Repository
    ↓
Data Source / Service
```

Use this structure pragmatically.

---

# 10. Business Logic

Business rules should be separated from visual widgets.

Examples include:

* Attendance eligibility
* Geofence validation
* Employee lifecycle rules
* Return approval rules
* Role permissions
* Organization restrictions
* Date/time validation

Where possible, these rules should be testable without rendering Flutter widgets.

---

# 11. Data Layer

Keep infrastructure-specific implementation behind appropriate data abstractions.

For Firebase-backed functionality, prefer:

```text
Presentation
    ↓
State / Controller
    ↓
Repository
    ↓
Firebase implementation
```

Do not query Firebase directly from unrelated UI widgets throughout the application.

Keep:

* Serialization
* Persistence
* Remote queries
* Upload logic
* Cache behavior

out of presentation code where practical.

---

# 12. Typed Models

Prefer typed Dart models instead of passing large untyped maps throughout the project.

Avoid excessive use of:

```dart
Map<String, dynamic>
```

outside infrastructure boundaries.

Use clearly named:

* Models
* Entities
* DTOs

when appropriate.

Do not create separate DTO/domain/UI models unless the separation provides actual value.

---

# 13. State Management

Use **one primary state-management approach consistently** throughout the application.

Do not mix multiple state-management libraries without a strong architectural reason.

State-management code should remain separate from UI rendering where appropriate.

Differentiate between:

* UI state
* application state
* business logic
* persistence
* remote data access

Do not introduce a state-management dependency without documenting why it was chosen.

Record important architectural choices in:

```text
docs/architecture.md
```

---

# 14. Routing

Use centralized and structured application routing.

Avoid scattering route strings throughout widgets.

Routing must be capable of supporting:

* Authentication
* Protected screens
* Role-based access
* Organization context
* Deep links where required
* Smartphone navigation
* Tablet navigation

Navigation architecture should adapt to device width without duplicating business screens.

---

# 15. Responsive and Adaptive Design

Responsive behavior is mandatory.

Use available width rather than relying only on device type.

Use these default breakpoints unless the project establishes better ones:

```text
Compact
< 600dp

Medium
600dp – 839dp

Expanded
>= 840dp
```

These values should be centralized.

Do not duplicate breakpoint values throughout individual widgets.

---

# 16. Compact Layouts

For compact widths, generally prefer:

* Bottom navigation
* Single-column content
* Full-screen forms
* Bottom sheets
* Vertical lists
* Touch-friendly controls
* Appropriate use of sticky actions

Do not overcrowd phone interfaces.

---

# 17. Medium Layouts

For medium widths, consider:

* Navigation rail
* Wider content areas
* Two-column forms where useful
* Expanded list rows
* Side sheets
* Better use of horizontal space

Do not simply scale phone widgets larger.

---

# 18. Expanded Layouts

For expanded widths, consider:

* Navigation rail
* Permanent navigation
* Master-detail layouts
* Two-pane workflows
* Multi-column forms
* Persistent detail panels
* Wider structured lists

A tablet should feel intentionally designed for a tablet.

Do not display a narrow phone screen in the center of a large tablet unless the content genuinely requires a narrow maximum width.

---

# 19. Reusable Adaptive Components

Create reusable adaptive components where repetition justifies them.

Examples may include:

```text
AdaptiveScaffold
AdaptiveNavigation
AdaptivePage
AdaptiveDialog
AdaptiveForm
MasterDetailLayout
ResponsiveContent
```

Do not create separate copies such as:

```text
EmployeePhonePage
EmployeeTabletPage
```

when a shared adaptive screen can compose different layouts cleanly.

Prefer shared feature logic with adaptive presentation.

---

# 20. Material Design 3

Use Material Design 3 consistently.

Centralize application styling.

The theme should own decisions such as:

* Colors
* Typography
* Input decoration
* Buttons
* Cards
* Navigation
* Dialogs
* Status presentation

Prefer:

```dart
Theme.of(context)
```

and theme extensions rather than repeated hardcoded styling.

---

# 21. Design Tokens

Centralize reusable design values when useful.

Examples:

```text
AppBreakpoints
AppSpacing
AppRadius
AppSizes
AppDurations
```

Avoid arbitrary values scattered throughout the codebase.

Prefer a consistent spacing system.

---

# 22. Reusable Widgets

Extract genuinely reusable UI patterns.

Examples:

* PrimaryButton
* SecondaryButton
* AppTextField
* SearchField
* StatusChip
* EmptyState
* ErrorState
* LoadingState
* OfflineBanner
* UserAvatar
* SummaryCard
* SectionHeader
* ConfirmationDialog

Do not turn every small widget into a global reusable abstraction.

Feature-specific widgets should stay inside their feature.

---

# 23. Forms

Large forms must be split into logical sections.

Do not create one huge form widget containing dozens of fields.

For example:

```text
EmployeeForm
├── PersonalInformationSection
├── EmploymentInformationSection
├── AddressSection
├── EmergencyContactSection
└── DocumentsSection
```

Separate where appropriate:

* Form state
* Validation
* UI
* Submission
* Mapping

Form data must not be lost because of simple validation failures.

---

# 24. Validation

Create reusable validation logic where there is genuine repetition.

Examples:

* Required values
* Phone numbers
* Numeric ranges
* Dates
* IDs
* Email addresses

Business-specific validation should remain close to the feature that owns it.

Validation messages must be understandable to users.

---

# 25. Roles and Authorization

The application contains roles such as:

```text
Organization Admin
Branch Manager
Employee
```

Role restrictions must not be implemented only by hiding buttons.

Authorization must be enforced at appropriate application and backend boundaries.

UI behavior should reflect permissions, but UI visibility is not security.

---

# 26. Organization Scoping

Application data may belong to a specific organization.

Never accidentally mix data between organizations.

Organization-scoped queries, state, and caches must use the active organization context.

When switching organization context:

* Clear inappropriate cached state
* Reload permissions
* Reload role context
* Reload branch context
* Refresh organization-scoped data

Never display cached information belonging to a previously selected organization.

---

# 27. Branch Scoping

Branch-restricted roles must never receive data belonging to unauthorized branches.

Do not fetch all organization data and merely hide unauthorized rows in the UI when the backend can scope the query correctly.

Security boundaries should exist as close to the data source as practical.

---

# 28. Errors

Implement a consistent error-handling approach.

Differentiate where useful between:

* Validation errors
* Network errors
* Authentication errors
* Authorization errors
* Timeout errors
* Backend failures
* Offline state
* Unexpected errors

Do not expose internal stack traces or technical backend messages directly to users.

Do not silently swallow exceptions.

Avoid relying on:

```dart
print(error);
```

as an error-handling strategy.

Use proper application logging where required.

---

# 29. Loading, Empty, and Error States

Every asynchronous screen should consider:

* Initial loading
* Refreshing
* Data loaded
* Empty state
* Error state
* Offline state
* Partial failure where applicable

Do not leave users looking at blank screens.

Use shared components when states are common across features.

---

# 30. Date and Time

Business-critical dates and timestamps should not blindly trust the device clock.

Use server-confirmed timestamps where required by business rules.

Keep:

* Storage format
* Business timezone
* Display formatting

as separate concerns.

Avoid spreading date formatting logic throughout widgets.

---

# 31. GPS and Location

Keep location logic separate from UI rendering.

Where geofencing is required, isolate:

* GPS acquisition
* Permission handling
* Distance calculation
* Accuracy validation
* Branch coordinates
* Radius rules

Distance calculations should be independently testable.

Do not embed complex geolocation mathematics directly in button callbacks.

---

# 32. Images and Documents

Keep upload and file-handling logic separated from presentation.

Support appropriate states such as:

* Selecting
* Capturing
* Compressing
* Uploading
* Uploaded
* Failed
* Retrying

Avoid unnecessarily holding large image byte arrays in long-lived application state.

Sensitive documents must not expose raw backend storage URLs unnecessarily.

---

# 33. Security

Never commit:

* Passwords
* API secrets
* Service-account credentials
* Private keys
* Production tokens

Use environment-specific configuration.

Do not log sensitive values.

Sensitive data should be displayed only to authorized roles.

Use the principle of least privilege.

---

# 34. Environment Configuration

Support separate environments where appropriate, for example:

```text
development
staging
production
```

Environment-specific configuration must not require editing source code manually for each build.

Do not commit secrets in environment files that are intended to remain private.

---

# 35. Dependencies

Do not add a package simply because it makes a small task slightly easier.

Before adding a dependency, consider:

* Is it actively maintained?
* Is it actually necessary?
* Does Flutter/Dart already provide the capability?
* What long-term maintenance burden does it introduce?
* Does it significantly increase application size?
* Does it conflict with existing architecture?

When adding a meaningful dependency, document the reason.

Do not introduce multiple libraries solving the same problem.

---

# 36. Performance

Write efficient Flutter code without premature optimization.

Prefer:

* Lazy lists
* Pagination where appropriate
* Efficient image loading
* Appropriate caching
* `const` constructors where useful
* Selective rebuilds
* Avoiding unnecessary rebuilds

Do not sacrifice clarity for insignificant micro-optimizations.

Measure before performing complex optimization.

---

# 37. Accessibility

Accessibility is part of implementation quality.

Consider:

* Minimum touch target sizes
* Semantic labels
* Screen readers
* Large text
* Logical focus order
* Sufficient contrast
* Keyboard navigation on tablets where applicable

Never rely only on color to communicate important status.

---

# 38. Testing

Architecture must make important behavior testable.

Write tests where they provide meaningful protection.

Prioritize testing for:

* Business rules
* Validation
* Permissions
* Data mapping
* Repositories
* Geofence calculations
* Attendance rules
* Critical state transitions
* Important reusable widgets

Avoid testing trivial framework behavior.

When fixing a reproducible bug, add a regression test when practical.

---

# 39. Flutter Analyzer

Maintain a clean analyzer result.

After implementation, run:

```bash
dart format .
flutter analyze
```

Run relevant tests:

```bash
flutter test
```

Do not claim the project is clean if these commands were not actually run.

Fix warnings instead of blindly suppressing them.

Do not disable analyzer rules simply to remove warnings unless there is a documented reason.

---

# 40. Imports

Keep imports clean.

Remove:

* Unused imports
* Duplicate imports
* Unnecessary barrel dependencies that create coupling

Follow established project import conventions consistently.

---

# 41. Naming

Use descriptive names.

Good examples:

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

A developer should understand the purpose of a class from its name.

---

# 42. Utilities

Do not create giant miscellaneous files such as:

```text
utils.dart
helpers.dart
common.dart
```

containing unrelated functions.

Prefer focused utilities such as:

```text
date_extensions.dart
phone_validator.dart
distance_calculator.dart
currency_formatter.dart
```

Feature-specific utilities should stay inside the feature.

---

# 43. Constants

Do not create one giant global constants file for the entire application.

Shared constants should be centralized only when genuinely shared.

Feature-specific constants belong with their feature.

Avoid hardcoded:

* Route names
* Storage keys
* Role names
* Breakpoints
* Backend collection names
* Important numeric limits

when they represent application-level concepts.

---

# 44. Documentation

Maintain:

```text
README.md
docs/architecture.md
```

where appropriate.

`docs/architecture.md` should describe actual architectural decisions such as:

* State-management solution
* Routing solution
* Backend integration approach
* Folder structure
* Responsive strategy
* Authentication architecture
* Environment setup
* Significant design decisions

Do not fill documentation with aspirational architecture that the code does not actually follow.

Documentation must reflect reality.

---

# 45. Architectural Changes

Before making a significant architectural change:

1. Inspect the existing architecture.
2. Read `docs/architecture.md`.
3. Explain why the existing approach is insufficient.
4. Describe the proposed change.
5. Avoid introducing competing patterns.
6. Update architecture documentation after the change.

Do not replace working architecture merely because another library or pattern is personally preferred.

---

# 46. Preserve Working Code

When modifying an existing feature:

* Make the smallest reasonable change.
* Reuse established components.
* Preserve existing behavior unless the requirement changes it.
* Do not rewrite unrelated modules.
* Do not perform large opportunistic refactors without reason.

Refactoring is encouraged when it directly improves the code affected by the task.

Avoid unrelated scope expansion.

---

# 47. Implementation Workflow

For every implementation request, follow this process.

## Step 1 — Inspect

Inspect:

* Relevant files
* Current architecture
* Dependencies
* Existing reusable components
* Existing tests

Do not assume the project structure.

---

## Step 2 — Understand

Determine:

* What must change
* Which feature owns the change
* Which existing components can be reused
* Whether the requirement affects mobile, tablet, or both
* Role and permission implications
* Data/backend implications

---

## Step 3 — Plan

Before a significant implementation, briefly state:

* Files to create
* Files to modify
* Architectural approach
* Dependencies to add, if any
* Important assumptions

Keep the plan concise.

Do not spend excessive time documenting trivial changes.

---

## Step 4 — Implement

Implement the smallest clean solution that completely satisfies the requirement.

Follow existing conventions.

Split responsibilities appropriately.

Do not create monolithic files.

---

## Step 5 — Review

Before considering the task complete, review:

* Mobile layout
* Tablet layout
* Portrait behavior
* Landscape behavior
* Loading state
* Empty state
* Error state
* Permissions
* Organization/branch scoping
* Accessibility
* Duplicate code
* Oversized files/classes

Refactor where necessary.

---

## Step 6 — Validate

Run:

```bash
dart format .
flutter analyze
flutter test
```

Run additional relevant tests when applicable.

Report failures rather than pretending they succeeded.

---

# 48. Definition of Done

A task is not complete merely because the happy path visually works.

Where relevant, completion includes:

* Correct implementation
* Mobile support
* Tablet support
* Responsive behavior
* Clear architecture
* Appropriate separation of concerns
* Loading behavior
* Empty behavior
* Error behavior
* Permission handling
* Backend/data scoping
* Basic accessibility
* Analyzer passing
* Relevant tests passing
* No unnecessary duplication
* No newly introduced monolithic files

---

# 49. Final Rule

Never use:

> "Put everything in one file and make it work."

as the implementation strategy.

When a feature grows, organize it.

When responsibilities differ, separate them.

When code repeats, evaluate whether it should be reused.

When architecture becomes difficult to understand, simplify it.

When tablet space is available, use it intentionally.

When requirements are simple, keep the solution simple.

Build the project so that future features can be added without turning the repository into a collection of giant, tightly coupled files.

**Smartphone and tablet support are both mandatory throughout the project.**

**SOLID, clean architecture, separation of concerns, maintainability, and pragmatic simplicity must be preserved throughout implementation.**
