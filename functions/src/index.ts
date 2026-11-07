import { initializeApp } from "firebase-admin/app";

initializeApp();

export { createKioskPairingToken } from "./handlers/createKioskPairingToken";
export { provisionUser } from "./handlers/provisionUser";
export { recordAttendancePunch } from "./handlers/recordAttendancePunch";
export { resetUserPassword } from "./handlers/resetUserPassword";
export { resolveLoginIdentifier } from "./handlers/resolveLoginIdentifier";
export { setOrganizationStatus } from "./handlers/setOrganizationStatus";
export { setUserStatus } from "./handlers/setUserStatus";
export { updateUserAccount } from "./handlers/updateUserAccount";
