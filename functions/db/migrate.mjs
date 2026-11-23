// Applies functions/db/migrations/*.sql in filename order and records each in
// schema_migrations. Uses the same env vars as src/db/connection.ts:
//   DB_MODE=cloudsql|tcp, DB_NAME, DB_USER, and
//   cloudsql: DB_INSTANCE_CONNECTION_NAME (IAM auth, no password)
//   tcp:      DB_HOST, DB_PORT, DB_PASSWORD, DB_SSL (true | no-verify | false,
//             default true = verify the certificate), DB_SSL_CA (private CA PEM)
// Optional DB_MIGRATION_ROLE: run every migration as this role (SET ROLE) so
// new objects get its owner and default privileges (CI uses the table owner).
// Run from functions/:  node db/migrate.mjs
import { readdir, readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import pg from "pg";

const env = process.env;
const mode = env.DB_MODE ?? "cloudsql";
const need = (key) => {
  if (!env[key]) throw new Error(`${key} is not configured.`);
  return env[key];
};

async function connect() {
  const base = { database: need("DB_NAME"), user: need("DB_USER"), max: 1 };
  if (mode === "cloudsql") {
    const { AuthTypes, Connector, IpAddressTypes } = await import(
      "@google-cloud/cloud-sql-connector"
    );
    const connector = new Connector();
    const options = await connector.getOptions({
      instanceConnectionName: need("DB_INSTANCE_CONNECTION_NAME"),
      ipType: IpAddressTypes.PUBLIC,
      authType: AuthTypes.IAM,
    });
    const pool = new pg.Pool({ ...base, ...options });
    return { pool, close: async () => { await pool.end(); connector.close(); } };
  }
  if (mode !== "tcp") throw new Error(`DB_MODE must be "cloudsql" or "tcp", got "${mode}".`);
  const pool = new pg.Pool({
    ...base,
    host: need("DB_HOST"),
    port: env.DB_PORT ? Number(env.DB_PORT) : 5432,
    password: need("DB_PASSWORD"),
    ssl: tcpSsl(),
  });
  return { pool, close: () => pool.end() };
}

// Same rules as tcpSslOptions in src/db/connection.ts.
function tcpSsl() {
  const raw = env.DB_SSL ?? "true";
  if (raw === "false") return false;
  if (raw === "no-verify") {
    console.warn("DB_SSL=no-verify: the database server certificate is not verified.");
    return { rejectUnauthorized: false };
  }
  if (raw !== "true") throw new Error(`DB_SSL must be "true", "no-verify" or "false", got "${raw}".`);
  return env.DB_SSL_CA ? { rejectUnauthorized: true, ca: env.DB_SSL_CA } : { rejectUnauthorized: true };
}

const dir = join(dirname(fileURLToPath(import.meta.url)), "migrations");
const files = (await readdir(dir)).filter((f) => f.endsWith(".sql")).sort();
const { pool, close } = await connect();
const client = await pool.connect();
try {
  if (env.DB_MIGRATION_ROLE) {
    await client.query(`SET ROLE ${client.escapeIdentifier(env.DB_MIGRATION_ROLE)}`);
  }
  await client.query(`CREATE TABLE IF NOT EXISTS schema_migrations (
    name text PRIMARY KEY,
    applied_at timestamptz NOT NULL DEFAULT now()
  )`);
  const done = new Set(
    (await client.query("SELECT name FROM schema_migrations")).rows.map((r) => r.name),
  );
  for (const file of files) {
    if (done.has(file)) {
      console.log(`skip   ${file}`);
      continue;
    }
    const sql = await readFile(join(dir, file), "utf8");
    try {
      await client.query("BEGIN");
      await client.query(sql);
      await client.query("INSERT INTO schema_migrations (name) VALUES ($1)", [file]);
      await client.query("COMMIT");
      console.log(`apply  ${file}`);
    } catch (e) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw new Error(`Migration ${file} failed: ${e.message}`);
    }
  }
} finally {
  client.release();
  await close();
}
