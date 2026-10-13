import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Triggered whenever an alert document in families/{familyId}/alerts/{alertId} is updated.
 * When an alert is resolved (resolution and resolvedAt are set),
 * clears the active alert state by synchronizing the resolution back to the
 * member's checkin document.
 */
export const onAlertResolved = onDocumentUpdated(
  "families/{familyId}/alerts/{alertId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!afterData) {
      return;
    }

    // Trigger only when resolution transitioned from unresolved to resolved
    const wasResolved = Boolean(beforeData?.resolution && beforeData?.resolvedAt);
    const isNowResolved = Boolean(afterData.resolution && afterData.resolvedAt);

    if (wasResolved || !isNowResolved) {
      return;
    }

    const { familyId, alertId } = event.params;
    const { familyMemberId, date, resolution, resolvedBy, resolvedAt } = afterData;

    console.log(
      `Alert ${alertId} resolved in family ${familyId} for member ${familyMemberId} on ${date}. Resolution: ${resolution} by ${resolvedBy}. Clearing active alert state...`
    );

    const db = admin.firestore();

    if (familyMemberId && date) {
      const checkinRef = db.doc(
        `families/${familyId}/members/${familyMemberId}/checkins/${date}`
      );

      const checkinSnap = await checkinRef.get();
      if (checkinSnap.exists) {
        await checkinRef.update({
          resolvedAt: resolvedAt,
          resolvedBy: resolvedBy || null,
          resolution: resolution,
          // If confirmed OK, status can be updated so the dashboard status circle shows confirmed
          status: resolution === "confirmed_ok" ? "ok" : "missed",
          activeAlert: false,
        });
        console.log(`Updated check-in status for member ${familyMemberId} to reflect resolution.`);
      }
    }
  }
);
