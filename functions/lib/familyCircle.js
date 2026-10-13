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
exports.joinFamilyCircle = exports.createFamilyCircle = void 0;
exports.generateInviteCode = generateInviteCode;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const crypto = __importStar(require("crypto"));
if (!admin.apps.length) {
    admin.initializeApp();
}
/**
 * Generates a random, non-sequential 6-character uppercase invite code.
 * Excludes ambiguous characters (0, O, 1, I).
 */
function generateInviteCode() {
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    let code = "";
    const randomBytes = crypto.randomBytes(6);
    for (let i = 0; i < 6; i++) {
        code += chars[randomBytes[i] % chars.length];
    }
    return code;
}
/**
 * Callable Function: Creates a new family circle, sets up the creator's membership,
 * generates a secure random 6-character invite code, and links the user's profile.
 */
exports.createFamilyCircle = (0, https_1.onCall)(async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required to create a family circle.");
    }
    const uid = request.auth.uid;
    const { familyName, displayName, role, phoneNumber } = request.data || {};
    if (!familyName || typeof familyName !== "string" || !familyName.trim()) {
        throw new https_1.HttpsError("invalid-argument", "Family name is required.");
    }
    const validRole = role === "parent" ? "parent" : "child";
    const db = admin.firestore();
    // Generate unique invite code
    let inviteCode = "";
    let isUnique = false;
    for (let attempt = 0; attempt < 10; attempt++) {
        const candidate = generateInviteCode();
        const existing = await db.doc(`invites/${candidate}`).get();
        if (!existing.exists) {
            inviteCode = candidate;
            isUnique = true;
            break;
        }
    }
    if (!isUnique) {
        throw new https_1.HttpsError("internal", "Could not generate unique invite code. Please try again.");
    }
    // Create new family doc
    const familyRef = db.collection("families").doc();
    const familyId = familyRef.id;
    const batch = db.batch();
    batch.set(familyRef, {
        name: familyName.trim(),
        createdBy: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        inviteCode: inviteCode,
    });
    // Creator membership doc: ID MUST equal auth UID
    const memberRef = db.doc(`families/${familyId}/members/${uid}`);
    batch.set(memberRef, {
        userId: uid,
        role: validRole,
        phoneNumber: phoneNumber || "",
        displayName: displayName || (validRole === "parent" ? "Parent" : "Caregiver"),
    });
    // Save invite lookup
    const inviteRef = db.doc(`invites/${inviteCode}`);
    batch.set(inviteRef, {
        familyId: familyId,
        createdBy: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Save user profile link
    const userRef = db.doc(`users/${uid}`);
    batch.set(userRef, {
        familyId: familyId,
        role: validRole,
        displayName: displayName || "",
        phoneNumber: phoneNumber || "",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    await batch.commit();
    return {
        familyId: familyId,
        inviteCode: inviteCode,
    };
});
/**
 * Callable Function: Joins an existing family circle using a 6-character invite code.
 * Validates the code, adds the caller as a member with their auth UID, and links their profile.
 */
exports.joinFamilyCircle = (0, https_1.onCall)(async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required to join a family circle.");
    }
    const uid = request.auth.uid;
    const { inviteCode, displayName, role, phoneNumber } = request.data || {};
    if (!inviteCode || typeof inviteCode !== "string") {
        throw new https_1.HttpsError("invalid-argument", "Valid invite code is required.");
    }
    const codeUpper = inviteCode.trim().toUpperCase();
    const db = admin.firestore();
    const inviteSnap = await db.doc(`invites/${codeUpper}`).get();
    if (!inviteSnap.exists) {
        throw new https_1.HttpsError("not-found", "Invalid or expired invite code.");
    }
    const inviteData = inviteSnap.data();
    const familyId = inviteData?.familyId;
    if (!familyId) {
        throw new https_1.HttpsError("not-found", "Family associated with this invite code was not found.");
    }
    const validRole = role === "parent" ? "parent" : "child";
    const batch = db.batch();
    // Member doc ID MUST equal auth UID
    const memberRef = db.doc(`families/${familyId}/members/${uid}`);
    batch.set(memberRef, {
        userId: uid,
        role: validRole,
        phoneNumber: phoneNumber || "",
        displayName: displayName || (validRole === "parent" ? "Parent" : "Caregiver"),
    }, { merge: true });
    // Update user profile link
    const userRef = db.doc(`users/${uid}`);
    batch.set(userRef, {
        familyId: familyId,
        role: validRole,
        displayName: displayName || "",
        phoneNumber: phoneNumber || "",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    await batch.commit();
    return {
        familyId: familyId,
    };
});
//# sourceMappingURL=familyCircle.js.map