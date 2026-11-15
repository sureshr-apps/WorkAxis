import { AuthTypes, Connector, IpAddressTypes } from "@google-cloud/cloud-sql-connector";
import { Pool, types, type PoolConfig } from "pg";

/**
 * Database host selection. This file is the whole "where is Postgres" story.
 *
 * DB_MODE=cloudsql  Cloud SQL through the Cloud SQL connector with IAM
 *                   database authentication (no password). Works across
 *                   Google projects: grant the function's service account
 *                   Cloud SQL Client and Cloud SQL Instance User on the
 *                   project that owns the instance.
 * DB_MODE=tcp       Any Postgres reachable over TCP (a VM, RDS, a laptop).
 *                   Uses DB_HOST, DB_PORT, DB_USER and DB_PASSWORD.
 *
 * Everything else (DB_NAME, pool size) is shared by both modes.
 */
export interface DbSettings {
  mode: "cloudsql" | "tcp";
  database: string;
  user: string;
  /** cloudsql: "project:region:instance". */
  instanceConnectionName?: string;
  /** tcp only. */
  host?: string;
  port?: number;
  password?: string;
  /** tcp only: require TLS (set false only for a private network). */
  ssl: boolean;
  poolMax: number;
}

export function readDbSettings(env: NodeJS.ProcessEnv = process.env): DbSettings {
  const mode = (env.DB_MODE ?? "cloudsql") as DbSettings["mode"];
  if (mode !== "cloudsql" && mode !== "tcp") {
    throw new Error(`DB_MODE must be "cloudsql" or "tcp", got "${mode}".`);
  }
  const need = (key: string): string => {
    const v = env[key];
    if (!v) throw new Error(`${key} is not configured.`);
    return v;
  };
  return {
    mode,
    database: need("DB_NAME"),
    user: need("DB_USER"),
    instanceConnectionName:
      mode === "cloudsql" ? need("DB_INSTANCE_CONNECTION_NAME") : undefined,
    host: mode === "tcp" ? need("DB_HOST") : undefined,
    port: env.DB_PORT ? Number(env.DB_PORT) : 5432,
    password: mode === "tcp" ? need("DB_PASSWORD") : undefined,
    ssl: env.DB_SSL !== "false",
    // Small on purpose: the instance is shared and tiny.
    poolMax: env.DB_POOL_MAX ? Number(env.DB_POOL_MAX) : 3,
  };
}

let typeParsersInstalled = false;

/** DATE as "YYYY-MM-DD" (no timezone shift) and TIMESTAMPTZ as ISO-8601. */
function installTypeParsers(): void {
  if (typeParsersInstalled) return;
  typeParsersInstalled = true;
  types.setTypeParser(types.builtins.DATE, (v) => v);
  types.setTypeParser(types.builtins.TIMESTAMPTZ, (v) => new Date(v).toISOString());
  types.setTypeParser(types.builtins.TIMESTAMP, (v) => new Date(`${v}Z`).toISOString());
  // count(*) and sum() arrive as bigint/numeric strings; our counts fit in JS numbers.
  types.setTypeParser(types.builtins.INT8, (v) => Number(v));
  types.setTypeParser(types.builtins.NUMERIC, (v) => Number(v));
}

export interface PoolHandle {
  pool: Pool;
  close(): Promise<void>;
}

export async function createPool(settings: DbSettings): Promise<PoolHandle> {
  installTypeParsers();
  const base: PoolConfig = {
    database: settings.database,
    user: settings.user,
    max: settings.poolMax,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 10_000,
  };

  if (settings.mode === "cloudsql") {
    const connector = new Connector();
    const options = await connector.getOptions({
      instanceConnectionName: settings.instanceConnectionName!,
      ipType: IpAddressTypes.PUBLIC,
      authType: AuthTypes.IAM,
    });
    const pool = new Pool({ ...base, ...options });
    return {
      pool,
      close: async () => {
        await pool.end();
        connector.close();
      },
    };
  }

  const pool = new Pool({
    ...base,
    host: settings.host,
    port: settings.port,
    password: settings.password,
    ssl: settings.ssl ? { rejectUnauthorized: false } : false,
  });
  return { pool, close: () => pool.end() };
}
