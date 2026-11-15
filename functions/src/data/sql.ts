import { isUniqueViolation } from "../db";
import type { SqlExecutor } from "../db/executor";
import { conflict, invalid, notFound } from "../errors";
import { parseDate } from "./vars";

type Row = Record<string, unknown>;

/** Converts driver values (Date) to the JSON contract (ISO strings), recursively. */
export function clean<T>(value: T): T {
  if (value instanceof Date) return value.toISOString() as unknown as T;
  if (Array.isArray(value)) return value.map(clean) as unknown as T;
  if (value && typeof value === "object") {
    const out: Row = {};
    for (const [k, v] of Object.entries(value as Row)) out[k] = clean(v);
    return out as T;
  }
  return value;
}

export async function select<T = Row>(
  db: SqlExecutor,
  sql: string,
  params: readonly unknown[] = [],
): Promise<T[]> {
  return (await db.query<T>(sql, params)).map(clean);
}

export async function selectOne<T = Row>(
  db: SqlExecutor,
  sql: string,
  params: readonly unknown[] = [],
): Promise<T | null> {
  return (await select<T>(db, sql, params))[0] ?? null;
}

/** `[{_count: n}]`, the Data Connect shape of an ungrouped aggregate. */
export async function countRows(
  db: SqlExecutor,
  sql: string,
  params: readonly unknown[] = [],
): Promise<{ _count: number }[]> {
  const rows = await db.query<{ _count: unknown }>(sql, params);
  return [{ _count: Number(rows[0]?._count ?? 0) }];
}

/** GROUP BY rows whose `_count` is guaranteed numeric. */
export async function groupRows(
  db: SqlExecutor,
  sql: string,
  params: readonly unknown[] = [],
): Promise<Row[]> {
  const rows = await db.query<Row>(sql, params);
  return rows.map((r) => ({ ...clean(r), _count: Number(r._count) }));
}

/** Escapes LIKE wildcards so user text matches literally. */
export function likeContains(text: string): string {
  return `%${text.replace(/[\\%_]/g, "\\$&")}%`;
}

/** Positional-parameter + WHERE builder; unset filters add nothing. */
export class Query {
  readonly params: unknown[] = [];
  private readonly conds: string[] = [];

  bind(value: unknown): string {
    this.params.push(value);
    return `$${this.params.length}`;
  }

  and(cond: string): this {
    this.conds.push(cond);
    return this;
  }

  eq(column: string, value: unknown): this {
    if (value !== undefined && value !== null) this.conds.push(`${column} = ${this.bind(value)}`);
    return this;
  }

  /** Case-insensitive substring match (Data Connect's `contains` was case-sensitive). */
  contains(column: string, text: string | undefined): this {
    if (text !== undefined) this.conds.push(`${column} ILIKE ${this.bind(likeContains(text))}`);
    return this;
  }

  /** Case-insensitive substring match on any of the columns (one bound value). */
  containsAny(columns: string[], text: string | undefined): this {
    if (text !== undefined) {
      const value = this.bind(likeContains(text));
      this.conds.push(`(${columns.map((c) => `${c} ILIKE ${value}`).join(" OR ")})`);
    }
    return this;
  }

  /** Inclusive lower / exclusive upper bound on a timestamp column. */
  period(column: string, from?: string, to?: string): this {
    if (from !== undefined) this.conds.push(`${column} >= ${this.bind(from)}::timestamptz`);
    if (to !== undefined) this.conds.push(`${column} < ${this.bind(to)}::timestamptz`);
    return this;
  }

  get where(): string {
    return this.conds.length ? `WHERE ${this.conds.join(" AND ")}` : "";
  }
}

/** One page of rows plus the unpaged total in the `[{_count}]` shape. */
export async function paged<T = Row>(
  db: SqlExecutor,
  spec: { columns: string; from: string; q: Query; orderBy: string; limit: number; offset: number },
): Promise<{ rows: T[]; total: { _count: number }[] }> {
  const { q } = spec;
  const total = await countRows(
    db,
    `SELECT count(*)::int AS "_count" FROM ${spec.from} ${q.where}`,
    q.params,
  );
  const lim = q.bind(spec.limit);
  const off = q.bind(spec.offset);
  const rows = await select<T>(
    db,
    `SELECT ${spec.columns} FROM ${spec.from} ${q.where} ORDER BY ${spec.orderBy} LIMIT ${lim} OFFSET ${off}`,
    q.params,
  );
  return { rows, total };
}

