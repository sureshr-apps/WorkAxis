# WorkAxis Engineering Handoff Document

This document provides a comprehensive technical overview and state transfer for continuing development of **WorkAxis** in Claude.

---

## 1. Project Overview & Architecture

**WorkAxis** is a single multi-tenant workforce and operational management Flutter application targeting **Android smartphones, Android tablets, and responsive Web browsers**.

There is **no separate customer and platform console app**; all 5 user roles share the same codebase with strictly enforced role-based navigation and permissions:
- **Platform Owner**: Platform governance and platform administrator management.
- **Platform Administrator**: Customer organization provisioning and management.
- **Organization Admin**: Scoped to exactly one organization; manages organization-wide settings, branches, managers, and employees.
- **Branch Manager**: Assigned to one or more branches; operates within an active branch context. Can only manage/view employees assigned to their branch.
- **Employee**: Scoped to their branch; accesses attendance check-in/out, daily work metrics, returns, and personal profile.

### Persistence & Backend Architecture (Hybrid Firebase)
- **Authentication**: Firebase Authentication (Identifier + password; identifier can be username, email, or phone number).
- **Relational Data (PostgreSQL via Firebase Data Connect)**: Authoritative source for organizations, branches, memberships, credentials, and product return transactions.
- **Document & Event Data (Cloud Firestore)**: High-frequency event data (attendance punches, daily aggregate counters) and read-only profile projections under `users/{authUid}`.
- **Cloud Functions (`functions/`, Node.js 22, 2nd Gen, `asia-south1`)**: Trusted server-side callables for all sensitive operations (identity provisioning, updates, password resets, status changes, kiosk pairings, attendance verification, branch transactions).
- **Storage**: Firebase Cloud Storage for profile photos, Aadhaar proof images, and return bill/product photos.
- **Dual-Mode System**:
  - `BACKEND_MODE=mock`: In-memory realistic repositories with isolated fakes for local testing.
  - `BACKEND_MODE=firebase`: Real production backend using Firebase Auth, Data Connect, Firestore, and Cloud Functions.

---

## 2. Non-Negotiable Engineering Rules (`AGENTS.md` & `STITCH_FIDELITY_RULES.md`)

When continuing development, ensure strict adherence to these constraints:
1. **Never create monolithic files**: Keep UI, domain logic, and data separate. Break widgets into cohesive subcomponents.
2. **Never write directly to SQL Connect or Firestore from presentation code**: All mutations must go through repository interfaces, which delegate to Cloud Functions or remote data sources.
3. **Use Canonical Design System Widgets** (`lib/core/widgets/`):
   - **KPI Cards**: Always use `AppKpiCard` (title top-left, large value bottom-left, 32dp icon container bottom-right; height standardized at 96dp).
   - **KPI Layouts**: Always use `ResponsiveKpiSection` (swipeable carousel on phone `<600dp`, 2-column grid on tablet `600-839dp`, single row flex on desktop `>=840dp`).
   - **Buttons**: Always use `AppButton` (`.primary`, `.secondary`, `.outlined`, `.responsive`).
   - **Date Fields**: Use `AppDatePickerField`.
4. **Contract Testing**: Every repository must fulfill shared contracts verified by both mock and real-fake test suites (`test/contracts/`).
5. **Zero static analysis warnings and 100% test pass rate** before deploying or closing tasks.

---

## 3. Chronological Summary of Recent Fixes & Features

Below is the complete history of recent user requests and solutions implemented:

### Request 1: "Delete organization removes temporarily, entry comes back on refresh"
- **Problem**: Org deletion was only mutating in-memory list state.
- **Fix**: Implemented the server-side `deleteOrganization` callable in `functions/src/handlers/deleteOrganization.ts` (soft-deletes organization, marks members deleted, releases login aliases in Firestore) and wired it through `lib/features/platform_organizations/data/sql_connect_platform_organizations_repository.dart`.

### Request 2: "In login page, remove portal v1.0 label and align logo and workaxis in the middle. Also remove end-to-end encrypted session message"
- **Fix**: Cleaned up `lib/features/authentication/presentation/screens/widgets/sign_in_header.dart` and `lib/features/authentication/presentation/screens/sign_in_screen.dart`: centered the logo and branding, removed `"Portal v1.0"`, and stripped the `"End-to-end encrypted session"` banner.

### Request 3: Physical Device Connection
- Connected Android device `ZA2238FNGG` (`moto_g86_power_5G`). Release APKs are built with `--dart-define=BACKEND_MODE=firebase`.

