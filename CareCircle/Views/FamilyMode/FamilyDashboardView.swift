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

    public init(service: FirebaseService = .shared) {
        self.service = service
    }

    private var parentMembers: [FamilyMember] {
        service.members.filter { $0.role == .parent }
    }

    private var unresolvedAlerts: [CareAlert] {
        service.alerts.filter { !$0.isResolved }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(service.currentFamily.name)
                                .font(.familyHeadingLarge())
                                .foregroundColor(Color.ccInk)

                            Text("Today's Family Circle")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccInk.opacity(0.6))
                        }

                        Spacer()

                        Text(formattedDate())
                            .font(.familyNumeral(size: 13))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.ccLinen)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundColor(Color.ccInk)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Active Alert Banner (if any parent missed checkin)
                    if let activeAlert = unresolvedAlerts.first {
                        let parent = service.members.first(where: { $0.id == activeAlert.familyMemberId })
                        let parentName = parent?.displayName ?? "A family member"

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color.ccPaper)
                                    .font(.system(size: 18))

                                Text("Missed Check-In Alert")
                                    .font(.familyBodyBold())
                                    .foregroundColor(Color.ccPaper)

                                Spacer()

                                Text(activeAlert.date)
                                    .font(.familyNumeral(size: 12))
                                    .foregroundColor(Color.ccPaper.opacity(0.8))
                            }

                            Text("\(parentName) has not checked in today. Grace window elapsed.")
                                .font(.familyBody())
                                .foregroundColor(Color.ccPaper.opacity(0.95))

                            Button(action: {
                                resolvingAlert = activeAlert
                            }) {
                                HStack {
                                    Text("Resolve Alert")
                                        .font(.familyBodyBold())
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(Color.ccAlert)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.ccPaper)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(18)
                        .background(Color.ccAlert)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)
                    }

                    // Signature Radial Status Circles
                    VStack(spacing: 12) {
                        RadialStatusCirclesView(
                            parents: parentMembers,
                            checkins: service.parentCheckins,
                            onSelectParent: { parent in
                                selectedParent = parent
                            }
                        )

                        // Status Legend
                        HStack(spacing: 14) {
                            LegendItem(color: Color.ccPaper, stroke: Color.ccInk.opacity(0.4), label: "Waiting")
                            LegendItem(color: Color.ccHearth, label: "Checked In")
                            LegendItem(color: Color.ccWaiting, label: "Grace Window")
                            LegendItem(color: Color.ccAlert, label: "Missed")
                        }
                        .padding(.top, 4)
                    }

                    // Divider
                    Rectangle()
                        .fill(Color.ccHairline)
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    // Today's Medication Checklist (Read-only from Family side)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Medications Checklist")
                                .font(.familyHeadingMedium())
                                .foregroundColor(Color.ccInk)

                            Spacer()

                            Text("Read-only")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccInk.opacity(0.45))
                        }
                        .padding(.horizontal, 24)

                        VStack(spacing: 10) {
                            ForEach(service.medications) { med in
                                let isTaken = med.isTakenToday ?? false
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(isTaken ? Color.ccHearth : Color.ccPaper)
                                        .frame(width: 22, height: 22)
                                        .overlay(
                                            Circle()
                                                .stroke(isTaken ? Color.clear : Color.ccInk.opacity(0.3), lineWidth: 1.5)
                                        )
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(Color.ccPaper)
                                                .opacity(isTaken ? 1 : 0)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(med.name)
                                            .font(.familyBody())
                                            .foregroundColor(Color.ccInk)
                                        Text(med.scheduledTime)
                                            .font(.familyNumeral(size: 12))
                                            .foregroundColor(Color.ccInk.opacity(0.55))
                                    }

                                    Spacer()

                                    Text(isTaken ? "Taken" : "Pending")
                                        .font(.familyCaption())
                                        .foregroundColor(isTaken ? Color.ccHearth : Color.ccInk.opacity(0.4))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.ccLinen)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.ccHairline, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Divider
                    Rectangle()
                        .fill(Color.ccHairline)
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    // This Week's Care Schedule
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("This Week's Care Schedule")
                                .font(.familyHeadingMedium())
                                .foregroundColor(Color.ccInk)
                            Spacer()
                        }
                        .padding(.horizontal, 24)

                        VStack(spacing: 10) {
                            ForEach(service.careSchedule) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.dayName)
                                            .font(.familyBodyBold())
                                            .foregroundColor(Color.ccInk)
                                        Text(entry.notes)
                                            .font(.familyBody())
                                            .foregroundColor(Color.ccInk.opacity(0.75))
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.ccLinen)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.ccHairline, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    #if DEBUG
                    // Test / Simulation loop toolbar (for verifying checkin -> grace -> missed -> resolve)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Live Backend Loop Simulator (DEBUG only)")
                            .font(.familyHeadingSmall())
                            .foregroundColor(Color.ccInk.opacity(0.6))
                            .padding(.horizontal, 24)

                        HStack(spacing: 10) {
                            Button("Simulate Grace") {
                                if let p = parentMembers.first {
                                    service.simulateGracePeriodTrigger(memberId: p.id)
                                }
                            }
                            .font(.familyCaption())
                            .foregroundColor(Color.ccInk)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.ccWaiting.opacity(0.25))
                            .clipShape(Capsule())

                            Button("Simulate Missed") {
                                if let p = parentMembers.first {
                                    service.simulateMissedAlertTrigger(memberId: p.id)
                                }
                            }
                            .font(.familyCaption())
                            .foregroundColor(Color.ccAlert)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.ccAlert.opacity(0.15))
                            .clipShape(Capsule())

                            Button("Check In") {
                                if let p = parentMembers.first {
                                    service.recordParentCheckin(memberId: p.id)
                                }
                            }
                            .font(.familyCaption())
                            .foregroundColor(Color.ccHearth)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.ccHearth.opacity(0.15))
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 8)
                    #endif

                    Spacer(minLength: 40)
                }
            }
            .paperBackground()
            .sheet(item: $resolvingAlert) { alert in
                ResolveAlertSheet(alert: alert, service: service)
            }
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    var stroke: Color? = nil
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle().stroke(stroke ?? Color.clear, lineWidth: stroke != nil ? 1 : 0)
                )

            Text(label)
                .font(.familyCaption())
                .foregroundColor(Color.ccInk.opacity(0.6))
        }
    }
}
