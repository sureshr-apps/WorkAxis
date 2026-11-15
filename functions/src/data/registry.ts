import type { OperationRegistry } from "./operation";
import { branchesOps } from "./ops/branches";
import { commercialOps } from "./ops/commercial";
import { dashboardsOps } from "./ops/dashboards";
import { membersOps } from "./ops/members";
import { organizationsOps } from "./ops/organizations";
import { returnsOps } from "./ops/returns";

/** Every operation reachable through the `dataOp` callable, by name. */
export const operations: OperationRegistry = {
  ...organizationsOps,
  ...branchesOps,
  ...membersOps,
  ...returnsOps,
  ...dashboardsOps,
  ...commercialOps,
};
