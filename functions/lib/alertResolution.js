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
exports.onAlertResolved = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
if (!admin.apps.length) {
    admin.initializeApp();
}
/**
 * Triggered whenever an alert document in families/{familyId}/alerts/{alertId} is updated.
 * When an alert is resolved (resolution and resolvedAt are set),
 * clears the active alert state by synchronizing the resolution back to the
 * member's checkin document.
 */
exports.onAlertResolved = (0, firestore_1.onDocumentUpdated)("families/{familyId}/alerts/{alertId}", async (event) => {
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
    console.log(`Alert ${alertId} resolved in family ${familyId} for member ${familyMemberId} on ${date}. Resolution: ${resolution} by ${resolvedBy}. Clearing active alert state...`);
    const db = admin.firestore();
    if (familyMemberId && date) {
        const checkinRef = db.doc(`families/${familyId}/members/${familyMemberId}/checkins/${date}`);
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
});
//# sourceMappingURL=alertResolution.js.map