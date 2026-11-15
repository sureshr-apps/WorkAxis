import type { Pool, PoolClient } from "pg";
import type { SqlExecutor } from "./executor";

/** [SqlExecutor] over a node-postgres pool. */
export class PgExecutor implements SqlExecutor {
  constructor(private readonly pool: Pool) {}

  async query<T = Record<string, unknown>>(
    sql: string,
    params: readonly unknown[] = [],
  ): Promise<T[]> {
    const res = await this.pool.query(sql, params as unknown[]);
    return res.rows as T[];
  }

  async transaction<T>(work: (tx: SqlExecutor) => Promise<T>): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");
      const result = await work(new ClientExecutor(client));
      await client.query("COMMIT");
      return result;
    } catch (e) {
      await client.query("ROLLBACK").catch(() => undefined);
      throw e;
    } finally {
      client.release();
    }
  }
}

class ClientExecutor implements SqlExecutor {
  constructor(private readonly client: PoolClient) {}

  async query<T = Record<string, unknown>>(
    sql: string,
    params: readonly unknown[] = [],
  ): Promise<T[]> {
    const res = await this.client.query(sql, params as unknown[]);
    return res.rows as T[];
  }

  // Nested calls join the surrounding transaction.
  transaction<T>(work: (tx: SqlExecutor) => Promise<T>): Promise<T> {
    return work(this);
  }
}
