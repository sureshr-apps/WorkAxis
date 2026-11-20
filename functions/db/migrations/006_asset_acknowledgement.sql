-- Employee receipt acknowledgments belong to the relational asset record.
-- Existing assignments remain not_required; the organization setting applies
-- to assignments created or transferred after the flag is enabled.
ALTER TABLE employee_asset
  ADD COLUMN acknowledgement_required boolean NOT NULL DEFAULT false,
  ADD COLUMN acknowledgement_status text NOT NULL DEFAULT 'not_required',
  ADD COLUMN acknowledged_at timestamptz,
  ADD COLUMN acknowledged_by_uid text,
  ADD CONSTRAINT employee_asset_acknowledgement_status_valid
    CHECK (acknowledgement_status IN ('not_required', 'pending', 'acknowledged')),
  ADD CONSTRAINT employee_asset_acknowledgement_state_valid
    CHECK (
      (NOT acknowledgement_required
        AND acknowledgement_status = 'not_required'
        AND acknowledged_at IS NULL
        AND acknowledged_by_uid IS NULL)
      OR
      (acknowledgement_required
        AND acknowledgement_status = 'pending'
        AND acknowledged_at IS NULL
        AND acknowledged_by_uid IS NULL)
      OR
      (acknowledgement_required
        AND acknowledgement_status = 'acknowledged'
        AND acknowledged_at IS NOT NULL
        AND acknowledged_by_uid IS NOT NULL)
    );

CREATE INDEX idx_employee_asset_pending_acknowledgements
  ON employee_asset (organization_id, branch_id, employee_member_id)
  WHERE acknowledgement_status = 'pending';
