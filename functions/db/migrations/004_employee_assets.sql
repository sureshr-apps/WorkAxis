-- Employee-owned assets are relational records scoped to one organization,
-- branch, and employee membership.
CREATE UNIQUE INDEX IF NOT EXISTS idx_branch_id_organization
  ON branch (id, organization_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_organization_member_id_organization
  ON organization_member (id, organization_id);

CREATE TABLE IF NOT EXISTS employee_asset (
  id                  text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  organization_id     text NOT NULL REFERENCES organization (id) ON DELETE CASCADE,
  branch_id           text NOT NULL,
  employee_member_id  text NOT NULL,
  name                text NOT NULL,
  category            text NOT NULL,
  asset_tag           text NOT NULL,
  serial_number       text,
  status              text NOT NULL DEFAULT 'assigned',
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT employee_asset_branch_org_fk
    FOREIGN KEY (branch_id, organization_id)
    REFERENCES branch (id, organization_id) ON DELETE CASCADE,
  CONSTRAINT employee_asset_employee_org_fk
    FOREIGN KEY (employee_member_id, organization_id)
    REFERENCES organization_member (id, organization_id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_employee_asset_tag_org
  ON employee_asset (organization_id, lower(asset_tag));
CREATE INDEX IF NOT EXISTS idx_employee_asset_branch_employee
  ON employee_asset (branch_id, employee_member_id, name);
CREATE INDEX IF NOT EXISTS idx_employee_asset_org
  ON employee_asset (organization_id, name);
