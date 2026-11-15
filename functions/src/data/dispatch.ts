import { invalid } from "../errors";
import { asBag } from "../util/input";
import type { OperationContext, OperationRegistry } from "./operation";

/** Looks up and runs one operation. Pure apart from the operation itself. */
export async function runOperation(
  registry: OperationRegistry,
  ctx: OperationContext,
  request: unknown,
): Promise<unknown> {
  const bag = asBag(request);
  const name = bag.op;
  if (typeof name !== "string" || !Object.hasOwn(registry, name)) {
    throw invalid("Unknown operation.");
  }
  const vars = bag.vars === undefined ? {} : asBag(bag.vars);
  return registry[name](ctx, vars);
}
