import { initializeApp } from "firebase-admin/app";

initializeApp();

export { createKioskPairingToken } from "./handlers/createKioskPairingToken";
export { provisionUser } from "./handlers/provisionUser";
export { recordAttendancePunch } from "./handlers/recordAttendancePunch";
export { getAttendanceSelfiePolicy } from "./handlers/getAttendanceSelfiePolicy";
export { resetUserPassword } from "./handlers/resetUserPassword";
export { resolveLoginIdentifier } from "./handlers/resolveLoginIdentifier";
export { setOrganizationStatus } from "./handlers/setOrganizationStatus";
export { deleteOrganization } from "./handlers/deleteOrganization";
export { setUserStatus } from "./handlers/setUserStatus";
export { deletePlatformAdministrator } from "./handlers/deletePlatformAdministrator";
export { deleteOrganizationAdmin } from "./handlers/deleteOrganizationAdmin";
export { deleteOrganizationMember } from "./handlers/deleteOrganizationMember";
export { updateUserAccount } from "./handlers/updateUserAccount";

export { recordGroupAttendance } from "./handlers/recordGroupAttendance";

export { reconcileIdentitySync } from "./accounts/identitySync";

export { saveBranch } from "./handlers/saveBranch";
export { deleteBranch } from "./handlers/deleteBranch";
export { dataOp } from "./handlers/dataOp";
