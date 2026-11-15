-- 002_employee_codes.sql: per-organization employee IDs (EMP-10001, EMP-10002, ...).
--
-- Idempotent and non-destructive. The server allocates the next number
-- atomically inside the member-insert transaction by incrementing
-- organization.employee_code_seq. SQL is authoritative; the Firestore
-- users/{uid}.employeeCode projection is overwritten from it.

ALTER TABLE organization
  ADD COLUMN IF NOT EXISTS employee_code_seq integer NOT NULL DEFAULT 10000;

ALTER TABLE organization_member
  ADD COLUMN IF NOT EXISTS employee_code text;

-- Created before the backfill: every value is NULL at this point, and it guards
-- against duplicates from concurrent inserts while the backfill runs.
CREATE UNIQUE INDEX IF NOT EXISTS organization_member_org_employee_code_uq
  ON organization_member (organization_id, employee_code)
  WHERE employee_code IS NOT NULL;

-- Backfill: every org member without a code gets the next numbers in
-- (created_at, id) order. Re-running assigns nothing once all members have codes.
DO $$
DECLARE
  org record;
  assigned integer;
BEGIN
  FOR org IN
    SELECT id FROM organization
     WHERE EXISTS (SELECT 1 FROM organization_member m
                    WHERE m.organization_id = organization.id AND m.employee_code IS NULL)
     ORDER BY id
  LOOP
    -- Row lock serializes with concurrent provisioning for this organization.
    PERFORM 1 FROM organization WHERE id = org.id FOR UPDATE;

    WITH base AS (
      SELECT employee_code_seq AS seq FROM organization WHERE id = org.id
    ), numbered AS (
      SELECT m.id,
             (SELECT seq FROM base)
               + row_number() OVER (ORDER BY m.created_at, m.id) AS n
        FROM organization_member m
       WHERE m.organization_id = org.id AND m.employee_code IS NULL
    )
    UPDATE organization_member m
       SET employee_code = 'EMP-' || numbered.n
      FROM numbered
     WHERE m.id = numbered.id;
    GET DIAGNOSTICS assigned = ROW_COUNT;

    UPDATE organization
       SET employee_code_seq = employee_code_seq + assigned
     WHERE id = org.id;
  END LOOP;
END $$;
