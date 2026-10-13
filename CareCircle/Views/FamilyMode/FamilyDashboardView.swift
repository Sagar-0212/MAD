import SwiftUI

// MARK: - Family Dashboard Home View
// Features:
// 1. Signature radial status circles ("Seats at the Table")
// 2. Active alert card with one-tap resolution flow
// 3. Today's medication checklist (read-only from family side)
// 4. This week's care schedule summary
// 5. Test/simulation controls for full loop verification

public struct FamilyDashboardView: View {
    @ObservedObject var service: FirebaseService
    @State private var selectedParent: FamilyMember?
    @State private var resolvingAlert: CareAlert?
    @State private var isDevToolsExpanded: Bool = false
    @State private var pulseDot: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(service: FirebaseService = .shared) {
        self.service = service
    }

    private var parentMembers: [FamilyMember] {
        service.members.filter { $0.role == .parent }
    }

    private var unresolvedAlerts: [CareAlert] {
        service.alerts.filter { !$0.isResolved }
    }

    private var checkedInParentsCount: Int {
        parentMembers.filter { service.parentCheckins[$0.id]?.status == .ok }.count
    }

    private var overallSummaryStatus: (text: String, tone: CCStatusTone, icon: String) {
        let statuses = parentMembers.map { service.parentCheckins[$0.id]?.status ?? .none }
        if statuses.contains(.missed) {
            return ("Missed Check-In", .alert, "exclamationmark.triangle.fill")
        } else if statuses.contains(.waiting) {
            return ("Grace Period", .waiting, "hourglass")
        } else if !parentMembers.isEmpty && checkedInParentsCount == parentMembers.count {
            return ("All Checked In", .hearth, "checkmark.circle.fill")
        } else {
            return ("Awaiting Check-Ins", .neutral, "clock")
        }
    }