### Request 4: "No need for 'add organization' button under 'No customer organization registered'"
- **Fix**: Removed redundant empty-state button from `lib/features/platform_organizations/presentation/screens/organizations_list_screen.dart`, preserving the top app-bar CTA.

### Request 5: "Branch manager should only be allowed to add employees; Org admin can add managers and admins (not platform admins)"
- **Fix**: Updated `OrganizationMemberPolicy.creatableRoles` and `lib/features/employees/presentation/screens/widgets/organization_member_editor_dialog.dart`. When opened by a Branch Manager, the role dropdown locks exclusively to `Employee`. Org Admins can select `Organization Admin`, `Branch Manager`, or `Employee`.

### Request 6: "Permissions and branch scope: Role and Account Status buttons are not aligned"
- **Fix**: Fixed cross-axis alignment, flex constraints, and matching 48dp heights for the Role and Account Status fields inside `lib/features/employees/presentation/screens/widgets/organization_member_editor_dialog.dart`.

### Request 7: "Kiosk terminal and Generate pairing code functionality"
- Clarified architecture: WorkAxis supports branch-level kiosk terminals (for shared tablet attendance) paired via time-limited QR/pairing codes generated by `createKioskPairingToken`.

### Request 8: "Org admin created branch does not immediately appear in employee creation dropdown without logout"
- **Fix**: Ensured `lib/features/access/presentation/controllers/branch_context_controller.dart` and `lib/features/access/presentation/controllers/access_controller.dart` re-fetch and invalidate cached branch lists upon branch creation, making newly added branches available immediately in dropdowns.

### Request 9: "While creating employee, aadhar, aadhar pic, designation, salary should be mandatory"
- **Fix**:
  - In `lib/features/employees/presentation/screens/widgets/organization_member_editor_dialog.dart`: Made `aadhaarController` (validated for 12 digits), `aadhaarPhotoPath`, `designationController`, and `salaryController` strictly mandatory during creation when `role == UserRole.employee`.
  - Added visual required indicators (`*`) to `lib/features/employees/presentation/screens/widgets/employee_demographics_section.dart` and `lib/features/employees/presentation/screens/widgets/employee_employment_section.dart`.
  - Added comprehensive automated tests in `test/features/employees/employee_mandatory_fields_test.dart`.

### Request 10: "I tried creating a branch manager and set daily work hours to 9 hours, but on refresh it still shows 8"
- **Root Cause**:
  - In Firebase mode, Cloud Functions (`provisionUser` and `updateUserAccount`) wrote extended profile fields (`dailyWorkHours`, `shiftHours`, `employeeCode`, `aadhaarNumber`, etc.) to Firestore `users/{authUid}`.
  - However, `SqlConnectOrganizationMembersRepository.getMembersPage()` and `getMember()` in `lib/features/employees/data/sql_connect_organization_members_repository.dart` only queried Data Connect SQL (`organizationMembers`), which does not store rich profile attributes.
  - Upon reload, `OrganizationMember` instances were constructed without `dailyWorkHours`, defaulting to `8.0`.
- **Solution**:
  - In `lib/features/employees/data/sql_connect_organization_members_repository.dart`, added `_enrichWithProfiles` and `_enrichSingle` to read `users/{authUid}` in Firestore and hydrate all extended fields (`dailyWorkHours`, `salary`, `designation`, `aadhaarNumber`, `dateOfBirth`, `address`, `shiftHours`, etc.).
  - Injected `firestore: firestore` into `SqlConnectOrganizationMembersRepository` inside `lib/app/bootstrap/backend_factory.dart`.
  - Added unit tests in `test/features/employees/organization_members_repository_test.dart` with `FakeFirebaseFirestore` verifying hydration of `dailyWorkHours: 9.0` and fallback behaviors.

---

## 4. Current State of the Codebase

### Verification & Testing
- **Static Analysis**: `flutter analyze` passes with **0 issues**.
- **Automated Tests**: `flutter test` passes **820 / 820 tests**.

### Deployments & Builds
- **Cloud Functions**: Built and deployed to Google Cloud project `omniretail-60c71` in region `asia-south1`.
- **Web Portal**: Deployed live to **https://workaxis-portal.web.app**.
- **Android Release APK**: Built at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 5. Working Tree & Modified Files

The following files have uncommitted changes in the repository (`git status -s`):

