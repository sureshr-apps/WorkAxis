import type { OperationRegistry } from "./operation";
import { assetsOps } from "./ops/assets";
import { branchesOps } from "./ops/branches";
import { dashboardsOps } from "./ops/dashboards";
import { licensePlanOps } from "./ops/licensePlans";
import { membersOps } from "./ops/members";
import { organizationLicenseOps } from "./ops/organizationLicenses";
import { organizationsOps } from "./ops/organizations";
import { returnsOps } from "./ops/returns";

/** Every operation reachable through the `dataOp` callable, by name. */
export const operations: OperationRegistry = {
  ...organizationsOps,
  ...branchesOps,
  ...assetsOps,
  ...membersOps,
  ...returnsOps,
  ...dashboardsOps,
  ...licensePlanOps,
  ...organizationLicenseOps,
};
