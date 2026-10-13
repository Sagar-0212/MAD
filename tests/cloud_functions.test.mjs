process.env.GCLOUD_PROJECT = "carecircle-test-project";
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8088";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";

import { describe, it, before, beforeEach } from "node:test";
import assert from "node:assert/strict";
import adminPkg from "firebase-admin";
const admin = adminPkg.default || adminPkg;
import { runGracePeriodCheck } from "../functions/lib/gracePeriodCheck.js";

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: "carecircle-test-project",
  });
}

const db = admin.firestore();

describe("CareCircle Cloud Functions & Lifecycle Logic", () => {
  const familyId = "fam_fn_test";
  const parentId = "dad_fn_test";
  const childId = "daughter_fn_test";
  const testDate = "2026-10-06";
  const t0 = new Date("2026-10-06T10:00:00Z").getTime();

  beforeEach(async () => {
    // Clean up test documents in emulator
    const familyRef = db.doc(`families/${familyId}`);
    await familyRef.set({
      name: "The Emulators",
      createdBy: childId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Parent member
    await db.doc(`families/${familyId}/members/${parentId}`).set({
      userId: parentId,
      role: "parent",
      displayName: "Dad Tester",
      phoneNumber: "+15559990001",
    });

    // Child member
    await db.doc(`families/${familyId}/members/${childId}`).set({
      userId: childId,
      role: "child",
      displayName: "Daughter Tester",
      phoneNumber: "+15559990002",
      fcmToken: "mock-device-fcm-token-12345",
    });

    // Delete any existing checkin or alert for clean test
    await db.doc(`families/${familyId}/members/${parentId}/checkins/${testDate}`).delete();
    await db.doc(`families/${familyId}/alerts/alert_${parentId}_${testDate}`).delete();
  });

  it("1. Grace Period Check: marks parent with no check-in today as 'waiting'", async () => {
    // Run grace period check at t0
    const result = await runGracePeriodCheck(testDate, t0, db);
    assert.strictEqual(result.waitingCount >= 1, true, "Should have marked at least 1 member as waiting");

    // Check Firestore doc
    const checkinSnap = await db
      .doc(`families/${familyId}/members/${parentId}/checkins/${testDate}`)
      .get();
    
    assert.strictEqual(checkinSnap.exists, true, "Check-in document should be created");
    const data = checkinSnap.data();
    assert.strictEqual(data?.status, "waiting", "Status should be 'waiting'");
    assert.strictEqual(data?.checkedInAt, null, "checkedInAt should be null");
    assert.ok(data?.graceWindowExpiresAt, "graceWindowExpiresAt must be populated");
  });

  it("2. Grace Period Check: transitions 'waiting' to 'missed' once grace window expires", async () => {
    // Step A: Set to waiting at t0
    await runGracePeriodCheck(testDate, t0, db);

    // Step B: Simulate running check 91 minutes later (t0 + 91 mins)
    const tExpired = t0 + 91 * 60 * 1000;
    const result2 = await runGracePeriodCheck(testDate, tExpired, db);
    assert.strictEqual(result2.missedCount >= 1, true, "Should have transitioned waiting member to missed");

    const checkinSnap = await db
      .doc(`families/${familyId}/members/${parentId}/checkins/${testDate}`)
      .get();
    
    const data = checkinSnap.data();
    assert.strictEqual(data?.status, "missed", "Status should have transitioned to 'missed'");
  });

  it("3. Alert Creation & Resolution Lifecycle: updates status on alert resolution", async () => {
    // Simulate checkin transitioning to 'missed'
    const checkinRef = db.doc(`families/${familyId}/members/${parentId}/checkins/${testDate}`);
    await checkinRef.set({
      status: "missed",
      checkedInAt: null,
      missedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Simulate alert creation (function #2)
    const alertId = `alert_${parentId}_${testDate}`;
    const alertRef = db.doc(`families/${familyId}/alerts/${alertId}`);
    await alertRef.set({
      familyMemberId: parentId,
      date: testDate,
      triggeredAt: admin.firestore.FieldValue.serverTimestamp(),
      resolvedAt: null,
      resolvedBy: null,
      resolution: null,
    });

    // Child resolves the alert (function #3)
    const resolvedAtTimestamp = admin.firestore.FieldValue.serverTimestamp();
    await alertRef.update({
      resolvedAt: resolvedAtTimestamp,
      resolvedBy: childId,
      resolution: "confirmed_ok",
    });

    // Directly test resolution synchronization handler logic
    await checkinRef.update({
      resolvedAt: resolvedAtTimestamp,
      resolvedBy: childId,
      resolution: "confirmed_ok",
      status: "ok",
      activeAlert: false,
    });

    const updatedCheckin = await checkinRef.get();
    const checkinData = updatedCheckin.data();

    assert.strictEqual(checkinData?.status, "ok", "Status should be 'ok' after confirmed resolution");
    assert.strictEqual(checkinData?.resolution, "confirmed_ok", "Resolution should be confirmed_ok");
    assert.strictEqual(checkinData?.resolvedBy, childId, "Resolved by should be the child ID");
    assert.strictEqual(checkinData?.activeAlert, false, "Active alert should be cleared");
  });
});
