# WorkAxis: full project handoff

Status as of 19 November 2026. This document is meant to let a new chat pick up the whole project. It supersedes `HANDOFF.md` sections 1 to 4, which are out of date (they still describe Data Connect, 820 tests, and the old `omniretail-60c71` hosting). `HANDOFF.md` section "2026-11-15" is still accurate. The Play-only details are in [play-store-handoff.md](play-store-handoff.md).

Sections: [Summary](#1-summary) · [Product and roles](#2-product-and-roles) · [Architecture](#3-architecture) · [Feature status](#4-feature-status) · [Completed](#5-completed) · [Pending](#6-pending) · [Known gaps](#7-known-gaps) · [Decisions](#8-decisions-log) · [Engineering rules](#9-engineering-rules) · [Environment](#10-environment-and-tooling) · [Deployment](#11-deployment-and-release) · [Secrets](#12-secrets-and-private-data) · [Resume checklist](#13-resume-checklist)

---

## 1. Summary

WorkAxis is one Flutter application for Android phones and tablets and for web browsers. It serves five roles from one codebase: platform owner, platform administrator, organization admin, branch manager, and employee. Each organization's staff use it for attendance (check-in and check-out, breaks, group attendance), branch and employee management, expense returns with bill photos, and operational reports.

The app runs against a real Firebase backend (`BACKEND_MODE=firebase`), or against in-memory mock repositories (the default `BACKEND_MODE=mock`) for UI work and tests.

**Where it stands:**
- Firebase backend is live in project `workaxis-app`. Cloud Functions run in `asia-south1`.
- Web app and privacy pages are deployed at https://workaxis-app.web.app.
- The Android release bundle is built and signed with the upload key. It is submitted to a Google Play closed-testing track, awaiting Google's review.
- Code quality: `flutter analyze` is clean, and `flutter test` passed 1160 tests on the last run before PR #10. Functions tests and Firestore rules tests run in CI.

---

## 2. Product and roles

| Role | Scope | Main capabilities |
|---|---|---|
| Platform Owner | Platform | Manage platform administrators, customer organizations, and license plans |
| Platform Administrator | Platform | Create, edit, suspend, and delete customer organizations; manage organization administrators |
| Organization Admin | One organization | Manage branches, branch managers, and employees; reports; organization profile and settings |
| Branch Manager | One or more branches (active branch selected) | Add and manage employees in their branch; record group attendance; review returns and reports for the active branch |
| Employee | Self | Check in and out, breaks, shift progress, submit returns with bill photos, own profile, change own password |

Rules that apply everywhere (see `AGENTS.md`):
- No public sign-up. Administrators create accounts.
- Sign-in is identifier plus password. The identifier can be a username, email, or phone number.
- Branch managers see only their assigned branches. Employees see only their own data.
- Authorization is enforced on the server (Cloud Functions), not just hidden in the UI.

---

## 3. Architecture

Full detail is in `docs/architecture.md` and `docs/backend-api.md`. Summary:

**Flutter app**
- Feature-first layout under `lib/features/<feature>/` with `data`, `domain`, and `presentation` layers. Shared pieces are in `lib/core/` (including canonical widgets such as `AppKpiCard`, `AppButton`, `AppPageHeader`) and `lib/app/` (routing, theme, bootstrap).
- State management: Provider with `ChangeNotifier` controllers.
- Routing: GoRouter, with role-based guards and an adaptive shell (bottom navigation on phones, navigation rail on tablets and web).
- Mock-first: every repository has a mock implementation and a Firebase implementation behind the same contract. `test/contracts/` runs the same contract tests against both.
- Entry point selects the backend with `--dart-define=BACKEND_MODE=firebase`. `lib/app/bootstrap/backend_factory.dart` builds the repositories.

**Backend (Firebase project `workaxis-app`)**
- Firebase Authentication: identity and password sign-in.
- Cloud Firestore: attendance entries, daily counters, and read-only profile projections under `users/{authUid}`. Also the source for some profile fields (for example daily work hours, designation, and Aadhaar details).
- Cloud Storage bucket `workaxis-app-attachments`: profile photos, Aadhaar card images, and return bill photos. Stored as paths, not long-lived links.
- Cloud Functions (Node 22, 2nd gen, `asia-south1`, codebase `workaxis`): all sensitive writes. Callables include `provisionUser`, `updateUserAccount`, `resetUserPassword`, `setUserStatus`, `deleteOrganizationMember`, `deleteOrganization`, `setOrganizationStatus`, `saveBranch`, `createKioskPairingToken`, `recordAttendancePunch`, and `dataOp`.
- PostgreSQL: relational data (organizations, branches, memberships, returns). Reached only from Cloud Functions through `dataOp` and `SqlExecutor` (`functions/src/db`). The app never talks to SQL directly.
  - Instance: `omniretail-60c71:asia-south1:omniretail-sql` (database `workaxis`). This is a shared, small Cloud SQL instance in the separate OmniRetail project. Connection limits are tight: `DB_POOL_MAX` 3, `MAX_INSTANCES` 5.
  - Schema: `functions/db/migrations/001_init.sql`. Runner: `functions/db/migrate.mjs`.
- Firebase Data Connect was removed on 2026-11-15. Do not reintroduce it.
- Hosting: site `workaxis-app` serves the Flutter web build and the two policy pages.

**Persistence rules**
- Each business entity has one authoritative home.
- Cross-store writes go through Cloud Functions with idempotent steps where needed.
- Identity writes never go straight from the client to Firestore or SQL.

---

## 4. Feature status

Status is based on the code and the last test run. Areas marked "verify" should be checked in a running build before being promised to users.

| Area | Folder | Status |
|---|---|---|
| Sign-in and session | `features/authentication`, `features/access` | Implemented (Firebase mode) |
| Active branch context | `features/access`, `features/branches` | Implemented |
| Platform dashboard and organizations | `features/platform_dashboard`, `features/platform_organizations` | Implemented: create, edit, suspend, delete (soft delete), license tab |
| Platform users (administrators) | `features/platform_users` | Implemented: create, reset password, suspend, delete |
| License plans | `features/plans` | Implemented |
| Organization dashboard | `features/organization_dashboard` | Implemented |
| Branches | `features/branches`, `features/branch_dashboard` | Implemented: create, details, managers, location for geofence. Kiosk pairing exists on the backend (`createKioskPairingToken`); verify the UI. |
| Employees | `features/employees` | Implemented: directory, create (mandatory Aadhaar, photo, designation, salary for employees), edit, reset password, suspend, delete, details. Branch managers see only employees in their branch. |
| Employee home and attendance | `features/employee_home`, `features/attendance` | Implemented: check-in and check-out with location, breaks, live timer, group attendance |
| Returns | `features/returns` | Implemented: multi-item returns, bill photos, approval flow |
| Leaves | `features/leaves` | Employee and Branch Manager applications; Branch Managers or Organization Admins review employee requests; only Organization Admins review manager requests; approved requests cannot be edited |
| Reports | `features/reports` | Implemented: operational reports (verify the full set in the app) |
| Profile | `features/profile` | Implemented: own profile, change password |
| Settings | `features/settings` | Partial. Some controls are saved preferences only and not enforced (see section 7). |

---

## 5. Completed

**Recent merged PRs (all into `main`)**

| PR | Date | Summary |
|---|---|---|
| #1 | 2026-11-07 | Code review remediation: server authorization, scoping, session safety, UI cleanup |
| #2 | 2026-11-16 | Branch and organization UI updates, attendance card layout |
| #3 | 2026-11-16 | Plans and platform users: add buttons, administrator actions |
| #4 | 2026-11-16 | Administrator details: Reset and Suspend share one row on phones |
| #5 | 2026-11-16 | Delete administrators, explain refused suspends, delete on platform admin cards |
| #6 | 2026-11-17 | Aadhaar number validation fixed on the server |
| #7 | 2026-11-17 | Branch details access panel; shared account card layouts |
| #8 | 2026-11-17 | Employee cards: reset password, suspend, delete; `deleteOrganizationMember` |
| #9 | 2026-11-18 | Employee home live timer; branch managers list employees only; employee details layout |
| #10 | 2026-11-18 | Application ID changed to `com.sureshrapps.workaxis`; app icon set |
| #11 | 2026-11-18 | Privacy policy and account deletion request pages (deployed) |

**Other completed work**
- Data layer moved off Data Connect to plain PostgreSQL behind Cloud Functions (2026-11-15). Auth users migrated from `omniretail-60c71` with passwords and UIDs preserved.
- Firebase project `workaxis-app` set up as its own project. Hosting, Functions, Firestore, and the attachments bucket are in place.
- Google Play:
  - App created with package `com.sureshrapps.workaxis`.
  - Upload keystore created (`android/upload-keystore.jks`, git-ignored). `android/key.properties` created (git-ignored).
  - Original signed release bundle `1.0.0 (1)` was submitted to closed testing. Device log confirms it was built in mock mode and aborts at `BackendConfig.assertReleaseSafe` before the first Flutter frame.
  - Corrected signed bundle `1.0.0 (2)` is prepared at `build/app/outputs/bundle/release/app-release.aab` with `BACKEND_MODE=firebase`; it has not yet been uploaded.
  - Closed-testing release submitted with release notes in `<en-US>` tags.
  - Store text drafted (short and full description). Play icon at `store-assets/play-icon-512.png`, converted to 32-bit RGBA.
- Policy pages live: https://workaxis-app.web.app/privacy-policy.html and https://workaxis-app.web.app/account-deletion.html. Support email `sureshr.apps@gmail.com`.
- Developer decisions recorded: Firestore and Storage data in India, 90-day retention for attendance and return records, 30-day deletion response.

---

## 6. Pending

### 6.1 Google Play (in progress)
1. Upload the corrected `1.0.0 (2)` AAB from `build/app/outputs/bundle/release/app-release.aab` to closed testing and wait for Google's review. The currently installed `1.0.0 (1)` build fails before the app UI because it uses mock mode.
2. Collect 12 or more tester Gmail accounts. Each opts in and stays opted in for 14 consecutive days. Testers also need WorkAxis accounts, created by an administrator.
3. Apply for production access after day 14, then roll out production.
4. Complete any listing items still missing: feature graphic (1024 × 500), phone screenshots (at least 2), tablet screenshots (recommended), privacy policy URL entered, data safety submitted, content rating (IARC), target audience (18 and over), ads declaration (no ads), app access with a working test account.
5. Confirm the full description matches the final build. Remove any feature bullet the release doesn't include.
6. Add SHA-1 fingerprints to the Android Firebase app: the upload key (`keytool -list -v -keystore android\upload-keystore.jks`), and the Play app signing key (from Play Console under App integrity).
7. Check the Google Maps API key restrictions. The geofence map uses `google_maps_flutter`. HANDOFF notes the key may need the new Android package name and SHA-1 added. Confirm the map renders in the Play build.
8. Use a higher version code for every upload. The corrected local bundle is version code `2`; CI now uses the repository-wide GitHub run ID to avoid collisions across workflows. Keep the sequence increasing.

### 6.2 Backend and operations
1. **Decommission the old WorkAxis resources in `omniretail-60c71`** after the new project is verified: 12 `workaxis` functions, hosting site `workaxis-portal`, and bucket `workaxis-attachments`. Do not touch the OmniRetail data.
2. **Migrate photo paths.** Records saved before the photo-upload change still hold local device paths, not storage references.
3. **Plan for the shared database.** The `db-f1-micro` instance has tight connection limits. Raise them only together with the instance size, or move to a self-hosted PostgreSQL VM (`DB_MODE=tcp`, `docs/architecture.md` section 21c).
4. **Build the 90-day deletion job** (see section 7). Until it exists, the privacy policy and deletion page describe deletion that does not happen.
5. Leave requests use PostgreSQL migration `functions/db/migrations/005_leave_requests.sql`; the deploy workflow applies pending migrations before deploying Functions.

### 6.3 Platform targets
1. **iOS:** register a Firebase iOS app for `com.sureshrapps.workaxis` and update the iOS entry in `lib/firebase_options.dart`. Until then, iOS Firebase initialization won't match the bundle ID.
2. **macOS:** `macos/Runner/Configs/AppInfo.xcconfig` still says `com.workaxis` in the copyright line.
3. **Windows and web:** web is deployed. The Windows build was not checked in this handoff, so verify it before relying on it.

### 6.4 Legal and compliance
1. **Legal review of the privacy policy** and the deletion page.
2. **Aadhaar handling:** the app stores the full number and the card image. The Aadhaar Act and UIDAI rules restrict this. Decide whether to keep, mask, or drop it.
3. **Retention start point:** confirm the 90 days runs from when each record is created.
4. **Deletion blocking:** accounts with attendance, return, or leave records cannot be deleted, only suspended. Decide whether to keep that rule.

### 6.5 Product and code
1. **Settings enforcement:** session timeout, lockout and complexity, maintenance broadcast, attendance policy defaults, and notification automation are saved but not enforced. Either implement them or mark them clearly as not active.
2. **Kiosk terminals:** the backend supports paired kiosk devices. Confirm the flow works end to end in the app before promising it.
3. **Stale local branches:** 13 local branches are merged into `main` and can be deleted. `fix/code-review-remediation` is not merged. Decide whether to merge or close it.
4. **Docs:** `docs/WORKAXIS_IMPLEMENTATION_SUMMARY.md` is out of date (mock-only, 99 tests). Update or remove it.

---

## 7. Known gaps

- **90-day retention is not enforced.** No code deletes attendance or return records. The privacy policy and the deletion page both say records are deleted after 90 days. Do not let this ship unfixed without a decision.
- **Accounts with attendance, return, or leave records cannot be deleted.** `functions/src/employees/memberDeletion.ts` refuses deletion and the account is suspended. The deletion page says so.
- **Aadhaar number and image are stored** in Firestore and Storage. Legal review pending.
- **Settings controls** listed in 6.5 are not enforced.
- **Test credentials were shared in chat** during development. They are not in the repo. Rotate them before reviewers or testers use them.
- **Emulator network issues** on the development machine. Cloudflare WARP can break DNS and TLS for emulators. See section 10.

---

## 8. Decisions log

| Date | Decision | Notes |
|---|---|---|
| 2026-11-07 | Code review remediation merged | PR #1 |
| 2026-11-15 | Data Connect removed; SQL only via Cloud Functions `dataOp` | Shared Cloud SQL instance in OmniRetail project, for cost |
| 2026-11-15 | WorkAxis moved to its own Firebase project `workaxis-app` | Auth users migrated from `omniretail-60c71` |
| 2026-11-18 | Application ID `com.sureshrapps.workaxis` | Permanent once uploaded to Play |
| 2026-11-18 | Developer account is personal | Closed test (12 testers, 14 days) required before production |
| 2026-11-18 | Data hosted in India | Functions and SQL in asia-south1; Firestore and Storage in India per developer |
| 2026-11-18 | 90-day retention for attendance and return records | Not yet enforced in code (see 6.2) |
| 2026-11-18 | 30-day response time for deletion requests | Stated on the deletion page |
| 2026-11-18 | Deployed privacy pages without a deletion job | Developer's choice; gap recorded in section 7 |
| 2026-11-18 | Support email `sureshr.apps@gmail.com` | Used in policy and deletion page |

---

## 9. Engineering rules

Full rules are in `AGENTS.md` and `STITCH_FIDELITY_RULES.md`. The ones that matter most day to day:

- Read `AGENTS.md` and `STITCH_FIDELITY_RULES.md` before any UI change.
- No monolithic files. Split by responsibility. Feature code stays in its feature until real reuse appears.
- Use canonical widgets from `lib/core/widgets/`: `AppKpiCard`, `ResponsiveKpiSection`, `AppButton`, `AppTextField`/`AppPasswordField`, `AppPageHeader`.
- Presentation code never talks to Firebase, SQL, or Firestore directly. Mutations go through repositories and Cloud Functions.
- Every repository has mock and Firebase implementations that pass the same contract tests in `test/contracts/`.
- Before reporting work done: `dart format .`, `flutter analyze`, `flutter test`. Run `npm test` in `functions/` for backend changes. Report failures; don't claim success without running them.
- Commit and push only when asked. Use feature branches, open PRs into `main`, and merge with `gh pr merge --merge` after CI passes.
- Keep commit messages and PR descriptions focused on the change.

---

## 10. Environment and tooling

- **OS:** Windows 11. Use PowerShell for `flutter`, `firebase`, and Gradle builds. The bash sandbox failed Gradle with "Unable to establish loopback connection"; the same build worked from PowerShell.
- **Git:** use the Bash tool for git commands (per CLAUDE.md).
- **Flutter:** 3.47.0 (stable). **Firebase CLI:** 15.22.3. **GitHub CLI:** `gh` is signed in to `sureshr-apps/WorkAxis`.
- **Test devices and emulators:**
  - Emulators: `OnePlus_Pad_3` (tablet) and `Pixel_10_API_34` (phone).
  - Physical device used earlier: Moto G86 Power 5G (`ZA2238FNGG`).
  - The Pixel AVD has a different signing key from the Play build, so uninstall before installing a Play build.
- **Cloudflare WARP** (corporate Zero Trust) affects emulators:
  - DNS: enable Private DNS on the emulator: `adb shell settings put global private_dns_mode hostname` and `adb shell settings put global private_dns_specifier dns.google`.
  - TLS interception: pause WARP while testing with `warp-cli disconnect`, then `warp-cli connect` afterwards.

---

## 11. Deployment and release

**CI (GitHub Actions, `.github/workflows/`)**
- `ci.yml`: runs on pull requests and on pushes to branches other than `main`. Runs `verify.yml` only. Nothing is deployed.
- `deploy.yml`: runs on push to `main` or manually. Runs `verify`, then deploys only what changed: database migrations, functions and rules, and the web build to Hosting. A manual run deploys everything and also builds the Play App Bundle.
- `play-store.yml`: manual run from `main`. Runs verification, builds a signed App Bundle, and uploads a completed release to the configured closed testing track.
- `android.yml`: builds a signed APK on app changes. Artifact name `workaxis-apk-<run number>`.
- Deploys are serialized (`concurrency: deploy-main`).
- The Android `versionCode` in CI uses GitHub's repository-wide run ID.

**Manual deploys (if CI is unavailable)**
```powershell
firebase use workaxis-app
flutter build web --release --dart-define=BACKEND_MODE=firebase
firebase deploy --only firestore,storage,functions,hosting --project workaxis-app
```
Full checklist: `docs/backend-api.md` section 5.

**Play release**
- Build local releases with `flutter build appbundle --release --dart-define=BACKEND_MODE=firebase --build-number=<next-higher-code>` in PowerShell, or use the manual App Bundle run in CI. Never omit the Firebase define: release startup otherwise aborts before Flutter renders the UI.
- Output: `build/app/outputs/bundle/release/app-release.aab`.
- Signing: the upload key from `android/key.properties`, with Play App Signing managing the app signing key.

---

## 12. Secrets and private data

Never commit these. All are git-ignored or stored outside the repo:
- `android/upload-keystore.jks` and `android/key.properties`: the upload key and its passwords.
- `functions/.env.workaxis-app`: database and runtime settings.
- Service account credentials, if any.

Things to remember:
- The upload keystore and both passwords must be backed up somewhere safe. Losing them requires a Play upload-key reset.
- `android/google-services.json` and `lib/firebase_options.dart` contain public client config, not secrets. They are committed.
- Test account credentials were shared in chat during development. Rotate them.
- Do not put the developer's personal data, passwords, or the keystore passphrase into commits, PRs, or external services.

---

## 13. Resume checklist

For a new chat, start here:

1. Read this file, then `AGENTS.md`, then `docs/play-store-handoff.md` if the work involves Play.
2. Check state:
   ```powershell
   git status
   gh pr list --state open
   ```
3. Check the Play release in Play Console (**Testing → Closed testing**).
4. Decide the open items in section 6 that need the developer's input:
   - The 90-day deletion job: build it, or change the policy wording.
   - Aadhaar storage: keep, mask, or drop.
   - Legal review of the privacy policy and deletion page.
   - Whether to decommission the old `omniretail-60c71` WorkAxis resources.
   - iOS Firebase app registration.
5. Before any new deploy, run `flutter analyze`, `flutter test`, and `npm test` in `functions/`.