### Modified Files (`M`):
- `android/app/src/main/AndroidManifest.xml` (Permissions for camera/storage/location)
- `functions/src/firestore/userStore.ts` (Profile projection writing/clearing)
- `functions/src/handlers/provisionUser.ts` (Added extended employee fields)
- `functions/src/handlers/updateUserAccount.ts` (Added extended employee update fields)
- `functions/src/index.ts` (Exported handlers)
- `functions/src/provisioning/provisionWorkflow.ts` (Profile write flow)
- `functions/src/sql/branches.ts` (Branch transactions)
- `lib/app/bootstrap/backend_factory.dart` (Injected Firestore into members repository)
- `lib/core/backend/account_callables.dart` (Client callable parameters for extended fields)
- `lib/features/access/presentation/controllers/access_controller.dart` (Branch cache refresh)
- `lib/features/access/presentation/controllers/branch_context_controller.dart` (Active branch scoping)
- `lib/features/authentication/presentation/screens/sign_in_screen.dart` (Header alignment)
- `lib/features/authentication/presentation/screens/widgets/sign_in_header.dart` (Cleaned header)
- `lib/features/branches/presentation/screens/branch_management_screen.dart` (Branch creation & manager assignments)
- `lib/features/employee_home/data/firestore_employee_home_repository.dart` (Employee metrics reading)
- `lib/features/employees/data/sql_connect_organization_members_repository.dart` (Firestore profile hydration)
- `lib/features/employees/domain/models/organization_member.dart` (Extended profile fields & copyWith)
- `lib/features/employees/domain/policies/organization_member_policy.dart` (Role creation permissions)
- `lib/features/employees/presentation/screens/employee_directory_screen.dart` (Directory display)
- `lib/features/employees/presentation/screens/widgets/member_details_dialog.dart` (Displaying work hours & profile info)
- `lib/features/employees/presentation/screens/widgets/organization_member_card.dart` (Card styling)
- `lib/features/employees/presentation/screens/widgets/organization_member_editor_dialog.dart` (Mandatory fields & role scoping)
- `lib/features/organization_dashboard/presentation/screens/organization_home_screen.dart` (KPIs & quick actions)
- `lib/features/platform_organizations/data/*` (Organization repositories & delete implementation)
- `lib/features/platform_organizations/presentation/*` (List, details, status dialogs)
- `lib/features/reports/presentation/screens/operational_reports_screen.dart` (Reports view)
- `lib/features/returns/data/*` & `presentation/*` (Multi-item returns module)
- `pubspec.yaml` & `pubspec.lock` (Dependencies)
- `test/*` (Updated contract and unit test suites)

### Untracked Files (`??`):
- `functions/src/handlers/deleteOrganization.ts` (Callable for organization soft-delete)
- `lib/core/widgets/app_date_picker_field.dart` (Canonical date picker widget)
- `lib/features/employees/presentation/screens/widgets/employee_demographics_section.dart` (Demographics form section)
- `lib/features/employees/presentation/screens/widgets/employee_employment_section.dart` (Employment details section)
- `lib/features/employees/presentation/screens/widgets/employee_id_input.dart` (Employee code / Aadhaar widget)
- `lib/features/employees/presentation/screens/widgets/employee_photo_picker.dart` (Aadhaar & profile photo picker)
- `lib/features/employees/presentation/screens/widgets/work_hours_shift_section.dart` (Daily work hours & shift selector)
- `lib/features/returns/presentation/screens/widgets/return_image_picker.dart` (Bill/product image picker)
- `test/features/employees/app_date_picker_field_test.dart`
- `test/features/employees/employee_mandatory_fields_test.dart`
- `test/features/employees/work_hours_shift_section_test.dart`
- `test/features/returns/return_module_enhanced_test.dart`

---

## 6. Helpful Commands for Continuing Work

- **Run all tests**:
  ```powershell
  flutter test
  ```
- **Run static analysis**:
  ```powershell
  flutter analyze
  ```
- **Build Web (Firebase mode)**:
  ```powershell
  flutter build web --release --dart-define=BACKEND_MODE=firebase
  ```
- **Deploy Web Hosting**:
  ```powershell
  firebase deploy --only hosting:workaxis
  ```
- **Build and Deploy Cloud Functions**:
  ```powershell
  npm --prefix functions run build
  firebase deploy --only functions
  ```
- **Build Release Android APK (Firebase mode)**:
  ```powershell
  flutter build apk --release --dart-define=BACKEND_MODE=firebase
  ```
- **Install APK to Connected Device**:
  ```powershell
  adb install -r build\app\outputs\flutter-apk\app-release.apk
  ```

