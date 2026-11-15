import { defineInt, defineString } from "firebase-functions/params";

// Central constants. Region must match the Cloud Functions / Cloud SQL region.
export const REGION = "asia-south1";

/** Business timezone used to compute attendance workDate. */
export const BUSINESS_TIMEZONE = "Asia/Kolkata";

/** Reject GPS fixes less accurate than this (metres). */
export const MAX_GPS_ACCURACY_METERS = 100;

export const MIN_PASSWORD_LENGTH = 8;
export const KIOSK_TOKEN_TTL_MINUTES = 10;
export const PROVISION_LOCK_STALE_SECONDS = 120;

/** Login-identifier resolution: attempts allowed per client IP per window. */
export const RESOLVE_MAX_ATTEMPTS = 30;
export const RESOLVE_WINDOW_MINUTES = 15;

/** When "true", callables reject requests lacking a valid App Check token. */
export const ENFORCE_APP_CHECK = process.env.ENFORCE_APP_CHECK === "true";

/** Domain for synthetic login emails when an admin supplies no email. */
export const SYNTHETIC_EMAIL_DOMAIN = "login.workaxis.invalid";

/**
 * Identity the functions run as. In production this is the service account
 * granted access to the database host (for Cloud SQL: Cloud SQL Client and
 * Instance User). "default" uses the project's default compute service account.
 */
// Deploy-time options must be params (read from functions/.env.<project>);
// plain process.env is not populated while the CLI analyses the code.
export const RUNTIME_SERVICE_ACCOUNT = defineString("RUNTIME_SERVICE_ACCOUNT", {
  default: "default",
});

/**
 * Upper bound on concurrent instances. Every instance holds a small database
 * pool, so this also caps connections on a small shared database server.
 */
export const MAX_INSTANCES = defineInt("MAX_INSTANCES", { default: 5 });

export const callableOptions = {
  region: REGION,
  enforceAppCheck: ENFORCE_APP_CHECK,
  maxInstances: MAX_INSTANCES,
  serviceAccount: RUNTIME_SERVICE_ACCOUNT,
} as const;
