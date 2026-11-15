-- ============================================================================
-- WorkAxis Initial Data Seeding Script (PostgreSQL / Cloud SQL)
-- Database: workaxis
-- Instance: omniretail-sql (asia-south1)
-- ============================================================================

BEGIN;

-- 1. Organizations
INSERT INTO organization (id, name, code, category, country, status, currency, logo_url, created_at)
VALUES
  ('org-acme', 'Acme Corporation', 'ORG-ACM-01', 'Retail', 'India', 'active', 'INR', NULL, '2024-09-14 10:00:00+00'),
  ('org-apex', 'Apex Logistics & Freight', 'ORG-APX-01', 'Logistics', 'India', 'active', 'INR', NULL, '2024-10-12 10:00:00+00'),
  ('org-crest', 'Crestline Retailers', 'ORG-CRS-03', 'Apparel', 'India', 'suspended', 'INR', NULL, '2024-11-01 10:00:00+00')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  code = EXCLUDED.code,
  category = EXCLUDED.category,
  country = EXCLUDED.country,
  status = EXCLUDED.status,
  currency = EXCLUDED.currency;

-- 2. Commercial Agreements
INSERT INTO commercial_agreement (id, organization_id, agreement_reference, plan_name, plan_tier, negotiated_price, annual_maintenance_price, max_stores, max_users, start_date, expiry_date, status, created_at)
VALUES
  ('agr-acme-01', 'org-acme', 'AGR-ORG-ACM-01', 'Basic', 'Level 1', 40000.0, 5000.0, 18, 540, '2026-11-07', '2027-11-07', 'active', '2026-11-07 10:00:00+00'),
  ('agr-apex-01', 'org-apex', 'AGR-ORG-APX-01', 'Standard', 'Level 2', 65000.0, 8500.0, 14, 420, '2026-10-12', '2027-10-12', 'active', '2026-10-12 10:00:00+00')
ON CONFLICT (id) DO UPDATE SET
  plan_name = EXCLUDED.plan_name,
  plan_tier = EXCLUDED.plan_tier,
  negotiated_price = EXCLUDED.negotiated_price,
  annual_maintenance_price = EXCLUDED.annual_maintenance_price,
  max_stores = EXCLUDED.max_stores,
  max_users = EXCLUDED.max_users,
  start_date = EXCLUDED.start_date,
  expiry_date = EXCLUDED.expiry_date,
  status = EXCLUDED.status;

-- 3. License Audit Events
INSERT INTO license_event (id, organization_id, event_type, plan_name, plan_tier, validity_period, stores_count, users_count, one_time_price, annual_maintenance_price, created_at)
VALUES
  ('evt-acme-01', 'org-acme', 'LICENSE_ASSIGNED', 'Basic', 'Level 1', '2026-11-07 to 2027-11-07', 18, 540, 40000.0, 5000.0, '2026-11-07 10:45:00+00'),
  ('evt-apex-01', 'org-apex', 'LICENSE_ASSIGNED', 'Standard', 'Level 2', '2026-10-12 to 2027-10-12', 14, 420, 65000.0, 8500.0, '2026-10-12 10:00:00+00')
ON CONFLICT (id) DO UPDATE SET
  event_type = EXCLUDED.event_type,
  plan_name = EXCLUDED.plan_name,
  plan_tier = EXCLUDED.plan_tier,
  validity_period = EXCLUDED.validity_period,
  stores_count = EXCLUDED.stores_count,
  users_count = EXCLUDED.users_count,
  one_time_price = EXCLUDED.one_time_price,
  annual_maintenance_price = EXCLUDED.annual_maintenance_price;

-- 4. Branches
INSERT INTO branch (id, organization_id, code, name, location, status, is_main_branch, geofence_radius_meters, latitude, longitude, kiosk_enabled, created_at)
VALUES
  ('br-acme-01', 'org-acme', 'ACM-DT-01', 'Downtown Flagship', 'Sector 8, Industrial Corridor', 'active', TRUE, 125, 12.9716, 77.5946, TRUE, '2026-11-07 10:00:00+00'),
  ('br-acme-02', 'org-acme', 'ACM-MH-02', 'Metro Hub', 'Connaught Place', 'active', FALSE, 150, 28.6315, 77.2167, FALSE, '2026-11-07 10:00:00+00'),
  ('br-acme-03', 'org-acme', 'ACM-WE-03', 'West End Outlet', 'Bandra West', 'active', FALSE, 100, 19.0760, 72.8777, TRUE, '2026-11-07 10:00:00+00'),
  ('br-apex-01', 'org-apex', 'APX-CD-01', 'Central Depot', 'Mount Road', 'active', TRUE, 200, 13.0827, 80.2707, TRUE, '2026-10-12 10:00:00+00')
