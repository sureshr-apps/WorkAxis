# Remediation of the 2026-11-07 Code Review

The fixes for [code-review-2026-11-07.md](code-review-2026-11-07.md) were done in three waves by Sonnet sub-agents with disjoint file ownership. The lead reviewer reviewed and re-verified each wave before the next one started.

## Validation (final state)

| Check | Result |
|---|---|
| `dart format lib test` | clean |
| `flutter analyze` | No issues found |
| `flutter test` | 751 / 751 passed (baseline was 210) |
| `flutter build web` | built |
| `npm --prefix functions test` | 28 / 28 passed |
| Firestore rules suite (emulator) | 21 / 21 passed |
| `firebase dataconnect:compile` | passed; Dart SDK regenerated |

Nothing has been deployed or committed.

## What changed, by wave

**Wave 1A: server authorization**
- SQL Connect:
  - Every operation is gated by `@auth(expr)` on custom claims (`role`, `organizationId`, `branchIds`, `status == 'active'`), with `@check` lookups for branch scope.
  - Identity writes are `NO_ACCESS`.
  - New paged, aggregate and scoped operations.
- Firestore rules: deny-by-default. `user_aliases` and `users` cannot be written by clients. Attendance and review writes require `request.time`.
- New Cloud Functions (`functions/`, asia-south1): `provisionUser`, `updateUserAccount`, `resetUserPassword`, `setUserStatus`, `setOrganizationStatus`, `resolveLoginIdentifier`, `recordAttendancePunch` and `createKioskPairingToken`.
  - The authorization matrix is unit-tested.
  - Cross-store writes follow a set order, with compensation and an idempotent `requestId`.
- Schema: `OrganizationMember.authUid` (SQL is authoritative for identity), uniqueness constraints, and the missing return columns.
- Documentation: `docs/backend-api.md`.

**Wave 1B: Dart foundation**
- `mapBackendError` / `userMessageFor` with typed exceptions.
- `SessionController`: a single sign-out path that resets every session-scoped controller. Changing the branch resets branch-scoped controllers.
- Stale-response guards (`RequestGeneration`) on every controller.
- Router: `resolveRedirect` gates Branch Managers without a branch, plus splash, no-branch and error routes. Session restore via `AuthController.init()`.
- Auth fixes: the mock universal password is removed, a release guard rejects mock mode, demo credentials show only in mock debug builds, and password change is real.
- `WorkAxisApp(repositories:)`.
- Core widget fixes (AppButton loading, KPI min-height and text scaling, AppTextField, ErrorBanner accessibility), and the shell split into focused widgets.
- New shared pieces: tokens, `AppFormatters` and `Clock`.

**Wave 2: data layer**
- `AccessResolver` is shared by mock and real.
  - Assignments come from `ListMyBranchAssignments`.
  - Suspended orgs and inactive members are denied.
  - The `org-acme` literals are removed.
- Accounts, org admins and platform admins go through the callables.
- `getOrganizationById` cast fixed. All organization form fields are persisted.
- Branches: create and update, nullable geofence, `BranchGeofenceValidator`, server kiosk tokens.
- Dashboards and reports are scoped by `UserAccessContext`, with no fabricated metrics.
- Check-in goes only through `recordAttendancePunch`. The simulator is mock- and debug-only.
- Returns: scoped, the reviewer is set server-side, and field mapping is fixed. Settings has a repository and controller.
- Contract test suites run every repository contract against both the mock and the real implementation with fakes.

**Wave 3: screens and leftovers**
- Edit is shown only when allowed (`OrganizationMemberPolicy.canManage`).
- All fabricated UI data is removed or shown as "coming soon".
- Every action failure is surfaced, and dialogs close only on success.
- Edit Organization: `PopScope` unsaved-changes guard and the tax ID field.
- Search fields are seeded from the controller.
- Lazy sliver lists with "Load more".
- Large files split. The largest hand-written file went from 1,122 to 595 lines.
- Design-system pass:
  - Raw buttons 143 → about 9 tap-target wrappers.
  - Hex colours about 300 → decorative palettes only.
  - `fontSize` about 460 → 10 mono overrides.
- Backend leftovers:
  - Settings rules.
  - `ListReturnsByOrgPaged`.
  - Period-scoped return aggregates, including per-reason counts.
  - `geolocator` behind a `DeviceLocationGateway` interface, with Android and iOS permissions.
  - Firestore indexes.

**Lead-reviewer fixes**
- `AppButton` now applies its width policy through an intrinsic-safe render object, not a `LayoutBuilder`. It works inside `AlertDialog` actions and unbounded rows, with a regression test.
- Added an `AppButton.destructive` variant, used for the suspend confirmations.

## Open items, not done

1. **Deployment.** Functions, rules, indexes and the Data Connect schema still need deploying. Steps are in `docs/backend-api.md`.
   - The first Platform Owner has to be bootstrapped manually.
   - Seed members need `authUid` linked.
2. **Not verified at runtime.** The raw GraphQL in `functions/src/sql/*`, and the assumption that an omitted optional filter means "skip". The Data Connect emulator was not run.
3. **Product decision.** Should `/platform/settings` be Platform Owner only? Today it is reachable by Platform Administrators, and the routing is unchanged.
4. **Partial.**
   - Branch lists are not paginated (no paged branch query).
   - Attendance has no pagination.
   - The desktop platform-users table and the tablet recent-organizations `Wrap` build every loaded row.
   - `organization_overview_tab.dart` (595 lines) is not split.
5. **Not implemented.**
   - Kiosk token redemption.
   - Removing an org admin (no callable exists).
   - Preserving a deep link across session restore.
   - Assigning several managers to a branch is not atomic.
6. **Kept on purpose.** Decorative colour palettes remain in the sign-in hero panel, the platform hero banner and the geofence map painter.
