/**
 * The only database contract the rest of the backend depends on.
 *
 * Handlers and data operations speak plain parameterised SQL (`$1`, `$2`, ...)
 * through this interface. Where the database lives (Cloud SQL, a VM, a test
 * double) is decided once in `connection.ts`, so moving hosts never touches
 * business code.
 */
export interface SqlExecutor {
  /** Runs one statement and returns its rows (empty for statements without). */
  query<T = Record<string, unknown>>(
    sql: string,
    params?: readonly unknown[],
  ): Promise<T[]>;

  /**
   * Runs [work] inside one transaction: committed when it resolves, rolled
   * back when it throws. The executor passed to [work] is bound to that
   * transaction and must not be used after [work] settles.
   */
  transaction<T>(work: (tx: SqlExecutor) => Promise<T>): Promise<T>;
}
