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
exports.triggerGracePeriodCheckHttp = exports.scheduledGracePeriodCheck = void 0;
exports.getTodayDateString = getTodayDateString;
exports.runGracePeriodCheck = runGracePeriodCheck;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
if (!admin.apps.length) {
    admin.initializeApp();
}
/**
 * Formats a Date object to YYYY-MM-DD
 */
function getTodayDateString(d = new Date()) {
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, "0");
    const day = String(d.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
}
/**
 * Core business logic for checking grace period across all families.
 * 1. Finds parent members with no checkin for today -> marks as 'waiting' (90m grace window).
 * 2. Finds parent members still in 'waiting' whose grace window has elapsed -> marks as 'missed'.
 */
function getMillis(val) {
    if (!val)
        return 0;
    if (typeof val.toMillis === "function")
        return val.toMillis();
    if (typeof val.toDate === "function")
        return val.toDate().getTime();
    if (val instanceof Date)
        return val.getTime();
    if (typeof val._seconds === "number")
        return val._seconds * 1000;
    if (typeof val.seconds === "number")
        return val.seconds * 1000;
    if (typeof val === "number")
        return val;
    return new Date(val).getTime() || 0;
}
async function runGracePeriodCheck(forcedDate, nowMs = Date.now(), customDb) {
    const db = customDb || admin.firestore();
    const todayDate = forcedDate || getTodayDateString(new Date(nowMs));
    const defaultGraceMs = 90 * 60 * 1000; // 90 minutes
    let waitingCount = 0;
    let missedCount = 0;
    const familiesSnapshot = await db.collection("families").get();
    for (const familyDoc of familiesSnapshot.docs) {
        const familyId = familyDoc.id;
        // Query parent members of this family
        const parentsSnapshot = await db
            .collection(`families/${familyId}/members`)
            .where("role", "==", "parent")
            .get();
        for (const parentDoc of parentsSnapshot.docs) {
            const parentId = parentDoc.id;
            const checkinRef = db.doc(`families/${familyId}/members/${parentId}/checkins/${todayDate}`);
            const checkinSnap = await checkinRef.get();
            if (!checkinSnap.exists) {
                // No checkin document exists yet for today: start grace window ('waiting')
                const expiresAt = new Date(nowMs + defaultGraceMs);
                await checkinRef.set({
                    checkedInAt: null,
                    status: "waiting",
                    graceWindowExpiresAt: expiresAt,
                    createdAt: new Date(nowMs),
                });
                waitingCount++;
            }
            else {
                const data = checkinSnap.data();
                if (data?.status === "waiting") {
                    // Member is waiting: verify if grace period elapsed
                    const expiresAtMillis = getMillis(data.graceWindowExpiresAt);
                    if (nowMs >= expiresAtMillis) {
                        // Grace period elapsed, transition to missed
                        await checkinRef.update({
                            status: "missed",
                            missedAt: new Date(nowMs),
                        });
                        missedCount++;
                    }
                }
            }
        }
    }
    return { waitingCount, missedCount };
}
/**
 * Scheduled Cloud Function running daily at the cutoff time (default: 10:00 AM)
 */
exports.scheduledGracePeriodCheck = (0, scheduler_1.onSchedule)({
    schedule: "every day 10:00",
    timeZone: "America/New_York",
}, async () => {
    const result = await runGracePeriodCheck();
    console.log(`Scheduled grace-period check complete: ${result.waitingCount} waiting, ${result.missedCount} missed`);
});
/**
 * HTTP-triggered helper to execute the grace period check on demand
 * Protected: allowed in emulator environment or with x-admin-secret / Bearer header matching ADMIN_TRIGGER_SECRET.
 */
exports.triggerGracePeriodCheckHttp = (0, https_1.onRequest)(async (req, res) => {
    const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";
    const authHeader = req.headers.authorization;
    const adminSecret = process.env.ADMIN_TRIGGER_SECRET;
    if (!isEmulator) {
        const providedSecret = req.headers["x-admin-secret"] ||
            (authHeader ? authHeader.replace(/^Bearer\s+/i, "") : undefined);
        if (!adminSecret || providedSecret !== adminSecret) {
            res.status(401).json({ success: false, error: "Unauthorized: Missing or invalid secret." });
            return;
        }
    }
    try {
        const forcedDate = typeof req.query.date === "string" ? req.query.date : undefined;
        const nowMs = typeof req.query.now === "string" ? parseInt(req.query.now, 10) : Date.now();
        const result = await runGracePeriodCheck(forcedDate, nowMs);
        res.status(200).json({ success: true, ...result });
    }
    catch (error) {
        console.error("Failed to execute grace-period check:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});
//# sourceMappingURL=gracePeriodCheck.js.map