    private var todayDayName: String {
        CCFormatters.weekday.string(from: Date())
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CCSpacing.lg) {
                    // Header
                    CCScreenHeader(
                        title: service.currentFamily.name,
                        subtitle: "Today's Family Circle",
                        trailing: {
                            Text(CCFormatters.dayMonth.string(from: Date()))
                                .font(.familyCaption())
                                .fontWeight(.semibold)
                                .foregroundColor(Color.ccInk)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.ccSurfaceRaised)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.ccHairline, lineWidth: 1))
                        }
                    )
                    .padding(.horizontal, CCSpacing.lg)
                    .padding(.top, CCSpacing.sm)

                    // Status Summary Card (Read-only)
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(checkedInParentsCount) of \(parentMembers.count) parents checked in")
                                .font(.familyBodyBold())
                                .foregroundColor(Color.ccInk)

                            Text(parentMembers.count == 1 ? "Daily check-in status" : "Combined family circle status")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccTextSecondary)
                        }

                        Spacer()

                        CCStatusChip(
                            text: overallSummaryStatus.text,
                            tone: overallSummaryStatus.tone,
                            icon: overallSummaryStatus.icon
                        )
                    }
                    .padding(CCSpacing.md)
                    .linenCard()
                    .padding(.horizontal, CCSpacing.lg)

                    // Active Alert Banner (if any parent missed checkin)
                    if let activeAlert = unresolvedAlerts.first {
                        let parent = service.members.first(where: { $0.id == activeAlert.familyMemberId })
                        let parentName = parent?.displayName ?? "A family member"

                        VStack(alignment: .leading, spacing: CCSpacing.sm) {
                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.ccPaper)
                                        .frame(width: 8, height: 8)
                                        .opacity(pulseDot ? 0.3 : 1.0)

                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(Color.ccPaper)
                                        .font(.system(size: 16))

                                    Text("Missed Check-In Alert")
                                        .font(.familyBodyBold())
                                        .foregroundColor(Color.ccPaper)
                                }

                                Spacer()

                                Text(CCFormatters.isoDay(from: activeAlert.date))
                                    .font(.familyCaption())
                                    .foregroundColor(Color.ccPaper.opacity(0.85))
                            }

                            Text("\(parentName) has not checked in today. Grace window elapsed.")
                                .font(.familyBody())
                                .foregroundColor(Color.ccPaper.opacity(0.95))

                            if unresolvedAlerts.count > 1 {
                                Text("+\(unresolvedAlerts.count - 1) more unresolved alert")
                                    .font(.familyCaption())
                                    .foregroundColor(Color.ccPaper.opacity(0.8))
                            }

                            Button(action: {
                                CCHaptics.medium()
                                resolvingAlert = activeAlert
                            }) {
                                HStack {
                                    Text("Resolve Alert")
                                        .font(.familyBodyBold())
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(Color.ccAlert)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .background(Color.ccPaper)
                                .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm, style: .continuous))
                            }
                        }
                        .padding(CCSpacing.md)
                        .background(Color.ccAlert)
                        .clipShape(RoundedRectangle(cornerRadius: CCRadius.lg, style: .continuous))
                        .padding(.horizontal, CCSpacing.lg)
                    }

                    // Signature Radial Status Circles ("Seats at the Table")
                    VStack(spacing: CCSpacing.sm) {
                        RadialStatusCirclesView(
                            parents: parentMembers,
                            checkins: service.parentCheckins,
                            onSelectParent: { parent in
                                selectedParent = parent
                            }
                        )

                        // Status Legend in 2x2 wrapping grid for Dynamic Type safety
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            LegendItem(color: Color.ccSurfaceRaised, stroke: Color.ccHairline, label: "Not yet")
                            LegendItem(color: Color.ccHearth, label: "Checked In")
                            LegendItem(color: Color.ccWaiting, label: "Grace Window")
                            LegendItem(color: Color.ccAlert, label: "Missed")
                        }
                        .padding(.horizontal, CCSpacing.xl)
                        .padding(.top, 4)
                    }

                    // Divider
                    Rectangle()
                        .fill(Color.ccHairline)
                        .frame(height: 1)
                        .padding(.horizontal, CCSpacing.lg)

                    // Today's Medication Checklist (Read-only from Family side)
                    VStack(alignment: .leading, spacing: CCSpacing.sm) {
                        CCSectionHeader(
                            title: "Medications Checklist",
                            trailing: {
                                CCStatusChip(text: "Read-only", tone: .neutral, icon: "lock.fill")
                            }
                        )
                        .padding(.horizontal, CCSpacing.lg)

                        if service.medications.isEmpty {
                            CCEmptyState(
                                icon: "pills",
                                title: "No Medications Scheduled",
                                message: "Medication routines for parents will appear here."
                            )
                            .padding(.horizontal, CCSpacing.lg)
                        } else {
                            let taken = service.medications.filter { $0.isTakenToday == true }.count
                            let total = service.medications.count
                            let progress = total > 0 ? CGFloat(taken) / CGFloat(total) : 0

                            // Progress track
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.ccLinen)
                                        .frame(height: 6)
                                    Capsule()
                                        .fill(Color.ccHearth)
                                        .frame(width: geo.size.width * progress, height: 6)
                                }
                            }
                            .frame(height: 6)
                            .padding(.horizontal, CCSpacing.lg)

                            VStack(spacing: 8) {
                                ForEach(service.medications) { med in
                                    let isTaken = med.isTakenToday ?? false
                                    HStack(spacing: CCSpacing.sm) {
                                        ZStack {
                                            Circle()
                                                .fill(isTaken ? Color.ccHearth : Color.ccSurfaceRaised)
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Circle().stroke(isTaken ? Color.clear : Color.ccHairline, lineWidth: 1.5)
                                                )

                                            if isTaken {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(Color.ccPaper)
                                            }
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(med.name)
                                                .font(.familyBody())
                                                .foregroundColor(Color.ccInk)
                                            Text(med.scheduledTime)
                                                .font(.familyCaption())
                                                .foregroundColor(Color.ccTextSecondary)
                                        }

                                        Spacer()

                                        Text(isTaken ? "Taken" : "Pending")
                                            .font(.familyCaption())
                                            .foregroundColor(isTaken ? Color.ccHearth : Color.ccTextTertiary)
                                    }
                                    .padding(.horizontal, CCSpacing.md)
                                    .padding(.vertical, 12)
                                    .background(Color.ccLinen)
                                    .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CCRadius.sm, style: .continuous)
                                            .stroke(Color.ccHairline, lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal, CCSpacing.lg)
                        }
                    }

                    // Divider
                    Rectangle()
                        .fill(Color.ccHairline)
                        .frame(height: 1)
                        .padding(.horizontal, CCSpacing.lg)

                    // This Week's Care Schedule
                    VStack(alignment: .leading, spacing: CCSpacing.sm) {
                        CCSectionHeader(title: "This Week's Care Schedule")
                            .padding(.horizontal, CCSpacing.lg)

                        if service.careSchedule.isEmpty {
                            CCEmptyState(
                                icon: "calendar",
                                title: "No Care Visits Scheduled",
                                message: "Coordinate visits and calls with siblings on the Schedule tab."
                            )
                            .padding(.horizontal, CCSpacing.lg)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(service.careSchedule) { entry in
                                    let isToday = entry.dayName.lowercased() == todayDayName.lowercased()
                                    let assignedMember = service.members.first(where: { $0.userId == entry.familyMemberId || $0.id == entry.familyMemberId })
                                    let memberName = assignedMember?.displayName ?? (entry.familyMemberId.isEmpty ? "Unassigned" : "Family Member")

                                    HStack(spacing: CCSpacing.sm) {
                                        if isToday {
                                            Rectangle()
                                                .fill(Color.ccHearth)
                                                .frame(width: 4)
                                                .clipShape(Capsule())
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Text(entry.dayName)
                                                    .font(.familyBodyBold())
                                                    .foregroundColor(Color.ccInk)

                                                if isToday {
                                                    CCStatusChip(text: "Today", tone: .hearth, icon: nil)
                                                }
                                            }

                                            HStack(spacing: 6) {
                                                CCAvatar(name: memberName, tone: .neutral, size: 22)
                                                Text(memberName)
                                                    .font(.familyCaption())
                                                    .foregroundColor(Color.ccTextSecondary)
                                            }

                                            if !entry.notes.isEmpty {
                                                Text(entry.notes)
                                                    .font(.familyCaption())
                                                    .foregroundColor(Color.ccInk)
                                                    .padding(.top, 2)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, CCSpacing.md)
                                    .padding(.vertical, 12)
                                    .background(isToday ? Color.ccSurfaceRaised : Color.ccLinen)
                                    .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CCRadius.sm, style: .continuous)
                                            .stroke(isToday ? Color.ccHearth.opacity(0.5) : Color.ccHairline, lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal, CCSpacing.lg)
                        }
                    }

                    #if DEBUG
                    // Test / Simulation loop toolbar (DEBUG only) in tidy DisclosureGroup
                    DisclosureGroup("Developer tools", isExpanded: $isDevToolsExpanded) {
                        VStack(alignment: .leading, spacing: CCSpacing.xs) {
                            Text("Live Backend Loop Simulator")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccTextSecondary)

                            HStack(spacing: 8) {
                                Button("Simulate Grace") {
                                    if let p = parentMembers.first {
                                        service.simulateGracePeriodTrigger(memberId: p.id)
                                    }
                                }
                                .font(.familyCaption())
                                .foregroundColor(Color.ccInk)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.ccWaitingSoft)
                                .clipShape(Capsule())

                                Button("Simulate Missed") {
                                    if let p = parentMembers.first {
                                        service.simulateMissedAlertTrigger(memberId: p.id)
                                    }
                                }
                                .font(.familyCaption())
                                .foregroundColor(Color.ccAlert)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.ccAlertSoft)
                                .clipShape(Capsule())

                                Button("Check In") {
                                    if let p = parentMembers.first {
                                        service.recordParentCheckin(memberId: p.id)
                                    }
                                }
                                .font(.familyCaption())
                                .foregroundColor(Color.ccHearth)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.ccHearthSoft)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, CCSpacing.xs)
                    }
                    .font(.familyCaption())
                    .foregroundColor(Color.ccTextSecondary)
                    .padding(.horizontal, CCSpacing.lg)
                    .padding(.top, CCSpacing.xs)
                    #endif

                    // Ensure scroll content clears bottom tab bar and switcher
                    Spacer(minLength: 96)
                }
            }
            .paperBackground()
            .onAppear {
                if !reduceMotion {
                    withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        pulseDot = true
                    }
                }
            }
            .onDisappear {
                pulseDot = false
            }
            .sheet(item: $resolvingAlert) { alert in
                ResolveAlertSheet(alert: alert, service: service)
            }
            .sheet(item: $selectedParent) { parent in
                ParentDetailSheet(parent: parent, service: service)
            }
        }
    }
}

