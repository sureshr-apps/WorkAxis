-- Employees may have several recurring weekly days off (or none). The list
-- replaces the former single weekly_day_off column.
ALTER TABLE employee_schedule_history
  ADD COLUMN weekly_days_off smallint[] NOT NULL DEFAULT ARRAY[]::smallint[];

UPDATE employee_schedule_history
   SET weekly_days_off = ARRAY[weekly_day_off];

ALTER TABLE employee_schedule_history
  ADD CONSTRAINT employee_schedule_history_weekly_days_off_valid
  CHECK (weekly_days_off <@ ARRAY[0, 1, 2, 3, 4, 5, 6]::smallint[]);

ALTER TABLE employee_schedule_history DROP COLUMN weekly_day_off;
