# CI/CD (GitHub Actions)

Everything below is defined in `.github/workflows/` and targets the Firebase
project `workaxis-app`. Nothing in the pipeline touches `omniretail-60c71`
except the Cloud SQL connection used for migrations (see "Database access").

## Workflows

| File | Trigger | What it does |
|---|---|---|
| `verify.yml` | called by the two below | `dart format` check, `flutter analyze`, `flutter test`; functions `npm test` (tsc + node tests); Firestore rules tests in the emulator |
| `ci.yml` | pull requests and pushes to any branch except `main` | runs `verify.yml` only. No secrets, nothing deployed |
| `deploy.yml` | push to `main`, or run manually | `changes` detects what the push touched. `verify` always runs (analysis, two test shards, functions, rules). Then only what changed deploys: database migrations (`functions/db`), functions + Firestore/Storage rules and indexes (`functions/`, rules, indexes), web build and Hosting (`lib/`, `web/`, `assets/`, `pubspec`, `firebase.json`). The signed Android APK (`app` changes) is built from `android.yml` and does not wait for `verify`. The App Bundle is built only on a manual run, for Play uploads. A manual run deploys everything |
| `play-store.yml` | manual run from `main` | by default validates Play access and a signed App Bundle without publishing; when validation-only is unchecked, runs `verify.yml` and publishes to the configured testing track. It cannot publish to `production` |

Deployments are serialised (`concurrency: deploy-main`) and are never cancelled
midway. Android `versionCode` is `(GitHub run ID % 2,000,000,000) + 100`: this
avoids per-workflow run-number collisions and stays below Android's 2.1 billion
limit. The sequence increments until the modulo interval wraps.
Play closed-test uploads are serialized and Fastlane is pinned to `2.242.0`.

Where to find the Android build: the run's page, section Artifacts,
`workaxis-apk-<run number>` (APK for direct install). The App Bundle (AAB, for the
Play Store) from `deploy.yml` is `workaxis-appbundle-<run number>` and exists only
for manual runs. The Play publishing workflow downloads its own run's bundle and
uploads it directly. Artifacts are kept for 30 days. The repository is public, so artifacts
are visible to any signed-in GitHub user; add a private release channel (for
example Firebase App Distribution) before sharing builds more widely.

## How GitHub reaches Google Cloud (no stored keys)

`google-github-actions/auth` exchanges the run's OIDC token through Workload
Identity Federation for the service account
`workaxis-deployer@workaxis-app.iam.gserviceaccount.com`.

- Pool `github`, provider `workaxis-repo` in project `workaxis-app`.
- The provider only accepts tokens where `repository == sureshr-apps/WorkAxis`
  **and** `ref == refs/heads/main`. Pull requests, forks and other branches
  cannot deploy.
- The deployer holds, in `workaxis-app` only: Firebase Admin, Cloud Functions
  Admin, Cloud Run Admin, Cloud Scheduler Admin, Artifact Registry Admin, Cloud
  Build Editor, Service Usage Admin, Storage Admin, Datastore Index Admin and
  Service Account User.

Repository variables (Settings, Secrets and variables, Actions, Variables):

