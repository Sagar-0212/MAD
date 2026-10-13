import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

export * from "./types";
export {
  scheduledGracePeriodCheck,
  triggerGracePeriodCheckHttp,
} from "./gracePeriodCheck";
export { alertOnMissedCheckin } from "./alertCreation";
export { onAlertResolved } from "./alertResolution";
export { createFamilyCircle, joinFamilyCircle } from "./familyCircle";

