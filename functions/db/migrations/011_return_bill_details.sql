-- Bill number and business return date entered on the submit-return form.
-- Both are nullable: rows created before this migration never captured them,
-- and readers fall back to the invoice number and created_at respectively.
ALTER TABLE return_record
  ADD COLUMN IF NOT EXISTS bill_number text,
  ADD COLUMN IF NOT EXISTS return_date date;
