-- Leave requests are relational records so authorization, review state, and
-- organization/branch/member relationships remain authoritative in PostgreSQL.
-- PostgreSQL requires a unique index over the referenced composite columns,
-- even though each id is already individually unique.
CREATE UNIQUE INDEX IF NOT EXISTS uq_branch_id_organization
  ON branch (id, organization_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_member_id_organization
  ON organization_member (id, organization_id);

CREATE TABLE IF NOT EXISTS leave_request (
  id                  text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  organization_id     text NOT NULL REFERENCES organization (id) ON DELETE CASCADE,
  branch_id           text NOT NULL,
  applicant_member_id text NOT NULL,
  applicant_uid       text NOT NULL,
  applicant_name      text NOT NULL,
  applicant_role      text NOT NULL CHECK (applicant_role IN ('employee', 'branchManager')),
  leave_type          text NOT NULL CHECK (leave_type IN ('annual', 'sick', 'personal', 'unpaid')),
  start_date          date NOT NULL,
  end_date            date NOT NULL,
  reason              text NOT NULL,
  status              text NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewer_uid        text,
  reviewer_name       text,
  reviewer_notes      text,
  reviewed_at         timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT leave_request_dates_valid CHECK (end_date >= start_date),
  CONSTRAINT leave_request_branch_org_fk
    FOREIGN KEY (branch_id, organization_id)
    REFERENCES branch (id, organization_id) ON DELETE RESTRICT,
  CONSTRAINT leave_request_applicant_org_fk
    FOREIGN KEY (applicant_member_id, organization_id)
    REFERENCES organization_member (id, organization_id) ON DELETE RESTRICT,
  CONSTRAINT leave_request_review_state_valid CHECK (
    (status = 'pending' AND reviewer_uid IS NULL AND reviewed_at IS NULL)
    OR (status IN ('approved', 'rejected') AND reviewer_uid IS NOT NULL AND reviewed_at IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_leave_request_org_status_created
  ON leave_request (organization_id, status, created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_leave_request_branch_status_created
  ON leave_request (branch_id, status, created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_leave_request_applicant_created
  ON leave_request (applicant_uid, created_at DESC, id DESC);

-- A request may be edited only while it is pending. Once approved, even a
-- future server operation cannot change its application or review details.
CREATE OR REPLACE FUNCTION prevent_approved_leave_request_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.status = 'approved' THEN
    RAISE EXCEPTION 'Approved leave requests are immutable'
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS leave_request_approved_immutable ON leave_request;
CREATE TRIGGER leave_request_approved_immutable
  BEFORE UPDATE ON leave_request
  FOR EACH ROW
  EXECUTE FUNCTION prevent_approved_leave_request_update();
