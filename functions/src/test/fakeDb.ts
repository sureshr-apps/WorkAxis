import type { SqlExecutor } from "../db/executor";

export interface RecordedCall {
  sql: string;
  params: readonly unknown[];
}

type Responder = (call: RecordedCall) => Record<string, unknown>[] | undefined;

/**
 * Scripted [SqlExecutor] for unit tests. Register responders with [when];
 * the first responder returning rows wins, otherwise the query returns [].
 * Every statement is recorded in [calls], including those inside
 * transactions ([transactions] counts how many were opened).
 */
export class FakeDb implements SqlExecutor {
  readonly calls: RecordedCall[] = [];
  transactions = 0;
  private readonly responders: Responder[] = [];

  /** Rows returned when the SQL text contains [fragment] (case-insensitive). */
  when(fragment: string, rows: Record<string, unknown>[]): this {
    const needle = fragment.toLowerCase();
    this.responders.push((c) => (c.sql.toLowerCase().includes(needle) ? rows : undefined));
    return this;
  }

  whenCall(responder: Responder): this {
    this.responders.push(responder);
    return this;
  }

  async query<T = Record<string, unknown>>(
    sql: string,
    params: readonly unknown[] = [],
  ): Promise<T[]> {
    const call = { sql, params };
    this.calls.push(call);
    for (const r of this.responders) {
      const rows = r(call);
      if (rows) return rows as T[];
    }
    return [];
  }

  async transaction<T>(work: (tx: SqlExecutor) => Promise<T>): Promise<T> {
    this.transactions += 1;
    return work(this);
  }
}
