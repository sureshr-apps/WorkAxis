# WorkAxis: Play Store handoff

Status as of 19 November 2026. Written so the work can continue in a new chat.

Sections: [Completed](#completed) · [Pending](#pending) · [Known gaps](#known-gaps-to-be-aware-of) · [Key facts](#key-facts) · [Where things are](#where-things-are) · [Next steps](#next-steps-in-order)

---

## Completed

### Code and repository

- **Application ID changed** from `com.workaxis.workaxis` to `com.sureshrapps.workaxis`. This covers Android (namespace, applicationId, `MainActivity` package), iOS and macOS bundle identifiers, and Linux. The Android Firebase app is registered in `lib/firebase_options.dart` and `android/app/google-services.json`.
  - Merged via **PR #10** (`feature/package-name`, commit `70d3828`).
- **App icon set generated** from the in-app hub mark (Material `hub_rounded`, white on `#004AC6`). Covers Android legacy and adaptive icons, iOS and macOS AppIcon sets, web icons, and Windows `app_icon.ico`. Included in PR #10.
- **Privacy policy and account-deletion request pages** written and deployed.
  - `web/privacy-policy.html`: live at https://workaxis-app.web.app/privacy-policy.html
  - `web/account-deletion.html`: live at https://workaxis-app.web.app/account-deletion.html
  - Merged via **PR #11** (`56fe9c8` on `main`). The deploy workflow succeeded, including the web build and Hosting deploy. Both pages return HTTP 200.
- **Earlier feature work merged** in PRs #2 to #9. This includes the employee home live timer, employee directory and details, account actions (reset password, suspend, delete), and branch-manager employee scoping.
- **Analyzer and tests** passed before PR #10: `flutter analyze` reported no issues, and `flutter test` passed 1160 tests.

### Release signing and build

- **Upload keystore created:** `android/upload-keystore.jks`, RSA 2048, alias `upload`, validity 10,000 days. It is git-ignored.
- **`android/key.properties` created** with the passwords the developer chose. It is git-ignored. Do not paste its contents into chats or commits.
- **Closed-test version 1.0.0 (1):** `build/app/outputs/bundle/release/app-release-v1.0.0+1-original.aab` (60.8 MB), signed with the upload certificate. A device log confirmed this build starts in mock mode and throws `Mock backend is not permitted in release builds` before Flutter renders its first frame.
- **Latest closed-test upload:** the automated GitHub Actions workflow uploaded version name `1.0.0` to the `Alpha-1` track on 19 November 2026. It built the signed App Bundle with `BACKEND_MODE=firebase` and a unique Android version code.
- **Automatic version names:** future closed-test uploads increment the patch version automatically. The next app release will be `1.0.1`, followed by `1.0.2`; successful uploads are recorded with `play-vX.Y.Z` Git tags. See [CI/CD](ci-cd.md#google-play-closed-test-publishing).
- Every local release build must include `--dart-define=BACKEND_MODE=firebase`; without it, release startup aborts before the app UI appears. The CI App Bundle workflow already supplies this define. Each Play upload also needs a higher version code.
- `pubspec.yaml` is now `1.0.0+2`, matching the corrected bundle.

### Google Play Console

- **Developer account:** Personal. The 14-day closed-test requirement applies.
- **App created** with package name `com.sureshrapps.workaxis`.
- **Play App Signing:** accepted as the default at first upload.
- The original `1.0.0 (1)` closed-test release was superseded by the automated `1.0.0` upload. The Play workflow uploads directly to `Alpha-1`; check the console for Google's processing/review status.
- **Store listing text drafted** (short and full description). Confirm the text is entered in the console.
  - Short description: "Employee attendance, branch management and returns for your organization."
- **Play store icon:** `store-assets/play-icon-512.png`, converted to 32-bit RGBA with full opacity to match Play's requirement. The change is not committed yet.
- **Data safety answers** worked out from the code (see below). Confirm they were entered.
  - Data collected: name, email, phone, usernames and employee codes, Aadhaar number and card image, precise location at check-in and check-out, photos, and uploaded files.
  - No analytics, crash reporting, or ads SDKs were found.
  - Data is encrypted in transit. Deletion is available on request.
- **Support email:** `sureshr.apps@gmail.com`, used on both pages and the policy.

---

## Pending

### Google Play (closed testing track)

1. **Wait for Google's review** of the closed-testing release. Check **Testing → Closed testing → your track**. The status changes from "In review" to "Available."
2. **Get 12 or more testers** with real Google accounts (Gmail or Workspace). Each tester must open the opt-in link on an Android phone signed in to that account and tap **Become a tester**.
   - Testers also need WorkAxis sign-in accounts, which an organization administrator creates in the app.
3. **Keep all testers opted in for 14 consecutive days.** If anyone drops out, the count restarts.
4. **Apply for production access** from the dashboard after day 14. Answer the questionnaire.
5. **Create a production release** and roll it out. Review can take several days.

### Store listing and policy forms (confirm each is complete)

- **Feature graphic:** 1024 × 500 PNG. Not created yet. Offer to generate one.
- **Phone screenshots:** at least 2, 16:9 or 9:16, between 320 and 3840 px.
- **Tablet screenshots:** optional but recommended, since the app supports tablets.
- **Privacy policy URL:** https://workaxis-app.web.app/privacy-policy.html. Enter it in the console.
- **Data safety form:** answers are in the Completed section. Confirm they are submitted.
- **Content rating questionnaire (IARC):** not confirmed as completed.
- **Target audience:** 18 and over. Not confirmed as set.
- **Ads:** no ads. Confirm the declaration.
- **App access:** give reviewers a working WorkAxis test account. This is required because the app needs a login. Not confirmed as provided.
- **Description claims:** the full description was written from the code and needs checking against the final build. Remove any bullet the release doesn't include. The kiosk feature was left out on purpose.

### Legal and compliance (not signed off)

- **Privacy policy:** needs a legal review before publication. The "Draft for review" box has been removed, but the content hasn't been reviewed.
- **Aadhaar:** the app stores the full Aadhaar number and the card image. The Aadhaar Act and UIDAI rules restrict this. Someone who knows Indian data protection law should decide whether to keep, mask, or drop it.
- **Retention:** the developer confirmed 90 days for attendance and return records, and their attached photos and documents. The deletion page says requests are completed within 30 days. Both are in the published pages.
- **Retention start point:** the 90 days is assumed to run from when each record is created. Confirm this.

### Repository housekeeping

- **Uncommitted change:** `store-assets/play-icon-512.png` (RGBA conversion). Commit it if it should be in the repo.
- **Firebase Android SHA-1 (optional):** add the upload key's SHA-1 to the Android app in Firebase. This is needed later for Google sign-in or App Check.

---

## Known gaps to be aware of

- **The 90-day retention is not enforced.** Nothing in the code deletes attendance or return records. The policy and the deletion page both describe 90-day deletion. The developer chose to deploy without a deletion job. Build the job, or change the wording, before a reviewer or user relies on it.
- **Accounts with attendance or return records cannot be deleted.** The backend (`functions/src/employees/memberDeletion.ts`) refuses deletion and suspends the account instead. The deletion page says this.
- **Test account credentials were shared in chat earlier.** They are not stored in the repo. Rotate them before reviewers use them.
- **iOS Firebase app** for the new bundle identifier is not registered. iOS Firebase initialization won't match until it is.
- **macOS copyright string** in `macos/Runner/Configs/AppInfo.xcconfig` still says `com.workaxis`.
- **Installing from Play** requires the closed-test review to pass first. Internal testing is the faster route for the developer's own device.
- **Sideloaded builds** are signed with the upload key, while Play installs use Google's app signing key. Uninstall the sideloaded copy before installing the Play version.

---

## Key facts

| Item | Value |
|---|---|
| Application ID | `com.sureshrapps.workaxis` |
| Version base | `1.0.0+2` in `pubspec.yaml`; Play closed-test version names are generated by CI |
| Firebase project | `workaxis-app` |
| Hosting site | `workaxis-app` (https://workaxis-app.web.app) |
| Functions region | `asia-south1` (Mumbai) |
| Data location | India (per the developer; Firestore and Storage location to be confirmed in console) |
| Support email | `sureshr.apps@gmail.com` |
| Operator name used in policy | Yashassu Technologies (from the signing certificate; confirm) |
| Play developer account type | Personal |
| Closed-test requirement | 12+ testers opted in for 14 consecutive days |
| Repo | `sureshr-apps/WorkAxis` on GitHub |
| Default branch | `main` |

---

## Where things are

| What | Where |
|---|---|
| Release bundle | `build/app/outputs/bundle/release/app-release.aab` |
| Upload keystore | `android/upload-keystore.jks` (git-ignored) |
| Signing config | `android/key.properties` (git-ignored; keep private) |
| Gradle signing logic | `android/app/build.gradle.kts` |
| Play icon (512 px) | `store-assets/play-icon-512.png` |
| Privacy policy | `web/privacy-policy.html` |
| Deletion request page | `web/account-deletion.html` |
| Deploy workflow | `.github/workflows/deploy.yml` (deploys on push to `main`) |
| Deletion rules | `functions/src/employees/memberDeletion.ts` |
| Architecture notes | `docs/architecture.md`, `docs/backend-api.md`, `docs/ci-cd.md` |

PRs: #2 to #9 (features, merged earlier), #10 (package rename and icons, merged), #11 (privacy policy and deletion page, merged).

---

## Next steps, in order

1. Confirm the closed-testing release shows **Available** in Play Console.
2. Confirm every listing and policy item above is complete. The feature graphic is the main missing asset.
3. Provide a WorkAxis test account for app access.
4. Collect 12 or more tester Gmail accounts. Get each one to join and stay opted in for 14 days.
5. Decide on the 90-day deletion job and the Aadhaar handling. Both need a decision before production.
6. After 14 days, apply for production access, then roll out production.
7. If the developer wants to test sooner, use the internal testing track with the same AAB.