/** Raw SQL expression usable as an insert value. */
export class Raw {
  constructor(readonly sql: string) {}
}
export const raw = (sql: string): Raw => new Raw(sql);

export interface DbErrorMessages {
  unique?: string;
  fk?: string;
}

export function mapDbError(e: unknown, messages: DbErrorMessages): unknown {
  const code = (e as { code?: string } | null)?.code;
  if (code === "23503" && messages.fk) return notFound(messages.fk);
  if (messages.unique && isUniqueViolation(e)) return conflict(messages.unique);
  return e;
}

/**
 * Inserts one row and returns `{ id }`. `undefined` values are omitted so
 * column defaults apply. Unique / foreign-key violations become domain errors.
 */
export async function insertReturningId(
  db: SqlExecutor,
  table: string,
  values: [column: string, value: unknown, cast?: string][],
  messages: DbErrorMessages = {},
): Promise<{ id: string }> {
  const cols: string[] = [];
  const exprs: string[] = [];
  const params: unknown[] = [];
  for (const [column, value, cast] of values) {
    if (value === undefined) continue;
    cols.push(column);
    if (value instanceof Raw) {
      exprs.push(value.sql);
    } else {
      params.push(value);
      exprs.push(`$${params.length}${cast ? `::${cast}` : ""}`);
    }
  }
  try {
    const rows = await db.query<{ id: string }>(
      `INSERT INTO ${table} (${cols.join(", ")}) VALUES (${exprs.join(", ")}) RETURNING id`,
      params,
    );
    return { id: rows[0].id };
  } catch (e) {
    throw mapDbError(e, messages);
  }
}

export type FieldKind = "string" | "int" | "float" | "bool" | "date";

export interface UpdateField {
  key: string;
  column: string;
  kind: FieldKind;
  nullable?: boolean;
  min?: number;
  max?: number;
}

function parseNumber(field: UpdateField, v: unknown): number {
  const min = field.min ?? -1e12;
  const max = field.max ?? 1e12;
  if (typeof v !== "number" || !Number.isFinite(v) || v < min || v > max) {
    throw invalid(`${field.key} must be a number between ${min} and ${max}.`);
  }
  if (field.kind === "int" && !Number.isInteger(v)) {
    throw invalid(`${field.key} must be an integer.`);
  }
  return v;
}

function parseField(field: UpdateField, v: unknown): unknown {
  switch (field.kind) {
    case "string": {
      if (typeof v !== "string") throw invalid(`${field.key} must be text.`);
      const t = v.trim();
      const min = field.min ?? (field.nullable ? 0 : 1);
      const max = field.max ?? 500;
      if (t.length < min || t.length > max) {
        throw invalid(`${field.key} must be between ${min} and ${max} characters.`);
      }
      return t;
    }
    case "int":
    case "float":
      return parseNumber(field, v);
    case "bool":
      if (typeof v !== "boolean") throw invalid(`${field.key} must be true or false.`);
      return v;
    case "date":
      return parseDate(v, field.key);
  }
}

/**
 * Partial update by id, returning `{ id }` or null when no row matched.
 * Data Connect semantics: an omitted variable leaves the column alone; an
 * explicit null clears a nullable column (ignored for NOT NULL columns).
 */
export async function updateById(
  db: SqlExecutor,
  table: string,
  id: string,
  fields: UpdateField[],
  bag: Row,
  messages: DbErrorMessages = {},
): Promise<{ id: string } | null> {
  const sets: string[] = [];
  const params: unknown[] = [id];
  for (const f of fields) {
    const v = bag[f.key];
    if (v === undefined) continue;
    if (v === null) {
      if (f.nullable) sets.push(`${f.column} = NULL`);
      continue;
    }
    params.push(parseField(f, v));
    sets.push(`${f.column} = $${params.length}${f.kind === "date" ? "::date" : ""}`);
  }
  const sql = sets.length
    ? `UPDATE ${table} SET ${sets.join(", ")} WHERE id = $1 RETURNING id`
    : `SELECT id FROM ${table} WHERE id = $1`;
  try {
    const rows = await db.query<{ id: string }>(sql, params);
    return rows[0] ? { id: rows[0].id } : null;
  } catch (e) {
    throw mapDbError(e, messages);
  }
}
