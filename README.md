# CareCircle — Backend Architecture & Verification

CareCircle is a private, family-only coordination tool for adult children and aging parents. This document details the Firebase backend implementation for Step 1 of the build order.

---

## 1. Firestore Data Model & Schema

Every collection and subcollection is strictly scoped by family membership:

```
families/{familyId}
  ├── name: string
  ├── createdBy: string (userId of family creator)
  └── createdAt: timestamp

families/{familyId}/members/{memberId}
  ├── userId: string
  ├── role: 'parent' | 'child'
  ├── phoneNumber: string
  ├── displayName: string
  ├── fcmToken?: string (optional single token)
  └── fcmTokens?: string[] (optional push token array)

families/{familyId}/members/{memberId}/checkins/{date}  (format: YYYY-MM-DD)
  ├── checkedInAt: timestamp | null
  ├── status: 'ok' | 'waiting' | 'missed'
  ├── graceWindowExpiresAt?: timestamp | null
  ├── resolvedAt?: timestamp | null
  ├── resolvedBy?: string | null
  ├── resolution?: 'confirmed_ok' | 'false_alarm' | null
  └── activeAlert?: boolean

families/{familyId}/members/{memberId}/medications/{medId}
  ├── name: string
  ├── scheduledTime: string (e.g., "08:00")
  └── createdBy: string (userId)

families/{familyId}/members/{memberId}/medications/{medId}/logs/{date}
  └── takenAt: timestamp | null

families/{familyId}/healthRecords/{recordId}
  ├── familyMemberId: string
  ├── photoUrl: string (Firebase Cloud Storage URL)
  ├── doctorName: string
  ├── visitDate: timestamp
  ├── followUpDate?: timestamp | null
  ├── tags: string[]
  └── addedBy: string (userId)

families/{familyId}/careSchedule/{entryId}
  ├── familyMemberId: string
  ├── dayOfWeek: number | string (0 = Sunday ... 6 = Saturday)
  └── notes: string

families/{familyId}/alerts/{alertId}
  ├── familyMemberId: string
  ├── date: string (YYYY-MM-DD)
  ├── triggeredAt: timestamp
  ├── resolvedAt: timestamp | null
  ├── resolvedBy: string | null
  └── resolution: 'confirmed_ok' | 'false_alarm' | null
```

---

## 2. Firestore Security Rules (`firestore.rules`)

- **Family Isolation**: All reads and writes enforce `isMember(familyId)` (`request.auth.uid` must exist in `/families/{familyId}/members/{uid}`).
- **Zero Cross-Family Leaks**: Users cannot query or mutate data belonging to families they do not belong to.
- **Parent Mode Protections**:
  - A parent can check in on their own record (`status in ['ok', 'waiting']`, `checkedInAt != null`).
  - Parents cannot accidentally overwrite other members' check-ins.
- **Child Member Permissions**:
  - Can manage medication regimens, weekly care schedule assignments, and health record logs.
  - Can resolve alerts with valid resolution constraints (`resolution in ['confirmed_ok', 'false_alarm']`, `resolvedBy == request.auth.uid`).

---

## 3. Cloud Functions for Firebase (`functions/src/`)

### Function 1: Scheduled Grace-Period Check (`scheduledGracePeriodCheck`)
- **Trigger**: Cloud Scheduler running daily at cutoff time (default: 10:00 AM America/New_York) + HTTP hook for testing (`triggerGracePeriodCheckHttp`).
- **Behavior**:
  1. Queries all families and active parent members.
  2. If a parent has no `checkins` document for today, creates one with `status: 'waiting'`, `checkedInAt: null`, and `graceWindowExpiresAt: now + 90 minutes`.
  3. Sweeps existing `'waiting'` check-ins: if `now >= graceWindowExpiresAt`, transitions `status` to `'missed'`, triggering Function 2.

### Function 2: Missed Check-in Alert Trigger & Push (`alertOnMissedCheckin`)
- **Trigger**: Firestore document write on `families/{familyId}/members/{memberId}/checkins/{date}`.
- **Behavior**:
  1. Detects transitions where `status == 'missed'`.
  2. Creates or updates an active alert in `families/{familyId}/alerts/{alertId}` (`alert_${memberId}_${date}`).
  3. Queries all members in that family with `role == 'child'`.
  4. Collects their FCM registration tokens and broadcasts high-priority push notifications with sound and badge.

### Function 3: Alert Resolution Handler (`onAlertResolved`)
- **Trigger**: Firestore document update on `families/{familyId}/alerts/{alertId}`.
- **Behavior**:
  1. Triggers when `resolution` and `resolvedAt` are populated by a family member.
  2. Clears the active alert state and updates the parent member's checkin document with the resolution and resolver information.
  3. Because the iOS dashboard uses live Firestore listeners, the UI updates instantly without requiring extra push notifications.

---

## 4. Firebase Emulator Test Suite (`tests/`)

Run tests anytime with:
```bash
npm test
```

### Test Results (9/9 Passed)
- **CareCircle Cloud Functions & Lifecycle Logic**:
  - `✔ 1. Grace Period Check: marks parent with no check-in today as 'waiting'`
  - `✔ 2. Grace Period Check: transitions 'waiting' to 'missed' once grace window expires`
  - `✔ 3. Alert Creation & Resolution Lifecycle: updates status on alert resolution`
- **CareCircle Firestore Security Rules**:
  - `✔ denies unauthenticated read/write to families`
  - `✔ allows family member to read their own family doc, but denies non-members`
  - `✔ allows a parent to write their own check-in ('ok')`
  - `✔ denies an outsider from creating or reading a check-in in another family`
  - `✔ allows child to manage care schedule and medications for family members`
  - `✔ allows a child member to resolve an alert with valid resolution fields`
