-- Retry-safe creates. A client sends a requestId with each create; the server
-- stores sha256(callerUid:organizationId:requestId) as creation_request_key and
-- a hash of the validated payload as creation_fingerprint. A retried request
-- finds the existing row(s) and returns them instead of inserting again.
-- Rows created without a requestId (older clients) leave the columns null.

ALTER TABLE return_record
  ADD COLUMN IF NOT EXISTS creation_request_key text,
  ADD COLUMN IF NOT EXISTS creation_line smallint,
  ADD COLUMN IF NOT EXISTS creation_fingerprint text;

-- One bill (one request) creates several lines, numbered by creation_line.
CREATE UNIQUE INDEX IF NOT EXISTS uq_return_record_creation
  ON return_record (creation_request_key, creation_line)
  WHERE creation_request_key IS NOT NULL;

ALTER TABLE leave_request
  ADD COLUMN IF NOT EXISTS creation_request_key text,
  ADD COLUMN IF NOT EXISTS creation_fingerprint text;

CREATE UNIQUE INDEX IF NOT EXISTS uq_leave_request_creation
  ON leave_request (creation_request_key)
  WHERE creation_request_key IS NOT NULL;

ALTER TABLE off_site_work_assignment
  ADD COLUMN IF NOT EXISTS creation_request_key text,
  ADD COLUMN IF NOT EXISTS creation_fingerprint text;

CREATE UNIQUE INDEX IF NOT EXISTS uq_off_site_work_assignment_creation
  ON off_site_work_assignment (creation_request_key)
  WHERE creation_request_key IS NOT NULL;