- `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `GCP_DEPLOYER_SERVICE_ACCOUNT`
- `GCP_PLAY_PUBLISHER_SERVICE_ACCOUNT` (dedicated account used only for Play publishing)
- `PLAY_CLOSED_TEST_TRACK` (exact Google Play Developer API identifier of the closed testing track, not necessarily its display title)

### Google Play closed-test publishing

The Play publishing workflow uses Workload Identity Federation, so it needs no
service-account key JSON or Play credential secret. Before its first run:

1. Enable the Google Play Developer API in the linked `workaxis-app` Google
   Cloud project. Create a dedicated service account for Play publishing.
2. Allow the existing `github` Workload Identity Pool/provider to impersonate
   that service account. Keep the provider's current repository and `main`
   branch restrictions.
3. In Play Console, add the service-account email under **Users and
   permissions** and grant the WorkAxis app the **Release apps to testing
   tracks** permission. Production release permission is not required.
4. Set `GCP_PLAY_PUBLISHER_SERVICE_ACCOUNT` to that service-account email and
   `PLAY_CLOSED_TEST_TRACK` to the track identifier returned by the Play
   Developer API. Closed testing tracks have custom identifiers; the console
   title (for example, `Alpha-1`) is not guaranteed to be the API identifier.
5. Run **Actions → Publish Android closed test → Run workflow** on `main`.

In the GitHub Actions form, **Validate Play access and the bundle without
publishing** is checked by default. This uses Fastlane's `validate_only` mode to
validate the Play edit without committing it; the AAB is uploaded to the
temporary edit for validation. To publish, uncheck that option. Publishing runs
only after verification passes. Play review or account-app setup requirements
can still need action in Play Console; this workflow does not fill the
app-access declaration or release notes.

## Database access for migrations

`functions/db/migrate.mjs` runs in the `database` job as the IAM database user
`workaxis-deployer@workaxis-app.iam`, which:

- reaches `omniretail-sql` through Cloud SQL Client and Cloud SQL Instance User
  roles on `omniretail-60c71`, **restricted by an IAM condition to that one
  instance**;
- is a member of the table-owner role `firebaseowner_workaxis_public`, and the
  job sets `DB_MIGRATION_ROLE` to that role so new tables are owned by it;
- new tables automatically grant the app's runtime user
  (`workaxis-sql@workaxis-app.iam`) select/insert/update/delete through default
  privileges.

Rules for migrations:

1. Add a new numbered file in `functions/db/migrations/`; never edit an applied
   one.
2. Make it idempotent (`IF NOT EXISTS`) and **backward compatible**: the
   previous backend keeps running until the deploy step finishes.
3. Run order is `database` then `backend`, so a failed migration stops the
   deploy before any code changes.

## Android signing

Release builds are signed with the upload key. `android/app/build.gradle.kts`
reads it from environment variables (CI) or `android/key.properties` (local),
and falls back to the debug key if neither exists.

Repository secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.

The keystore and its passwords are also stored in
`%USERPROFILE%\.workaxis-secrets\` on the machine that created them. **Back that
folder up somewhere safe.** GitHub secrets cannot be read back, and losing the
key means installed apps can no longer be updated in place.

To build locally with the same key, create `android/key.properties` (ignored by
git):

```
storeFile=C:\\Users\\<you>\\.workaxis-secrets\\workaxis-upload.jks
storePassword=...
keyAlias=workaxis
keyPassword=...
```

## Runtime configuration

Non-secret function settings live in `functions/.env.workaxis-app` and are
deployed with the functions (`DB_MODE`, `DB_NAME`, `DB_USER`,
`DB_INSTANCE_CONNECTION_NAME`, `RUNTIME_SERVICE_ACCOUNT`, `MAX_INSTANCES`).
Moving the database to a VM means changing those values and, for password
authentication, supplying the password as a secret (see `docs/architecture.md`,
section 21c).

## Operations

- Re-run a failed deployment: Actions, Deploy, Re-run failed jobs (or Run
  workflow on `main`).
- Roll back: revert the commit on `main`; the pipeline redeploys the previous
  code. Database migrations are not reverted automatically; write a new
  forward migration instead.
- Rotate the Android key or deployer access: update the repository secret, or
  delete and recreate the workload identity provider.
- Pin changes: Flutter `3.47.0` and firebase-tools `15.22.3` are pinned in the
  workflows; update them deliberately.

## Known first-run caveats

- The Firestore rules tests (`test-rules/`) need the Firestore emulator and could
  not be run on the machine that wrote them. The first CI run is their first
  execution; if that job fails, fix the test or the rules before deploys can
  proceed.
- The `database` job's keyless Cloud SQL login (IAM authentication through the
  federated identity) has been configured but not exercised by a real run.
