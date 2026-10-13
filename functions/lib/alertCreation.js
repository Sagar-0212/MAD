"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.alertOnMissedCheckin = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const firestore_2 = require("firebase-admin/firestore");
if (!admin.apps.length) {
    admin.initializeApp();
}
/**
 * Triggered whenever a member's checkin document is written.
 * If status transitions to 'missed', creates an alert document and
 * sends push notifications to all child members of that family.
 */
exports.alertOnMissedCheckin = (0, firestore_1.onDocumentWritten)("families/{familyId}/members/{memberId}/checkins/{date}", async (event) => {
    const afterData = event.data?.after.data();
    const beforeData = event.data?.before.data();
    // Check if the checkin status transitioned to 'missed'
    const isNowMissed = afterData?.status === "missed";
    const wasAlreadyMissed = beforeData?.status === "missed";
    if (!isNowMissed || wasAlreadyMissed) {
        return;
    }
    const { familyId, memberId, date } = event.params;
    const db = admin.firestore();
    console.log(`Check-in missed for member ${memberId} in family ${familyId} on ${date}. Creating alert...`);
    // 1. Create or ensure alert document in families/{familyId}/alerts
    const alertId = `alert_${memberId}_${date}`;
    const alertRef = db.doc(`families/${familyId}/alerts/${alertId}`);
    const existingAlert = await alertRef.get();
    if (!existingAlert.exists) {
        await alertRef.set({
            familyMemberId: memberId,
            date: date,
            triggeredAt: firestore_2.FieldValue.serverTimestamp(),
            resolvedAt: null,
            resolvedBy: null,
            resolution: null,
        });
        console.log(`Alert document created: families/${familyId}/alerts/${alertId}`);
    }
    // 2. Fetch the parent's display name
    const parentDoc = await db
        .doc(`families/${familyId}/members/${memberId}`)
        .get();
    const parentName = parentDoc.data()?.displayName || "Your family member";
    // 3. Query all family members with role 'child'
    const childrenSnapshot = await db
        .collection(`families/${familyId}/members`)
        .where("role", "==", "child")
        .get();
    if (childrenSnapshot.empty) {
        console.log(`No child members found in family ${familyId} to notify.`);
        return;
    }
    const tokens = [];
    childrenSnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.fcmToken) {
            tokens.push(data.fcmToken);
        }
        if (Array.isArray(data.fcmTokens)) {
            tokens.push(...data.fcmTokens);
        }
    });
    const uniqueTokens = Array.from(new Set(tokens.filter(Boolean)));
    if (uniqueTokens.length === 0) {
        console.log(`No FCM registration tokens found for child members in family ${familyId}. Notification logged.`);
        return;
    }
    // 4. Send FCM Push Notification
    try {
        const message = {
            tokens: uniqueTokens,
            notification: {
                title: "CareCircle Alert: Missed Check-in",
                body: `${parentName} has not checked in today. Please check in with them.`,
            },
            data: {
                familyId,
                memberId,
                date,
                type: "MISSED_CHECKIN",
                alertId,
            },
            android: {
                priority: "high",
                notification: {
                    sound: "default",
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        badge: 1,
                    },
                },
            },
        };
        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`FCM notifications sent to family ${familyId}: ${response.successCount} succeeded, ${response.failureCount} failed.`);
    }
    catch (error) {
        console.error("Failed to send FCM notifications:", error);
    }
});
//# sourceMappingURL=alertCreation.js.map