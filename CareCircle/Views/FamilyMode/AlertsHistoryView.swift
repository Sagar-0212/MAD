import SwiftUI

// MARK: - Alerts History View
// Screen 2e: Past missed-check-in events, each showing whether and how
// it was resolved (confirmed OK vs. false alarm), and by whom.

public struct AlertsHistoryView: View {
    @ObservedObject var service: FirebaseService

    public init(service: FirebaseService = .shared) {
        self.service = service
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Alerts & Check-in History")
                            .font(.familyHeadingLarge())
                            .foregroundColor(Color.ccInk)
                        Text("Audit trail of missed check-in events and resolutions")
                            .font(.familyCaption())
                            .foregroundColor(Color.ccInk.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    if service.alerts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.shield")
                                .font(.system(size: 40))
                                .foregroundColor(Color.ccHearth.opacity(0.5))
                                .padding(.top, 32)

                            Text("No Alert Incidents Recorded")
                                .font(.familyHeadingMedium())
                                .foregroundColor(Color.ccInk)

                            Text("All daily check-ins have completed smoothly without confirmed missed alerts.")
                                .font(.familyBody())
                                .foregroundColor(Color.ccInk.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    } else {
                        VStack(spacing: 14) {
                            ForEach(service.alerts) { alert in
                                AlertHistoryCard(alert: alert, service: service)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 40)
                }
            }
            .paperBackground()
        }
    }
}

// MARK: - Alert History Card
@MainActor
struct AlertHistoryCard: View {
    let alert: CareAlert
    @ObservedObject var service: FirebaseService

    private var parent: FamilyMember? {
        service.members.first(where: { $0.id == alert.familyMemberId })
    }

    private var resolver: FamilyMember? {
        if let resolverId = alert.resolvedBy {
            return service.members.first(where: { $0.id == resolverId || $0.userId == resolverId })
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(parent?.displayName ?? "Parent Member")
                        .font(.familyBodyBold())
                        .foregroundColor(Color.ccInk)

                    Text("Date: \(alert.date)")
                        .font(.familyNumeral(size: 13))
                        .foregroundColor(Color.ccInk.opacity(0.6))
                }

                Spacer()

                // Resolution Badge
                if let resolution = alert.resolution {
                    Text(resolution.displayTitle)
                        .font(.familyCaption())
                        .foregroundColor(resolution == .confirmedOk ? Color.ccHearth : Color.ccWaiting)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            (resolution == .confirmedOk ? Color.ccHearth : Color.ccWaiting).opacity(0.12)
                        )
                        .clipShape(Capsule())
                } else {
                    Text("Unresolved")
                        .font(.familyCaption())
                        .foregroundColor(Color.ccAlert)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.ccAlert.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Rectangle()
                .fill(Color.ccHairline)
                .frame(height: 1)

            // Timeline details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Triggered:")
                        .font(.familyCaption())
                        .foregroundColor(Color.ccInk.opacity(0.55))
                    Text(formattedTime(alert.triggeredAt))
                        .font(.familyNumeral(size: 12))
                        .foregroundColor(Color.ccInk)
                }

                if let resolvedAt = alert.resolvedAt {
                    HStack {
                        Text("Resolved:")
                            .font(.familyCaption())
                            .foregroundColor(Color.ccInk.opacity(0.55))
                        Text(formattedTime(resolvedAt))
                            .font(.familyNumeral(size: 12))
                            .foregroundColor(Color.ccInk)
                        
                        if let rName = resolver?.displayName {
                            Text("by \(rName)")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccInk.opacity(0.75))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.ccLinen)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.ccHairline, lineWidth: 1)
        )
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
