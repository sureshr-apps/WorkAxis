-- Off-site assignments and their milestone history are separate from attendance.
-- GPS is stored only on explicit assignment events; the application never writes
-- route or background location samples.
CREATE TABLE IF NOT EXISTS off_site_work_assignment (
  id                            text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  organization_id               text NOT NULL REFERENCES organization (id) ON DELETE CASCADE,
  branch_id                     text NOT NULL,
  branch_name                   text NOT NULL,
  employee_member_id            text NOT NULL,
  employee_uid                  text NOT NULL,
  employee_name                 text NOT NULL,
  assigned_by_uid               text NOT NULL,
  assigned_by_name              text NOT NULL,
  title                         text NOT NULL CHECK (length(title) BETWEEN 1 AND 120),
  instructions                  text,
  destination                   text NOT NULL CHECK (length(destination) BETWEEN 1 AND 250),
  due_at                        timestamptz,
  reference                     text,
  required_evidence_description text,
  status                        text NOT NULL DEFAULT 'assigned'
                                  CHECK (status IN (
                                    'assigned', 'in_progress', 'arrived',
                                    'completed', 'unable_to_complete', 'returned'
                                  )),
  latest_latitude               double precision,
  latest_longitude              double precision,
  latest_accuracy_meters        double precision,
  latest_milestone_at           timestamptz,
  created_at                    timestamptz NOT NULL DEFAULT now(),
  updated_at                    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT off_site_work_branch_org_fk
    FOREIGN KEY (branch_id, organization_id)
    REFERENCES branch (id, organization_id) ON DELETE RESTRICT,
  CONSTRAINT off_site_work_employee_org_fk
    FOREIGN KEY (employee_member_id, organization_id)
    REFERENCES organization_member (id, organization_id) ON DELETE RESTRICT,
  CONSTRAINT off_site_work_latest_location_valid CHECK (
    (latest_latitude IS NULL AND latest_longitude IS NULL AND latest_accuracy_meters IS NULL)
    OR (latest_latitude BETWEEN -90 AND 90 AND latest_longitude BETWEEN -180 AND 180
        AND latest_accuracy_meters >= 0)
  )
);

CREATE TABLE IF NOT EXISTS off_site_work_event (
  id                  text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  assignment_id       text NOT NULL REFERENCES off_site_work_assignment (id) ON DELETE CASCADE,
  event_type          text NOT NULL CHECK (event_type IN (
                        'assigned', 'started', 'arrived', 'completed',
                        'unable_to_complete', 'returned_to_branch'
                      )),
  actor_uid           text NOT NULL,
  actor_name          text NOT NULL,
  occurred_at         timestamptz NOT NULL DEFAULT now(),
  latitude            double precision,
  longitude           double precision,
  accuracy_meters     double precision,
  note                text,
  evidence_references text[] NOT NULL DEFAULT '{}',
  CONSTRAINT off_site_work_event_location_valid CHECK (
    (latitude IS NULL AND longitude IS NULL AND accuracy_meters IS NULL)
    OR (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180
        AND accuracy_meters >= 0)
  ),
  CONSTRAINT off_site_work_assignment_event_valid CHECK (
    (event_type = 'assigned' AND latitude IS NULL AND longitude IS NULL AND accuracy_meters IS NULL)
    OR (event_type <> 'assigned' AND latitude IS NOT NULL AND longitude IS NOT NULL
        AND accuracy_meters IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_off_site_work_org_created
  ON off_site_work_assignment (organization_id, created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_off_site_work_branch_created
  ON off_site_work_assignment (branch_id, created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_off_site_work_employee_created
  ON off_site_work_assignment (employee_uid, created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_off_site_work_event_assignment
  ON off_site_work_event (assignment_id, occurred_at, id);
