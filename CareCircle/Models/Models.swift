import Foundation

// MARK: - Role & Status Enums
public enum MemberRole: String, Codable, CaseIterable {
    case parent
    case child
}

public enum CheckinStatus: String, Codable, CaseIterable {
    case ok
    case waiting
    case missed
    case none
}

public enum AlertResolution: String, Codable, CaseIterable {
    case confirmedOk = "confirmed_ok"
    case falseAlarm = "false_alarm"

    public var displayTitle: String {
        switch self {
        case .confirmedOk: return "Confirmed OK"
        case .falseAlarm: return "False Alarm"
        }
    }
}

// MARK: - Family Model
public struct Family: Identifiable, Codable {
    public var id: String
    public var name: String
    public var createdBy: String
    public var createdAt: Date
    public var inviteCode: String?

    public init(id: String = UUID().uuidString, name: String, createdBy: String, createdAt: Date = Date(), inviteCode: String? = nil) {
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.inviteCode = inviteCode
    }
}

// MARK: - Member Model
public struct FamilyMember: Identifiable, Codable, Hashable {
    public var id: String
    public var userId: String
    public var role: MemberRole
    public var phoneNumber: String
    public var displayName: String
    public var email: String?
    public var fcmToken: String?

    public init(
        id: String = UUID().uuidString,
        userId: String,
        role: MemberRole,
        phoneNumber: String = "",
        displayName: String,
        email: String? = nil,
        fcmToken: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.role = role
        self.phoneNumber = phoneNumber
        self.displayName = displayName
        self.email = email
        self.fcmToken = fcmToken
    }
}

// MARK: - Checkin Model
public struct DailyCheckin: Identifiable, Codable {
    public var id: String // Date string YYYY-MM-DD
    public var checkedInAt: Date?
    public var status: CheckinStatus
    public var graceWindowExpiresAt: Date?
    public var resolvedAt: Date?
    public var resolvedBy: String?
    public var resolution: AlertResolution?
    public var activeAlert: Bool?

    public init(
        id: String,
        checkedInAt: Date? = nil,
        status: CheckinStatus = .none,
        graceWindowExpiresAt: Date? = nil,
        resolvedAt: Date? = nil,
        resolvedBy: String? = nil,
        resolution: AlertResolution? = nil,
        activeAlert: Bool? = false
    ) {
        self.id = id
        self.checkedInAt = checkedInAt
        self.status = status
        self.graceWindowExpiresAt = graceWindowExpiresAt
        self.resolvedAt = resolvedAt
        self.resolvedBy = resolvedBy
        self.resolution = resolution
        self.activeAlert = activeAlert
    }
}

// MARK: - Medication Model
public struct Medication: Identifiable, Codable {
    public var id: String
    public var name: String
    public var scheduledTime: String // e.g. "08:00 AM"
    public var createdBy: String
    public var isTakenToday: Bool?

    public init(
        id: String = UUID().uuidString,
        name: String,
        scheduledTime: String,
        createdBy: String,
        isTakenToday: Bool? = false
    ) {
        self.id = id
        self.name = name
        self.scheduledTime = scheduledTime
        self.createdBy = createdBy
        self.isTakenToday = isTakenToday
    }
}

// MARK: - Health Record
public struct HealthRecord: Identifiable, Codable {
    public var id: String
    public var familyMemberId: String
    public var photoUrl: String
    public var doctorName: String
    public var visitDate: Date
    public var followUpDate: Date?
    public var tags: [String]
    public var addedBy: String

    public init(
        id: String = UUID().uuidString,
        familyMemberId: String,
        photoUrl: String,
        doctorName: String,
        visitDate: Date,
        followUpDate: Date? = nil,
        tags: [String] = [],
        addedBy: String
    ) {
        self.id = id
        self.familyMemberId = familyMemberId
        self.photoUrl = photoUrl
        self.doctorName = doctorName
        self.visitDate = visitDate
        self.followUpDate = followUpDate
        self.tags = tags
        self.addedBy = addedBy
    }
}

// MARK: - Care Schedule Entry
public struct CareScheduleEntry: Identifiable, Codable {
    public var id: String
    public var familyMemberId: String
    public var dayOfWeek: Int // 1 = Sunday, 2 = Monday, ... 7 = Saturday
    public var notes: String

    public init(
        id: String = UUID().uuidString,
        familyMemberId: String,
        dayOfWeek: Int,
        notes: String
    ) {
        self.id = id
        self.familyMemberId = familyMemberId
        self.dayOfWeek = dayOfWeek
        self.notes = notes
    }

    public var dayName: String {
        let calendar = Calendar.current
        let symbols = calendar.weekdaySymbols
        let idx = (dayOfWeek - 1) % 7
        return idx >= 0 && idx < symbols.count ? symbols[idx] : "Day \(dayOfWeek)"
    }
}

// MARK: - Care Alert
public struct CareAlert: Identifiable, Codable {
    public var id: String
    public var familyMemberId: String
    public var date: String
    public var triggeredAt: Date
    public var resolvedAt: Date?
    public var resolvedBy: String?
    public var resolution: AlertResolution?

    public init(
        id: String = UUID().uuidString,
        familyMemberId: String,
        date: String,
        triggeredAt: Date = Date(),
        resolvedAt: Date? = nil,
        resolvedBy: String? = nil,
        resolution: AlertResolution? = nil
    ) {
        self.id = id
        self.familyMemberId = familyMemberId
        self.date = date
        self.triggeredAt = triggeredAt
        self.resolvedAt = resolvedAt
        self.resolvedBy = resolvedBy
        self.resolution = resolution
    }

    public var isResolved: Bool {
        resolvedAt != nil && resolution != nil
    }
}
