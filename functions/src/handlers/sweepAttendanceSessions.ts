import { getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { sweepAttendanceSessions as sweep } from "../attendance/sessionSweep";
import { MAX_INSTANCES, REGION, RUNTIME_SERVICE_ACCOUNT } from "../config";

/** Every 15 minutes: flags overdue check-outs and closes expired sessions. */
export const sweepAttendanceSessions = onSchedule(
  {
    schedule: "every 15 minutes",
    timeZone: "Asia/Kolkata",
    region: REGION,
    maxInstances: MAX_INSTANCES,
    serviceAccount: RUNTIME_SERVICE_ACCOUNT,
  },
  async () => {
    const result = await sweep(getFirestore(), new Date());
    if (result.flaggedOverdue || result.closedMissing) {
      logger.info("Attendance sessions swept", result);
    }
  },
);