ON CONFLICT (id) DO UPDATE SET
  code = EXCLUDED.code,
  name = EXCLUDED.name,
  location = EXCLUDED.location,
  status = EXCLUDED.status,
  is_main_branch = EXCLUDED.is_main_branch,
  geofence_radius_meters = EXCLUDED.geofence_radius_meters,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude,
  kiosk_enabled = EXCLUDED.kiosk_enabled;

-- 5. Organization Members
-- auth_uid is the Firebase Auth uid and is intentionally NULL here: seed rows
-- have no Auth identity yet. Link each one after creating the Auth user, e.g.
--   UPDATE organization_member SET auth_uid = '<firebase-uid>' WHERE id = 'usr-acme-admin';
-- New users should be created through the provisionUser Cloud Function, which
-- sets auth_uid and the custom claims atomically from the caller's view.
INSERT INTO organization_member (id, organization_id, auth_uid, full_name, username, email, phone, role, status, created_at)
VALUES
  ('usr-acme-admin', 'org-acme', NULL, 'David Warner', 'david.warner', 'd.warner@acmecorp.com', '+919876543210', 'orgAdmin', 'active', '2026-11-07 10:00:00+00'),
  ('usr-acme-bm', 'org-acme', NULL, 'Marcus Chen', 'marcus.chen', 'm.chen@acmecorp.com', '+919876543211', 'branchManager', 'active', '2026-11-07 10:00:00+00'),
  ('usr-acme-emp', 'org-acme', NULL, 'Alex Rivera', 'alex.rivera', 'a.rivera@acmecorp.com', '+919876543212', 'employee', 'active', '2026-11-07 10:00:00+00'),
  ('usr-apex-admin', 'org-apex', NULL, 'Marcus Sterling', 'marcus.sterling', 'operations@apexlogistics.com', '+919876543213', 'orgAdmin', 'active', '2026-10-12 10:00:00+00')
ON CONFLICT (id) DO UPDATE SET
  -- auth_uid is deliberately not overwritten so re-seeding keeps linked uids.
  full_name = EXCLUDED.full_name,
  username = EXCLUDED.username,
  email = EXCLUDED.email,
  phone = EXCLUDED.phone,
  role = EXCLUDED.role,
  status = EXCLUDED.status;

-- 6. User Branch Assignments
INSERT INTO user_branch_assignment (id, member_id, branch_id, assigned_at)
VALUES
  ('asgn-01', 'usr-acme-bm', 'br-acme-01', '2026-11-07 10:00:00+00'),
  ('asgn-02', 'usr-acme-bm', 'br-acme-02', '2026-11-07 10:00:00+00'),
  ('asgn-03', 'usr-acme-emp', 'br-acme-01', '2026-11-07 10:00:00+00')
ON CONFLICT (id) DO UPDATE SET
  member_id = EXCLUDED.member_id,
  branch_id = EXCLUDED.branch_id;

-- 7. Returns (Sample Data)
INSERT INTO return_record (id, organization_id, branch_id, employee_id, employee_name, customer_name, product_title, quantity, unit, invoice_number, return_reason, amount, status, created_at)
VALUES
  ('ret-01', 'org-acme', 'br-acme-01', 'usr-acme-emp', 'Alex Rivera', 'Priya Sharma', 'Winter jacket', 1, 'pcs', 'INV-2026-0042', 'Defective zipper on winter jacket', 3499.00, 'pending', '2026-11-07 11:15:00+00'),
  ('ret-02', 'org-acme', 'br-acme-01', 'usr-acme-emp', 'Alex Rivera', 'Vikram Patel', 'Running shoes', 1, 'pairs', 'INV-2026-0048', 'Incorrect shoe size 9 vs 10', 5299.00, 'approved', '2026-11-07 12:30:00+00')
ON CONFLICT (id) DO UPDATE SET
  employee_id = EXCLUDED.employee_id,
  employee_name = EXCLUDED.employee_name,
  customer_name = EXCLUDED.customer_name,
  product_title = EXCLUDED.product_title,
  quantity = EXCLUDED.quantity,
  unit = EXCLUDED.unit,
  invoice_number = EXCLUDED.invoice_number,
  return_reason = EXCLUDED.return_reason,
  amount = EXCLUDED.amount,
  status = EXCLUDED.status;

COMMIT;
