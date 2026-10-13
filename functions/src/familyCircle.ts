import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Generates a random, non-sequential 6-character uppercase invite code.
 * Excludes ambiguous characters (0, O, 1, I).
 */
export function generateInviteCode(): string {
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
export const createFamilyCircle = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required to create a family circle.");
  }

  const uid = request.auth.uid;
  const { familyName, displayName, role, phoneNumber } = request.data || {};

  if (!familyName || typeof familyName !== "string" || !familyName.trim()) {
    throw new HttpsError("invalid-argument", "Family name is required.");
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
    throw new HttpsError("internal", "Could not generate unique invite code. Please try again.");
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
export const joinFamilyCircle = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required to join a family circle.");
  }

  const uid = request.auth.uid;
  const { inviteCode, displayName, role, phoneNumber } = request.data || {};

  if (!inviteCode || typeof inviteCode !== "string") {
    throw new HttpsError("invalid-argument", "Valid invite code is required.");
  }

  const codeUpper = inviteCode.trim().toUpperCase();
  const db = admin.firestore();

  const inviteSnap = await db.doc(`invites/${codeUpper}`).get();
  if (!inviteSnap.exists) {
    throw new HttpsError("not-found", "Invalid or expired invite code.");
  }

  const inviteData = inviteSnap.data();
  const familyId = inviteData?.familyId;
  if (!familyId) {
    throw new HttpsError("not-found", "Family associated with this invite code was not found.");
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