- **Android Emulators Configured on this Machine**:
  - `OnePlus_Pad_3`: OnePlus Pad 3 (Tablet: 2800x2000, 320 dpi landscape, 4GB RAM, WHPX accelerated)
  - `Pixel_10_API_34`: Google Pixel 10 (Phone: 1080x2424, 420 dpi portrait, 3GB RAM, WHPX accelerated)
  - Launch commands:
    ```powershell
    flutter emulators --launch OnePlus_Pad_3
    flutter emulators --launch Pixel_10_API_34
    ```
  - **Important Note on Machine Network & Cloudflare WARP**:
    This Windows host runs corporate Cloudflare WARP Zero Trust (`o9solutions`). This impacts Android emulators in two distinct ways:
    1. **DNS Resolution**: WARP binds host DNS to local loopbacks (`127.0.2.2`). QEMU's virtual NAT bridge cannot reach host loopbacks, breaking DNS resolution by default.
       - **Fix**: Android Private DNS is enabled in the guest settings (`dns.google`), routing DNS-over-TLS directly through port 853 and bypassing host loopback DNS:
         ```powershell
         adb shell settings put global private_dns_mode hostname
         adb shell settings put global private_dns_specifier dns.google
         ```
       - **Alternative launch flag**: If ever wiping data or cold-booting without snapshots:
         ```powershell
         & "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd OnePlus_Pad_3 -dns-server 8.8.8.8,1.1.1.1
         ```
    2. **TLS Inspection (HTTPS Interception)**: When WARP is connected in `WarpWithDnsOverHttps` mode, Cloudflare Gateway intercepts outbound HTTPS traffic and signs it using its internal Root CA (`Gateway CA - Cloudflare Managed G4`). The stock Android emulator does not have this corporate CA installed, so Flutter/Android fails SSL handshakes with `CERTIFICATE_VERIFY_FAILED: self signed certificate in certificate chain`, surfacing as *"Network problem. Check your connection and try again."*
       - **Solution**: Pause/disconnect Cloudflare WARP while testing apps on the emulator:
         ```powershell
         & "C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe" disconnect
         ```
         (or pause it from the Windows taskbar Cloudflare tray icon). Once paused, traffic connects directly to Google/Firebase with native Google Trust Services TLS certificates. To re-enable when done:
         ```powershell
         & "C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe" connect
         ```


## 2026-11-15 - Data layer moved off Data Connect

- Firebase Data Connect, `dataconnect/`, `lib/dataconnect_generated` and the `firebase_data_connect` package are gone. Relational data is plain PostgreSQL reached only from Cloud Functions through `SqlExecutor` (`functions/src/db`). The app calls one callable, `dataOp` (`functions/src/data`), via `DataGateway` (`lib/core/backend/data_gateway.dart`). Schema: `functions/db/migrations/001_init.sql`, runner `functions/db/migrate.mjs`, seed `functions/db/seed/seed_data.sql`.
- Topology: Firebase project `workaxis-app` (Auth, Firestore, Storage bucket `workaxis-app-attachments`, Hosting, Functions in asia-south1 codebase `workaxis`) is separate from OmniRetail. Functions run as `workaxis-sql@workaxis-app.iam.gserviceaccount.com`, which has Cloud SQL Client and Instance User on `omniretail-60c71`, and use the shared instance `omniretail-60c71:asia-south1:omniretail-sql` (db `workaxis`, IAM user `workaxis-sql@workaxis-app.iam`). Settings: `functions/.env.workaxis-app`.
- Deploy: `firebase use workaxis-app`, `flutter build web --release --dart-define=BACKEND_MODE=firebase`, `firebase deploy --only firestore,storage,functions,hosting`. Full checklist: `docs/backend-api.md` section 5. Moving to a self-hosted Postgres VM (`DB_MODE=tcp`): `docs/architecture.md` section 21c.
- Open items: records saved before the photo-upload change still hold local device paths. Existing OmniRetail project data is untouched. The old WorkAxis functions and hosting in `omniretail-60c71` (workaxis-portal.web.app, the 12 workaxis functions, bucket `workaxis-attachments`) still exist and should be decommissioned after the new project is verified. The Google Maps API key restrictions may need the new Android app's SHA-1 added. Auth users were migrated from `omniretail-60c71` with passwords and UIDs preserved. The Cloud SQL instance is a shared db-f1-micro, so connection limits are tight (`DB_POOL_MAX` 3, `MAX_INSTANCES` 5).
- Review fixes (same day): employee home no longer prompts for location on load or refresh (prompt only from the geofence refresh button or a punch; `AttendanceLocationProvider.peekLocation`); `AccessController.refreshAccess({force})` has a 60s freshness window (default stays forced, screen-entry loads pass `force: false`); organization details actions and list cards are 360dp / 1.3x text safe; organization delete navigates with `context.go`, updates list and counts locally, and uses `AccountCallables.deleteOrganization`; `isHeadlessTest` replaced by `MapRenderingScope` (tests use `test/helpers/fallback_maps.dart`).
