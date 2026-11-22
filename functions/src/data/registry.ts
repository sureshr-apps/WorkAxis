import type { OperationRegistry } from "./operation";
import { assetsOps } from "./ops/assets";
import { branchesOps } from "./ops/branches";
import { dashboardsOps } from "./ops/dashboards";
import { leavesOps } from "./ops/leaves";
import { licensePlanOps } from "./ops/licensePlans";
import { membersOps } from "./ops/members";
import { organizationLicenseOps } from "./ops/organizationLicenses";
import { organizationsOps } from "./ops/organizations";
import { offSiteWorkOps } from "./ops/offSiteWork";
import { returnsOps } from "./ops/returns";
import { workforceOps } from "./ops/workforce";
import { payrollOps } from "./ops/payroll";

/** Every operation reachable through the `dataOp` callable, by name. */
export const operations: OperationRegistry = {
  ...organizationsOps,
  ...branchesOps,
  ...assetsOps,
  ...membersOps,
  ...returnsOps,
  ...leavesOps,
  ...offSiteWorkOps,
  ...dashboardsOps,
  ...licensePlanOps,
  ...organizationLicenseOps,
  ...workforceOps,
  ...payrollOps,
};
