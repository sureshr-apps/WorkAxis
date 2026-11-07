// Central constants. Region must match dataconnect/dataconnect.yaml.
export const REGION = "asia-south1";
export const DATA_CONNECT_SERVICE_ID = "workaxis-service";

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

export const callableOptions = {
  region: REGION,
  enforceAppCheck: ENFORCE_APP_CHECK,
  maxInstances: 20,
} as const;