// MARK: - Parent Detail Sheet (Read-only tap from table seat)
struct ParentDetailSheet: View {
    let parent: FamilyMember
    @ObservedObject var service: FirebaseService
    @Environment(\.dismiss) private var dismiss

    private var checkin: DailyCheckin? {
        service.parentCheckins[parent.id]
    }

    private var status: CheckinStatus {
        checkin?.status ?? .none
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: CCSpacing.lg) {
                // Parent Header
                HStack(spacing: CCSpacing.md) {
                    CCAvatar(name: parent.displayName, tone: .hearth, size: 56)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(parent.displayName)
                            .font(.familyHeadingLarge())
                            .foregroundColor(Color.ccInk)

                        if let checkedAt = checkin?.checkedInAt {
                            Text("Checked in at \(CCFormatters.shortTime.string(from: checkedAt))")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccTextSecondary)
                        } else {
                            Text("No check-in recorded yet today")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccTextSecondary)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, CCSpacing.lg)
                .padding(.top, CCSpacing.md)

                // Today's Medications for this parent
                VStack(alignment: .leading, spacing: CCSpacing.xs) {
                    Text("MEDICATIONS")
                        .font(.familyLabel())
                        .foregroundColor(Color.ccTextSecondary)
                        .tracking(1.0)
                        .padding(.horizontal, CCSpacing.lg)

                    if service.medications.isEmpty {
                        Text("No medications scheduled today.")
                            .font(.familyBody())
                            .foregroundColor(Color.ccTextSecondary)
                            .padding(.horizontal, CCSpacing.lg)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(service.medications) { med in
                                let isTaken = med.isTakenToday ?? false
                                HStack {
                                    Text(med.name)
                                        .font(.familyBody())
                                        .foregroundColor(Color.ccInk)
                                    Spacer()
                                    Text(isTaken ? "Taken ✓" : "Pending")
                                        .font(.familyCaption())
                                        .foregroundColor(isTaken ? Color.ccHearth : Color.ccTextTertiary)
                                }
                                .padding(.horizontal, CCSpacing.md)
                                .padding(.vertical, 10)
                                .background(Color.ccLinen)
                                .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm, style: .continuous))
                            }
                        }
                        .padding(.horizontal, CCSpacing.lg)
                    }
                }

                Spacer()
            }
            .paperBackground()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.familyBody())
                    .foregroundColor(Color.ccInk)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    var stroke: Color? = nil
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle().stroke(stroke ?? Color.clear, lineWidth: stroke != nil ? 1 : 0)
                )

            Text(label)
                .font(.familyCaption())
                .foregroundColor(Color.ccTextSecondary)
        }
    }
}
