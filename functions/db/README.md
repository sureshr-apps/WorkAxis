# Database migrations

Plain PostgreSQL migrations for the WorkAxis relational core. Files in
`migrations/` are applied in filename order and recorded in the
`schema_migrations` table, so each runs once.

`001_init.sql` is idempotent (`IF NOT EXISTS` everywhere) and never alters
existing columns, so it is safe to run against the live database that Data
Connect originally created.

## Applying

From `functions/`, with the same environment variables the functions use:

```bash
# Cloud SQL (IAM database auth, no password). The caller needs Cloud SQL Client
# and an IAM database user with CREATE on the schema.
DB_MODE=cloudsql DB_INSTANCE_CONNECTION_NAME=project:region:instance \
DB_NAME=workaxis DB_USER=you@example.com node db/migrate.mjs

# Any Postgres reachable over TCP
DB_MODE=tcp DB_HOST=127.0.0.1 DB_PORT=5432 DB_NAME=workaxis \
DB_USER=postgres DB_PASSWORD=... DB_SSL=false node db/migrate.mjs
```

`002_employee_codes.sql` adds `organization.employee_code_seq` and
`organization_member.employee_code` (unique per organization) and backfills
codes (`EMP-10001`, ...) for existing members in `created_at` order. It is
idempotent; re-running assigns nothing new.

Add new changes as `002_*.sql`, `003_*.sql`, ... and never edit an applied file.

## Grants for the runtime database user

The functions need only data access, not DDL. Run once as the table owner
(replace `fn_user` with the IAM database user / role the functions connect as):

```sql
GRANT CONNECT ON DATABASE workaxis TO fn_user;
GRANT USAGE ON SCHEMA public TO fn_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO fn_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO fn_user;
-- Tables created by later migrations:
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO fn_user;
```

If the tables were created by Data Connect, the owner is the Data Connect
database user; run the grants as that user (or `postgres`).
