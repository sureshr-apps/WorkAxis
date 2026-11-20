-- Snapshot who assigned the current employee/branch assignment and when.
-- Existing rows remain null because earlier releases did not record an assigner
-- or a reliable reassignment time.
ALTER TABLE employee_asset
  ADD COLUMN IF NOT EXISTS assigned_by_uid text,
  ADD COLUMN IF NOT EXISTS assigned_by_name text,
  ADD COLUMN IF NOT EXISTS assigned_at timestamptz,
  ADD COLUMN IF NOT EXISTS acknowledged_by_name text;

-- The acknowledgment UID and employee membership were already recorded. Keep a
-- display-name snapshot for acknowledgments completed before this migration.
UPDATE employee_asset ea
   SET acknowledged_by_name = m.full_name
  FROM organization_member m
 WHERE m.id = ea.employee_member_id
   AND m.auth_uid = ea.acknowledged_by_uid
   AND ea.acknowledgement_status = 'acknowledged'
   AND ea.acknowledged_by_name IS NULL;
