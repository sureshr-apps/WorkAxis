-- Organization leave policy: leave types with a yearly allowance, and whether
-- the allowance accrues monthly. Allowances and the accrual flag are
-- effective-dated so a change applies from its effective date onward and
-- payroll for earlier days never changes.
--
-- Leave requests now reference a leave type. This migration assumes no leave
-- requests exist yet (pre-production): it fails on SET NOT NULL below if any
-- do, rather than guessing a type for them.

CREATE TABLE IF NOT EXISTS leave_type (
  id               text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  organization_id  text NOT NULL REFERENCES organization (id) ON DELETE CASCADE,
  name             text NOT NULL CHECK (length(btrim(name)) BETWEEN 1 AND 60),
  -- false for the built-in "Unpaid leave" type: never paid, no allowance.
  paid             boolean NOT NULL DEFAULT true,
  sort_order       integer NOT NULL DEFAULT 100,
  archived_at      timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now()
);

-- Active type names are unique per organization (case-insensitive).
CREATE UNIQUE INDEX IF NOT EXISTS uq_leave_type_active_name
  ON leave_type (organization_id, lower(btrim(name)))
  WHERE archived_at IS NULL;

-- One built-in unpaid type per organization.
CREATE UNIQUE INDEX IF NOT EXISTS uq_leave_type_unpaid
  ON leave_type (organization_id)
  WHERE NOT paid;

CREATE TABLE IF NOT EXISTS leave_type_allowance (
  leave_type_id   text NOT NULL REFERENCES leave_type (id) ON DELETE CASCADE,
  effective_from  date NOT NULL,
  -- Days per calendar year (pro-rated from the joining month).
  yearly_days     numeric(5, 2) NOT NULL CHECK (yearly_days >= 0 AND yearly_days <= 366),
  -- Unused days move to the next year; otherwise they lapse on 31 December.
  carry_forward   boolean NOT NULL DEFAULT false,
  created_by_uid  text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (leave_type_id, effective_from)
);

CREATE TABLE IF NOT EXISTS organization_leave_policy (
  organization_id  text NOT NULL REFERENCES organization (id) ON DELETE CASCADE,
  effective_from   date NOT NULL,
  -- true: the yearly allowance accrues 1/12 per month, unused accrual
  -- carries to later months of the year. false: available from January.
  monthly_accrual  boolean NOT NULL,
  created_by_uid   text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (organization_id, effective_from)
);

-- Every organization starts with only the built-in Unpaid leave type and
-- yearly (not monthly) availability; Org Admins add their own paid types.
CREATE OR REPLACE FUNCTION seed_leave_policy(org_id text)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO leave_type (organization_id, name, paid, sort_order)
  VALUES (org_id, 'Unpaid leave', false, 1000)
  ON CONFLICT DO NOTHING;
  INSERT INTO organization_leave_policy (organization_id, effective_from, monthly_accrual)
  VALUES (org_id, DATE '1970-01-01', false)
  ON CONFLICT DO NOTHING;
END;
$$;

SELECT seed_leave_policy(id) FROM organization;

CREATE OR REPLACE FUNCTION seed_leave_policy_for_new_organization()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM seed_leave_policy(NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS organization_seed_leave_policy ON organization;
CREATE TRIGGER organization_seed_leave_policy
  AFTER INSERT ON organization
  FOR EACH ROW
  EXECUTE FUNCTION seed_leave_policy_for_new_organization();

-- The fixed leave_type code is replaced by a reference to the organization's
-- leave type.
ALTER TABLE leave_request DROP COLUMN IF EXISTS leave_type;
ALTER TABLE leave_request
  ADD COLUMN IF NOT EXISTS leave_type_id text REFERENCES leave_type (id) ON DELETE RESTRICT;
ALTER TABLE leave_request ALTER COLUMN leave_type_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_leave_request_applicant_approved_dates
  ON leave_request (applicant_member_id, start_date)
  WHERE status = 'approved';
