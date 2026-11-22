CREATE TABLE IF NOT EXISTS employee_schedule_history (
  id text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  member_id text NOT NULL REFERENCES organization_member(id) ON DELETE CASCADE,
  effective_from date NOT NULL,
  effective_to date,
  daily_work_hours numeric(4,2) NOT NULL CHECK (daily_work_hours >= 0.5 AND daily_work_hours <= 24),
  shift_hours text NOT NULL,
  weekly_day_off smallint NOT NULL CHECK (weekly_day_off BETWEEN 0 AND 6),
  created_by_uid text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (effective_to IS NULL OR effective_to > effective_from),
  UNIQUE (member_id, effective_from)
);

CREATE INDEX IF NOT EXISTS employee_schedule_history_effective_idx
  ON employee_schedule_history (member_id, effective_from DESC, effective_to);

CREATE TABLE IF NOT EXISTS employee_compensation_history (
  id text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  member_id text NOT NULL REFERENCES organization_member(id) ON DELETE CASCADE,
  effective_from date NOT NULL,
  effective_to date,
  monthly_salary numeric(12,2) NOT NULL CHECK (monthly_salary >= 0),
  created_by_uid text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (effective_to IS NULL OR effective_to > effective_from),
  UNIQUE (member_id, effective_from)
);

CREATE INDEX IF NOT EXISTS employee_compensation_history_effective_idx
  ON employee_compensation_history (member_id, effective_from DESC, effective_to);
