import { describe, it, before, after, beforeEach } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, updateDoc, collection, getDocs } from "firebase/firestore";

const PROJECT_ID = "carecircle-test-project";

describe("CareCircle Firestore Security Rules", () => {
  let testEnv;

  before(async () => {
    const rulesPath = path.resolve(process.cwd(), "firestore.rules");
    const rules = fs.readFileSync(rulesPath, "utf8");

    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules,
        host: "127.0.0.1",
        port: 8088,
      },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();

    // Seed test data with admin context (bypasses security rules)
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      
      // Seed Family 1
      await setDoc(doc(db, "families/family1"), {
        name: "The Johnsons",
        createdBy: "child1",
        createdAt: new Date(),
      });

      // Seed Child 1
      await setDoc(doc(db, "families/family1/members/child1"), {
        userId: "child1",
        role: "child",
        displayName: "Alice",
        phoneNumber: "+15550001",
      });

      // Seed Parent 1
      await setDoc(doc(db, "families/family1/members/parent1"), {
        userId: "parent1",
        role: "parent",
        displayName: "Dad",
        phoneNumber: "+15550002",
      });

      // Seed Family 2 (outsider family)
      await setDoc(doc(db, "families/family2"), {
        name: "The Smiths",
        createdBy: "outsider1",
        createdAt: new Date(),
      });
      await setDoc(doc(db, "families/family2/members/outsider1"), {
        userId: "outsider1",
        role: "child",
        displayName: "Bob",
        phoneNumber: "+15550003",
      });
    });
  });

  it("denies unauthenticated read/write to families", async () => {
    const unauthDb = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(unauthDb, "families/family1")));
    await assertFails(
      setDoc(doc(unauthDb, "families/familyNew"), {
        name: "Hacker Family",
        createdBy: "anon",
        createdAt: new Date(),
      })
    );
  });

  it("allows family member to read their own family doc, but denies non-members", async () => {
    const childDb = testEnv.authenticatedContext("child1").firestore();
    const outsiderDb = testEnv.authenticatedContext("outsider1").firestore();

    // Child1 is a member of family1
    await assertSucceeds(getDoc(doc(childDb, "families/family1")));

    // Outsider1 is NOT a member of family1
    await assertFails(getDoc(doc(outsiderDb, "families/family1")));
  });

  it("denies any authenticated user from listing all families (no unrestricted list)", async () => {
    const childDb = testEnv.authenticatedContext("child1").firestore();
    const outsiderDb = testEnv.authenticatedContext("outsider1").firestore();

    // Listing the /families collection should be denied to all clients
    await assertFails(getDocs(collection(childDb, "families")));
    await assertFails(getDocs(collection(outsiderDb, "families")));
  });

  it("allows users to access their own /users profile doc and denies outsiders", async () => {
    const childDb = testEnv.authenticatedContext("child1").firestore();
    const outsiderDb = testEnv.authenticatedContext("outsider1").firestore();

    // Can write and read own profile doc
    await assertSucceeds(
      setDoc(doc(childDb, "users/child1"), {
        familyId: "family1",
        displayName: "Alice",
      })
    );
    await assertSucceeds(getDoc(doc(childDb, "users/child1")));

    // Outsider cannot read or write child1's profile doc
    await assertFails(getDoc(doc(outsiderDb, "users/child1")));
    await assertFails(
      setDoc(doc(outsiderDb, "users/child1"), {
        familyId: "hacked",
      })
    );
  });

  it("enforces secure invite code creation and lookup (allows get with known code, denies enumeration/listing)", async () => {
    const childDb = testEnv.authenticatedContext("child1").firestore();
    const outsiderDb = testEnv.authenticatedContext("outsider1").firestore();

    // Creator can create an invite document
    await assertSucceeds(
      setDoc(doc(childDb, "invites/CARE92"), {
        familyId: "family1",
        createdBy: "child1",
        createdAt: new Date(),
      })
    );

    // Spoofed creator fails
    await assertFails(
      setDoc(doc(outsiderDb, "invites/FAKE01"), {
        familyId: "family1",
        createdBy: "someone_else",
        createdAt: new Date(),
      })
    );

    // Anyone authenticated can read single invite if they know the code
    await assertSucceeds(getDoc(doc(outsiderDb, "invites/CARE92")));

    // Listing all invites is strictly forbidden
    await assertFails(getDocs(collection(outsiderDb, "invites")));
  });

  it("allows a parent to write their own check-in ('ok')", async () => {
    const parentDb = testEnv.authenticatedContext("parent1").firestore();
    const checkinRef = doc(parentDb, "families/family1/members/parent1/checkins/2026-10-06");

    await assertSucceeds(
      setDoc(checkinRef, {
        checkedInAt: new Date(),
        status: "ok",
      })
    );
  });

  it("denies an outsider from creating or reading a check-in in another family", async () => {
    const outsiderDb = testEnv.authenticatedContext("outsider1").firestore();
    const checkinRef = doc(outsiderDb, "families/family1/members/parent1/checkins/2026-10-06");

    await assertFails(getDoc(checkinRef));
    await assertFails(
      setDoc(checkinRef, {
        checkedInAt: new Date(),
        status: "ok",
      })
    );
  });

  it("allows child to manage care schedule and medications for family members", async () => {
    const childDb = testEnv.authenticatedContext("child1").firestore();
    
    // Create medication
    const medRef = doc(childDb, "families/family1/members/parent1/medications/med1");
    await assertSucceeds(
      setDoc(medRef, {
        name: "Blood Pressure Med",
        scheduledTime: "09:00",
        createdBy: "child1",
      })
    );

    // Create care schedule entry
    const scheduleRef = doc(childDb, "families/family1/careSchedule/entry1");
    await assertSucceeds(
      setDoc(scheduleRef, {
        familyMemberId: "child1",
        dayOfWeek: 1,
        notes: "Visit Dad for lunch",
      })
    );
  });

  it("allows a child member to resolve an alert with valid resolution fields", async () => {
    // Seed an active alert using admin context
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "families/family1/alerts/alert1"), {
        familyMemberId: "parent1",
        date: "2026-10-06",
        triggeredAt: new Date(),
        resolvedAt: null,
        resolvedBy: null,
        resolution: null,
      });
    });

    const childDb = testEnv.authenticatedContext("child1").firestore();
    const alertRef = doc(childDb, "families/family1/alerts/alert1");

    // Invalid resolution should fail
    await assertFails(
      updateDoc(alertRef, {
        resolution: "invalid_status",
        resolvedAt: new Date(),
        resolvedBy: "child1",
      })
    );

    // Valid resolution should succeed
    await assertSucceeds(
      updateDoc(alertRef, {
        resolution: "confirmed_ok",
        resolvedAt: new Date(),
        resolvedBy: "child1",
      })
    );
  });
});
