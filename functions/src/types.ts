import { Timestamp, FieldValue } from "firebase-admin/firestore";

export type Role = "parent" | "child";
export type CheckinStatus = "ok" | "waiting" | "missed";
export type AlertResolution = "confirmed_ok" | "false_alarm";

export interface Family {
  name: string;
  createdBy: string;
  createdAt: Timestamp | FieldValue;
}

export interface FamilyMember {
  userId: string;
  role: Role;
  phoneNumber: string;
  displayName: string;
  fcmToken?: string;
  fcmTokens?: string[];
}

export interface Checkin {
  checkedInAt: Timestamp | FieldValue | null;
  status: CheckinStatus;
  graceWindowExpiresAt?: Timestamp | FieldValue | null;
  resolvedAt?: Timestamp | FieldValue | null;
  resolution?: AlertResolution | null;
}

export interface Medication {
  name: string;
  scheduledTime: string;
  createdBy: string;
}

export interface MedicationLog {
  takenAt: Timestamp | FieldValue | null;
}

export interface HealthRecord {
  familyMemberId: string;
  photoUrl: string;
  doctorName: string;
  visitDate: Timestamp | string;
  followUpDate?: Timestamp | string | null;
  tags: string[];
  addedBy: string;
}

export interface CareScheduleEntry {
  familyMemberId: string;
  dayOfWeek: number | string;
  notes: string;
}

export interface CareAlert {
  familyMemberId: string;
  date: string;
  triggeredAt: Timestamp | FieldValue;
  resolvedAt: Timestamp | FieldValue | null;
  resolvedBy: string | null;
  resolution: AlertResolution | null;
}
