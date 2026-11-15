-- 001_init.sql: WorkAxis relational core.
--
-- Reproduces the schema Firebase Data Connect created from
-- dataconnect/schema/schema.gql. Idempotent and non-destructive: every
-- statement is IF NOT EXISTS, so it is safe against the live database that
-- already holds these tables (existing tables and columns are never altered;
-- inline constraints only apply when a table is created here).
--
-- Valid values (validated in functions, not DB enums):
--   role   : platformOwner | platformAdmin | orgAdmin | branchManager | employee
--   status : active | suspended        (organization, branch, member)
--   return : pending | approved | rejected

CREATE TABLE IF NOT EXISTS organization (
  id                  text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  name                text NOT NULL,
  code                text NOT NULL UNIQUE,
  category            text,
  country             text,
  status              text NOT NULL DEFAULT 'active',
  currency            text DEFAULT 'INR',
  logo_url            text,
  tax_identification  text,
  description         text,
  contact_name        text,
  contact_email       text,
  contact_phone       text,
  address             text,
  created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS branch (
  id                      text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  creation_request_key    text UNIQUE,
  creation_fingerprint    text,
  organization_id         text NOT NULL REFERENCES organization (id) ON DELETE CASCADE,
  name                    text NOT NULL,
  code                    text NOT NULL,
  location                text,
  status                  text NOT NULL DEFAULT 'active',
  is_main_branch          boolean NOT NULL DEFAULT false,
  geofence_radius_meters  integer DEFAULT 100,
  latitude                double precision,
  longitude               double precision,
  kiosk_enabled           boolean DEFAULT false,
  created_at              timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organization_id, code)
);

CREATE TABLE IF NOT EXISTS organization_member (
  id               text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  -- Null for platform-level roles (platformOwner, platformAdmin).
  organization_id  text REFERENCES organization (id) ON DELETE SET NULL,
  -- Firebase Auth uid; set for every member created by provisionUser.
  auth_uid         text UNIQUE,
  full_name        text NOT NULL,
  username         text NOT NULL UNIQUE,
  email            text NOT NULL UNIQUE,
  phone            text UNIQUE,
  role             text NOT NULL,
  status           text NOT NULL DEFAULT 'active',
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_branch_assignment (
  id           text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  member_id    text NOT NULL REFERENCES organization_member (id) ON DELETE CASCADE,
  branch_id    text NOT NULL REFERENCES branch (id) ON DELETE CASCADE,
  assigned_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (member_id, branch_id)
);

CREATE TABLE IF NOT EXISTS commercial_agreement (
  id                        text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  organization_id           text NOT NULL REFERENCES organization (id) ON DELETE CASCADE,
  agreement_reference       text NOT NULL UNIQUE,
  plan_name                 text NOT NULL,
  plan_tier                 text NOT NULL,
  negotiated_price          double precision NOT NULL,
  annual_maintenance_price  double precision NOT NULL,
  max_stores                integer NOT NULL,
  max_users                 integer NOT NULL,
  start_date                date NOT NULL,
  expiry_date               date NOT NULL,
  status                    text NOT NULL DEFAULT 'active',
  created_at                timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS license_event (
  id                        text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  organization_id           text NOT NULL REFERENCES organization (id) ON DELETE CASCADE,
  -- LICENSE_ASSIGNED, PLAN_CHANGED, TERMS_MODIFIED, RENEWED
  event_type                text NOT NULL,
  plan_name                 text NOT NULL,
  plan_tier                 text NOT NULL,
  validity_period           text NOT NULL,
  stores_count              integer NOT NULL,
  users_count               integer NOT NULL,
  one_time_price            double precision NOT NULL,
  annual_maintenance_price  double precision NOT NULL,
  created_at                timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS return_record (
  id               text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  organization_id  text NOT NULL REFERENCES organization (id) ON DELETE CASCADE,
  branch_id        text NOT NULL REFERENCES branch (id) ON DELETE CASCADE,
  -- Legacy member id as supplied by the client; employee_uid (server-stamped
  -- from auth.uid) is the authoritative submitter identity.
  employee_id      text NOT NULL,
  employee_uid     text,
  employee_name    text NOT NULL,
  -- Legacy columns: customer_name carried the product title, amount the quantity.
  customer_name    text NOT NULL,
  amount           double precision NOT NULL,
  product_title    text,
  quantity         double precision,
  unit             text,
  invoice_number   text NOT NULL,
  status           text NOT NULL DEFAULT 'pending',
  return_reason    text NOT NULL,
  bill_image_url   text,
  remarks          text,
  reviewer_notes   text,
  reviewer_uid     text,
  reviewer_name    text,
  reviewed_at      timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now()
);

-- Indexes for the filters used by queries and the delete-organization steps.
-- (Primary keys and UNIQUE constraints above already index their own columns.)
CREATE INDEX IF NOT EXISTS idx_branch_organization
  ON branch (organization_id);
CREATE INDEX IF NOT EXISTS idx_organization_member_organization
  ON organization_member (organization_id);
CREATE INDEX IF NOT EXISTS idx_organization_member_role
  ON organization_member (organization_id, role);
CREATE INDEX IF NOT EXISTS idx_user_branch_assignment_branch
  ON user_branch_assignment (branch_id);
CREATE INDEX IF NOT EXISTS idx_commercial_agreement_organization
  ON commercial_agreement (organization_id);
CREATE INDEX IF NOT EXISTS idx_license_event_organization
  ON license_event (organization_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_return_record_org_created
  ON return_record (organization_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_return_record_branch_created
  ON return_record (branch_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_return_record_employee_uid
  ON return_record (employee_uid);
