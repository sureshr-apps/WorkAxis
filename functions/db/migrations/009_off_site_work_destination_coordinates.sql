ALTER TABLE off_site_work_assignment
  ADD COLUMN destination_latitude double precision,
  ADD COLUMN destination_longitude double precision,
  ADD CONSTRAINT off_site_work_destination_coordinates_valid CHECK (
    (destination_latitude IS NULL AND destination_longitude IS NULL)
    OR (destination_latitude IS NOT NULL AND destination_longitude IS NOT NULL
        AND destination_latitude BETWEEN -90 AND 90
        AND destination_longitude BETWEEN -180 AND 180)
  );
