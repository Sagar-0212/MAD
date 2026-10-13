import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

// MARK: - CareCircle Firebase Service
// Real Firestore-backed service with live listeners.
// Replaces the in-memory mock with actual Firebase operations.

@MainActor
public class FirebaseService: ObservableObject {
    public static let shared = FirebaseService()

    // MARK: - Auth State
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUserId: String = ""
    @Published public var currentFamilyId: String = ""
    @Published public var authError: String?
    @Published public var isLoading: Bool = false

    // MARK: - Data State
    @Published public var currentFamily: Family = Family(id: "", name: "", createdBy: "")
    @Published public var members: [FamilyMember] = []
    @Published public var parentCheckins: [String: DailyCheckin] = [:]
    @Published public var medications: [Medication] = []
    @Published public var careSchedule: [CareScheduleEntry] = []
    @Published public var healthRecords: [HealthRecord] = []
    @Published public var alerts: [CareAlert] = []

    // MARK: - Email Auth
    @Published public var authEmail: String = ""

    // Private
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Init
    public init() {
        setupAuthStateListener()
    }

    deinit {
        listeners.forEach { $0.remove() }
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Date Helpers
    public func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self = self else { return }
                if let user = user {
                    self.currentUserId = user.uid
                    self.authEmail = user.email ?? ""
                    self.isAuthenticated = true
                    // Load existing profile/family membership
                    await self.loadUserProfile()
                } else {
                    self.isAuthenticated = false
                    self.currentUserId = ""
                    self.currentFamilyId = ""
                    self.authEmail = ""
                    self.removeAllListeners()
                    self.resetData()
                }
            }
        }
    }

    private func resetData() {
        currentFamily = Family(id: "", name: "", createdBy: "")
        members = []
        parentCheckins = [:]
        medications = []
        careSchedule = []
        healthRecords = []
        alerts = []
    }

    // MARK: - Email Auth: Sign Up
    public func signUp(email: String, password: String) async -> Bool {
        isLoading = true
        authError = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.currentUserId = result.user.uid
            self.authEmail = email
            self.isAuthenticated = true
            isLoading = false
            return true
        } catch {
            authError = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Email Auth: Sign In
    public func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        authError = nil
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.currentUserId = result.user.uid
            self.authEmail = email
            self.isAuthenticated = true
            isLoading = false
            return true
        } catch {
            authError = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Instant Anonymous Sign In (Zero Friction)
    public func signInAnonymously() async -> Bool {
        isLoading = true
        authError = nil
        do {
            let result = try await Auth.auth().signInAnonymously()
            self.currentUserId = result.user.uid
            self.authEmail = "guest_\(result.user.uid.prefix(6))@carecircle.app"
            self.isAuthenticated = true
            isLoading = false
            return true
        } catch {
            authError = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Sign Out
    public func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Demo Mode Data Seeder
    public func loadDemoData(role: MemberRole = .child) {
        let parentId = "member_parent_arthur"
        let childId = "member_child_sarah"
        
        self.currentUserId = (role == .parent) ? "user_parent_arthur" : "user_child_sarah"
        self.authEmail = (role == .parent) ? "parent@carecircle.demo" : "family@carecircle.demo"
        self.isAuthenticated = true
        self.currentFamilyId = "family_demo_johnson"
        self.currentFamily = Family(
            id: "family_demo_johnson",
            name: "The Johnsons",
            createdBy: "user_child_sarah",
            createdAt: Date(),
            inviteCode: "DEMO77"
        )
        
        self.members = [
            FamilyMember(
                id: parentId,
                userId: "user_parent_arthur",
                role: .parent,
                phoneNumber: "+15552345678",
                displayName: "Arthur Johnson",
                email: "arthur@carecircle.demo"
            ),
            FamilyMember(
                id: childId,
                userId: "user_child_sarah",
                role: .child,
                phoneNumber: "+15559876543",
                displayName: "Sarah Johnson",
                email: "sarah@carecircle.demo"
            ),
            FamilyMember(
                id: "member_child_michael",
                userId: "user_child_michael",
                role: .child,
                phoneNumber: "+15558765432",
                displayName: "Michael Johnson",
                email: "michael@carecircle.demo"
            )
        ]
        
        let today = todayDateString()
        self.parentCheckins[parentId] = DailyCheckin(
            id: today,
            checkedInAt: nil,
            status: .waiting,
            graceWindowExpiresAt: Date().addingTimeInterval(3600)
        )
        
        self.medications = [
            Medication(
                id: "med_1",
                name: "Lisinopril 10mg",
                scheduledTime: "08:00 AM",
                createdBy: "user_child_sarah",
                isTakenToday: true
            ),
            Medication(
                id: "med_2",
                name: "Metformin 500mg",
                scheduledTime: "12:00 PM",
                createdBy: "user_child_sarah",
                isTakenToday: false
            ),
            Medication(
                id: "med_3",
                name: "Atorvastatin 20mg",
                scheduledTime: "08:00 PM",
                createdBy: "user_child_sarah",
                isTakenToday: false
            )
        ]
        
        self.careSchedule = [
            CareScheduleEntry(
                id: "sched_1",
                familyMemberId: parentId,
                dayOfWeek: 2,
                notes: "Dr. Evelyn Harris cardiology visit at 2:30 PM"
            ),
            CareScheduleEntry(
                id: "sched_2",
                familyMemberId: parentId,
                dayOfWeek: 4,
                notes: "Pick up Lisinopril refill at pharmacy"
            ),
            CareScheduleEntry(
                id: "sched_3",
                familyMemberId: parentId,
                dayOfWeek: 6,
                notes: "Weekend lunch and garden walk with Michael"
            )
        ]
        
        self.healthRecords = [
            HealthRecord(
                id: "rec_1",
                familyMemberId: parentId,
                photoUrl: "",
                doctorName: "Dr. Evelyn Harris (Cardiology)",
                visitDate: Date().addingTimeInterval(-86400 * 5),
                followUpDate: Date().addingTimeInterval(86400 * 25),
                tags: ["Routine", "Cardiology", "Vitals Normal"],
                addedBy: "user_child_sarah"
            )
        ]
        
        self.alerts = []
    }

    // MARK: - Load User Profile & Family Membership
    /// After sign-in, find which family the user belongs to.
    /// Searches all families for a member doc with ID == auth UID.
    public func loadUserProfile() async {
        guard !currentUserId.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            // Check direct profile link first (users/{uid})
            let userDoc = try await db.document("users/\(currentUserId)").getDocument()
            if let data = userDoc.data(), let familyId = data["familyId"] as? String, !familyId.isEmpty {
                self.currentFamilyId = familyId
                await loadFamily(familyId: familyId)
                setupFamilyListeners(familyId: familyId)
                return
            }

            // Fallback: Query families where this user is a member
            let memberQuery = db.collectionGroup("members")
                .whereField("userId", isEqualTo: currentUserId)
                .limit(to: 1)
            let snapshot = try await memberQuery.getDocuments()

            if let memberDoc = snapshot.documents.first {
                // Extract familyId from the document path: families/{familyId}/members/{uid}
                let pathComponents = memberDoc.reference.path.components(separatedBy: "/")
                if pathComponents.count >= 2 {
                    let familyId = pathComponents[1]
                    self.currentFamilyId = familyId
                    await loadFamily(familyId: familyId)
                    setupFamilyListeners(familyId: familyId)
                }
            }
            // If no family found, user needs to create/join — that's fine
        } catch {
            authError = "Failed to load profile: \(error.localizedDescription)"
        }
    }

    // MARK: - Load Family
    private func loadFamily(familyId: String) async {
        do {
            let familyDoc = try await db.document("families/\(familyId)").getDocument()
            if let data = familyDoc.data() {
                currentFamily = Family(
                    id: familyId,
                    name: data["name"] as? String ?? "",
                    createdBy: data["createdBy"] as? String ?? "",
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    inviteCode: data["inviteCode"] as? String
                )
            }
        } catch {
            authError = "Failed to load family: \(error.localizedDescription)"
        }
    }

    // MARK: - Live Listeners
    private func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }

    public func setupFamilyListeners(familyId: String) {
        removeAllListeners()
        self.currentFamilyId = familyId

        // Members listener
        let membersListener = db.collection("families/\(familyId)/members")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self = self, let documents = snapshot?.documents else { return }
                    self.members = documents.compactMap { doc in
                        let data = doc.data()
                        return FamilyMember(
                            id: doc.documentID,
                            userId: data["userId"] as? String ?? "",
                            role: MemberRole(rawValue: data["role"] as? String ?? "child") ?? .child,
                            phoneNumber: data["phoneNumber"] as? String ?? "",
                            displayName: data["displayName"] as? String ?? "",
                            email: data["email"] as? String
                        )
                    }
                    // After members loaded, set up checkin listeners for parents
                    self.setupParentCheckinListeners(familyId: familyId)
                    // Setup medication listeners for parent members
                    self.setupMedicationListeners(familyId: familyId)
                }
            }
        listeners.append(membersListener)

        // Care Schedule listener
        let scheduleListener = db.collection("families/\(familyId)/careSchedule")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self = self, let documents = snapshot?.documents else { return }
                    self.careSchedule = documents.compactMap { doc in
                        let data = doc.data()
                        return CareScheduleEntry(
                            id: doc.documentID,
                            familyMemberId: data["familyMemberId"] as? String ?? "",
                            dayOfWeek: data["dayOfWeek"] as? Int ?? 1,
                            notes: data["notes"] as? String ?? ""
                        )
                    }
                }
            }
        listeners.append(scheduleListener)

        // Health Records listener
        let healthListener = db.collection("families/\(familyId)/healthRecords")
            .order(by: "visitDate", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self = self, let documents = snapshot?.documents else { return }
                    self.healthRecords = documents.compactMap { doc in
                        let data = doc.data()
                        return HealthRecord(
                            id: doc.documentID,
                            familyMemberId: data["familyMemberId"] as? String ?? "",
                            photoUrl: data["photoUrl"] as? String ?? "",
                            doctorName: data["doctorName"] as? String ?? "",
                            visitDate: (data["visitDate"] as? Timestamp)?.dateValue() ?? Date(),
                            followUpDate: (data["followUpDate"] as? Timestamp)?.dateValue(),
                            tags: data["tags"] as? [String] ?? [],
                            addedBy: data["addedBy"] as? String ?? ""
                        )
                    }
                }
            }
        listeners.append(healthListener)

        // Alerts listener
        let alertsListener = db.collection("families/\(familyId)/alerts")
            .order(by: "triggeredAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self = self, let documents = snapshot?.documents else { return }
                    self.alerts = documents.compactMap { doc in
                        let data = doc.data()
                        return CareAlert(
                            id: doc.documentID,
                            familyMemberId: data["familyMemberId"] as? String ?? "",
                            date: data["date"] as? String ?? "",
                            triggeredAt: (data["triggeredAt"] as? Timestamp)?.dateValue() ?? Date(),
                            resolvedAt: (data["resolvedAt"] as? Timestamp)?.dateValue(),
                            resolvedBy: data["resolvedBy"] as? String,
                            resolution: AlertResolution(rawValue: data["resolution"] as? String ?? "")
                        )
                    }
                }
            }
        listeners.append(alertsListener)
    }

    // MARK: - Parent Checkin Listeners (for today)
    private func setupParentCheckinListeners(familyId: String) {
        let today = todayDateString()
        let parentMembers = members.filter { $0.role == .parent }

        for parent in parentMembers {
            let checkinListener = db.document("families/\(familyId)/members/\(parent.id)/checkins/\(today)")
                .addSnapshotListener { [weak self] snapshot, error in
                    Task { @MainActor in
                        guard let self = self else { return }
                        if let data = snapshot?.data() {
                            let checkin = DailyCheckin(
                                id: today,
                                checkedInAt: (data["checkedInAt"] as? Timestamp)?.dateValue(),
                                status: CheckinStatus(rawValue: data["status"] as? String ?? "none") ?? .none,
                                graceWindowExpiresAt: (data["graceWindowExpiresAt"] as? Timestamp)?.dateValue(),
                                resolvedAt: (data["resolvedAt"] as? Timestamp)?.dateValue(),
                                resolvedBy: data["resolvedBy"] as? String,
                                resolution: AlertResolution(rawValue: data["resolution"] as? String ?? ""),
                                activeAlert: data["activeAlert"] as? Bool ?? false
                            )
                            self.parentCheckins[parent.id] = checkin
                        } else {
                            self.parentCheckins[parent.id] = DailyCheckin(id: today, status: .none)
                        }
                    }
                }
            listeners.append(checkinListener)
        }
    }

    // MARK: - Medication Listeners (for first parent found)
    private func setupMedicationListeners(familyId: String) {
        let parentMembers = members.filter { $0.role == .parent }
        guard let firstParent = parentMembers.first else { return }

        let medsListener = db.collection("families/\(familyId)/members/\(firstParent.id)/medications")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self = self, let documents = snapshot?.documents else { return }
                    let today = self.todayDateString()
                    var meds: [Medication] = []
                    for doc in documents {
                        let data = doc.data()
                        var med = Medication(
                            id: doc.documentID,
                            name: data["name"] as? String ?? "",
                            scheduledTime: data["scheduledTime"] as? String ?? "",
                            createdBy: data["createdBy"] as? String ?? "",
                            isTakenToday: false
                        )
                        // Check today's log
                        do {
                            let logDoc = try await self.db.document(
                                "families/\(familyId)/members/\(firstParent.id)/medications/\(doc.documentID)/logs/\(today)"
                            ).getDocument()
                            med.isTakenToday = logDoc.exists && logDoc.data()?["takenAt"] != nil
                        } catch {
                            // Log fetch failed, default to not taken
                        }
                        meds.append(med)
                    }
                    self.medications = meds
                }
            }
        listeners.append(medsListener)
    }

    // MARK: - Create Family (Firestore Direct - Spark Plan Compatible)
    public func createFamily(name: String, displayName: String, role: MemberRole, email: String = "", phoneNumber: String = "") async throws -> String {
        guard !currentUserId.isEmpty else {
            throw NSError(domain: "CareCircle", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }
        isLoading = true
        defer { isLoading = false }

        let inviteCode = generateInviteCode()
        let familyRef = db.collection("families").document()
        let familyId = familyRef.documentID
        let memberEmail = email.isEmpty ? authEmail : email

        let batch = db.batch()

        // 1. Create family document
        batch.setData([
            "name": name.trimmingCharacters(in: .whitespaces),
            "createdBy": currentUserId,
            "createdAt": FieldValue.serverTimestamp(),
            "inviteCode": inviteCode
        ], forDocument: familyRef)

        // 2. Add creator as member
        let memberRef = db.document("families/\(familyId)/members/\(currentUserId)")
        batch.setData([
            "userId": currentUserId,
            "role": role.rawValue,
            "email": memberEmail,
            "phoneNumber": phoneNumber,
            "displayName": displayName
        ], forDocument: memberRef)

        // 3. Save invite document
        let inviteRef = db.document("invites/\(inviteCode)")
        batch.setData([
            "familyId": familyId,
            "createdBy": currentUserId,
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: inviteRef)

        // 4. Update user profile link
        let userRef = db.document("users/\(currentUserId)")
        batch.setData([
            "familyId": familyId,
            "role": role.rawValue,
            "displayName": displayName,
            "email": memberEmail,
            "phoneNumber": phoneNumber,
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: userRef, merge: true)

        try await batch.commit()

        self.currentFamilyId = familyId
        await loadFamily(familyId: familyId)
        setupFamilyListeners(familyId: familyId)
        return inviteCode
    }

    // Helper: generate random non-sequential 6-character code
    private func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).compactMap { _ in chars.randomElement() })
    }

    // MARK: - Join Family (Firestore Direct - Spark Plan Compatible)
    public func joinFamily(inviteCode: String, displayName: String, role: MemberRole, email: String = "", phoneNumber: String = "") async throws {
        guard !currentUserId.isEmpty else {
            throw NSError(domain: "CareCircle", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }
        isLoading = true
        defer { isLoading = false }

        let codeUpper = inviteCode.trimmingCharacters(in: .whitespaces).uppercased()
        guard !codeUpper.isEmpty else {
            throw NSError(domain: "CareCircle", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invite code is required."])
        }
        let memberEmail = email.isEmpty ? authEmail : email

        // 1. Read invite document
        let inviteDoc = try await db.document("invites/\(codeUpper)").getDocument()
        guard inviteDoc.exists, let inviteData = inviteDoc.data(), let familyId = inviteData["familyId"] as? String else {
            throw NSError(domain: "CareCircle", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invalid or expired invite code."])
        }

        let batch = db.batch()

        // 2. Add member document
        let memberRef = db.document("families/\(familyId)/members/\(currentUserId)")
        batch.setData([
            "userId": currentUserId,
            "role": role.rawValue,
            "email": memberEmail,
            "phoneNumber": phoneNumber,
            "displayName": displayName
        ], forDocument: memberRef, merge: true)

        // 3. Update user profile link
        let userRef = db.document("users/\(currentUserId)")
        batch.setData([
            "familyId": familyId,
            "role": role.rawValue,
            "displayName": displayName,
            "email": memberEmail,
            "phoneNumber": phoneNumber,
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: userRef, merge: true)

        try await batch.commit()

        self.currentFamilyId = familyId
        await loadFamily(familyId: familyId)
        setupFamilyListeners(familyId: familyId)
    }

    // MARK: - Parent Check-in Write Path
    public func recordParentCheckin(memberId: String) {
        let today = todayDateString()
        let checkinRef = db.document("families/\(currentFamilyId)/members/\(memberId)/checkins/\(today)")

        checkinRef.setData([
            "checkedInAt": FieldValue.serverTimestamp(),
            "status": "ok",
            "activeAlert": false
        ], merge: true) { error in
            if let error = error {
                Task { @MainActor in
                    self.authError = "Check-in failed: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Medication Checkoff
    public func toggleMedicationTaken(medId: String) {
        guard let firstParent = members.first(where: { $0.role == .parent }) else { return }
        let today = todayDateString()
        let logRef = db.document(
            "families/\(currentFamilyId)/members/\(firstParent.id)/medications/\(medId)/logs/\(today)"
        )

        let currentlyTaken = medications.first(where: { $0.id == medId })?.isTakenToday ?? false

        if currentlyTaken {
            logRef.delete()
        } else {
            logRef.setData(["takenAt": FieldValue.serverTimestamp()])
        }

        // Optimistic local update
        if let idx = medications.firstIndex(where: { $0.id == medId }) {
            medications[idx].isTakenToday = !currentlyTaken
        }
    }

    // MARK: - Alert Simulation (DEBUG only)
    #if DEBUG
    public func simulateGracePeriodTrigger(memberId: String) {
        let today = todayDateString()
        let checkinRef = db.document("families/\(currentFamilyId)/members/\(memberId)/checkins/\(today)")

        checkinRef.setData([
            "status": "waiting",
            "checkedInAt": NSNull(),
            "graceWindowExpiresAt": Timestamp(date: Date().addingTimeInterval(90 * 60))
        ], merge: true)
    }

    public func simulateMissedAlertTrigger(memberId: String) {
        let today = todayDateString()
        let checkinRef = db.document("families/\(currentFamilyId)/members/\(memberId)/checkins/\(today)")

        checkinRef.setData([
            "status": "missed",
            "checkedInAt": NSNull(),
            "activeAlert": true,
            "missedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
    #endif

    // MARK: - Alert Resolution
    public func resolveAlert(alertId: String, resolution: AlertResolution) {
        let alertRef = db.document("families/\(currentFamilyId)/alerts/\(alertId)")

        alertRef.updateData([
            "resolvedAt": FieldValue.serverTimestamp(),
            "resolvedBy": currentUserId,
            "resolution": resolution.rawValue
        ]) { error in
            if let error = error {
                Task { @MainActor in
                    self.authError = "Failed to resolve alert: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Add Health Record
    public func addHealthRecord(
        familyMemberId: String,
        doctorName: String,
        visitDate: Date,
        followUpDate: Date?,
        tags: [String],
        photoUrl: String
    ) {
        let recordRef = db.collection("families/\(currentFamilyId)/healthRecords").document()

        var data: [String: Any] = [
            "familyMemberId": familyMemberId,
            "doctorName": doctorName,
            "visitDate": Timestamp(date: visitDate),
            "tags": tags,
            "addedBy": currentUserId,
            "photoUrl": photoUrl
        ]
        if let followUp = followUpDate {
            data["followUpDate"] = Timestamp(date: followUp)
        }

        recordRef.setData(data) { error in
            if let error = error {
                Task { @MainActor in
                    self.authError = "Failed to add health record: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Upload Health Record Photo (Disabled on Spark plan)
    public func uploadHealthRecordPhoto(imageData: Data) async throws -> String {
        throw NSError(
            domain: "CareCircle",
            code: 403,
            userInfo: [NSLocalizedDescriptionKey: "Photo attachments are temporarily disabled on the free Spark plan."]
        )
    }

    // MARK: - Add Care Schedule Entry
    public func addCareScheduleEntry(familyMemberId: String, dayOfWeek: Int, notes: String) {
        let entryRef = db.collection("families/\(currentFamilyId)/careSchedule").document()

        entryRef.setData([
            "familyMemberId": familyMemberId,
            "dayOfWeek": dayOfWeek,
            "notes": notes
        ]) { error in
            if let error = error {
                Task { @MainActor in
                    self.authError = "Failed to add schedule entry: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Invite Member (add directly as a placeholder member)
    public func inviteMember(displayName: String, email: String = "", phoneNumber: String = "", role: MemberRole) {
        // Create a placeholder member doc with a generated ID
        // The invited user will claim this when they sign up
        let memberRef = db.collection("families/\(currentFamilyId)/members").document()

        memberRef.setData([
            "userId": memberRef.documentID,
            "role": role.rawValue,
            "email": email,
            "phoneNumber": phoneNumber,
            "displayName": displayName
        ]) { error in
            if let error = error {
                Task { @MainActor in
                    self.authError = "Failed to invite member: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Add Medication
    public func addMedication(parentMemberId: String, name: String, scheduledTime: String) {
        let medRef = db.collection("families/\(currentFamilyId)/members/\(parentMemberId)/medications").document()

        medRef.setData([
            "name": name,
            "scheduledTime": scheduledTime,
            "createdBy": currentUserId
        ])
    }
}
