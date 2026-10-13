import SwiftUI

// MARK: - Alerts History View
// Screen 2e: Past missed-check-in events, each showing whether and how
// it was resolved (confirmed OK vs. false alarm), and by whom.

public struct AlertsHistoryView: View {
    @ObservedObject var service: FirebaseService
    @State private var resolvingAlert: CareAlert?

    public init(service: FirebaseService = .shared) {
        self.service = service
    }

    private var unresolvedAlerts: [CareAlert] {
        service.alerts.filter { !$0.isResolved }
    }

    private var resolvedAlerts: [CareAlert] {
        service.alerts.filter { $0.isResolved }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CCSpacing.lg) {
                    // Header
                    CCScreenHeader(
                        title: "Alerts & History",
                        subtitle: "Audit trail of missed check-in events and resolutions"
                    )
                    .padding(.horizontal, CCSpacing.lg)
                    .padding(.top, CCSpacing.sm)

                    if service.alerts.isEmpty {
                        CCEmptyState(
                            icon: "checkmark.shield.fill",
                            title: "No Alert Incidents Recorded",
                            message: "All daily check-ins have completed smoothly without confirmed missed alerts."
                        )
                        .padding(.horizontal, CCSpacing.lg)
                        .padding(.top, CCSpacing.xl)
                    } else {
                        // Section: Needs Attention (if any)
                        if !unresolvedAlerts.isEmpty {
                            VStack(alignment: .leading, spacing: CCSpacing.sm) {
                                CCSectionHeader(
                                    title: "Needs Attention",
                                    trailing: {
                                        CCStatusChip(text: "\(unresolvedAlerts.count)", tone: .alert, icon: "exclamationmark.triangle.fill")
                                    }
                                )
                                .padding(.horizontal, CCSpacing.lg)

                                VStack(spacing: 12) {
                                    ForEach(unresolvedAlerts) { alert in
                                        AlertHistoryCard(
                                            alert: alert,
                                            service: service,
                                            onResolve: {
                                                resolvingAlert = alert
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, CCSpacing.lg)
                            }
                        }

                        // Section: Resolved
                        if !resolvedAlerts.isEmpty {
                            VStack(alignment: .leading, spacing: CCSpacing.sm) {
                                CCSectionHeader(
                                    title: "Resolved",
                                    trailing: {
                                        Text("\(resolvedAlerts.count)")
                                            .font(.familyCaption())
                                            .foregroundColor(Color.ccTextSecondary)
                                    }
                                )
                                .padding(.horizontal, CCSpacing.lg)

                                VStack(spacing: 12) {
                                    ForEach(resolvedAlerts) { alert in
                                        AlertHistoryCard(
                                            alert: alert,
                                            service: service,
                                            onResolve: nil
                                        )
                                    }
                                }
                                .padding(.horizontal, CCSpacing.lg)
                            }
                        }
                    }

                    Spacer(minLength: 96)
                }
            }
            .paperBackground()
            .sheet(item: $resolvingAlert) { alert in
                ResolveAlertSheet(alert: alert, service: service)
            }
        }
    }
}

// MARK: - Alert History Card
@MainActor
struct AlertHistoryCard: View {
    let alert: CareAlert
    @ObservedObject var service: FirebaseService
    var onResolve: (() -> Void)? = nil

    private var parent: FamilyMember? {
        service.members.first(where: { $0.id == alert.familyMemberId })
    }

    private var resolver: FamilyMember? {
        if let resolverId = alert.resolvedBy {
            return service.members.first(where: { $0.id == resolverId || $0.userId == resolverId })
        }
        return nil
    }

    private var parentName: String {
        parent?.displayName ?? "Parent Member"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CCSpacing.sm) {
            // Header Row: Avatar + Name + Date + Status Chip
            HStack(alignment: .center, spacing: CCSpacing.sm) {
                CCAvatar(name: parentName, tone: .alert, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(parentName)
                        .font(.familyBodyBold())
                        .foregroundColor(Color.ccInk)

                    Text(CCFormatters.isoDay(from: alert.date))
                        .font(.familyCaption())
                        .foregroundColor(Color.ccTextSecondary)
                }

                Spacer()

                // Status chip
                if let resolution = alert.resolution {
                    if resolution == .confirmedOk {
                        CCStatusChip(text: "Confirmed OK", tone: .hearth, icon: "checkmark")
                    } else {
                        CCStatusChip(text: "False Alarm", tone: .waiting, icon: "clock.arrow.circlepath")
                    }
                } else {
                    CCStatusChip(text: "Unresolved", tone: .alert, icon: "exclamationmark.triangle.fill")
                }
            }

            Rectangle()
                .fill(Color.ccHairline)
                .frame(height: 1)

            // Mini Vertical Timeline
            VStack(alignment: .leading, spacing: 6) {
                // Triggered event
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color.ccAlert)
                        .frame(width: 8, height: 8)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Triggered")
                            .font(.familyCaption())
                            .fontWeight(.semibold)
                            .foregroundColor(Color.ccInk)
                        Text(CCFormatters.shortDateTime.string(from: alert.triggeredAt))
                            .font(.familyCaption())
                            .foregroundColor(Color.ccTextSecondary)
                    }
                }

                // Connecting line if resolved
                if let resolvedAt = alert.resolvedAt {
                    Rectangle()
                        .fill(Color.ccHairline)
                        .frame(width: 2, height: 12)
                        .padding(.leading, 3)

                    // Resolved event
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.ccHearth)
                            .frame(width: 8, height: 8)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(alert.resolution == .confirmedOk ? "Confirmed OK" : "Marked False Alarm")
                                .font(.familyCaption())
                                .fontWeight(.semibold)
                                .foregroundColor(Color.ccInk)

                            Text("\(CCFormatters.shortDateTime.string(from: resolvedAt)) \(resolver != nil ? "by \(resolver!.displayName)" : "")")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccTextSecondary)
                        }
                    }
                }
            }
            .padding(.vertical, 2)

            // Inline Resolve Button for Unresolved alerts
            if !alert.isResolved, let onResolve = onResolve {
                Button(action: {
                    CCHaptics.medium()
                    onResolve()
                }) {
                    HStack {
                        Text("Resolve Alert")
                            .font(.familyBodyBold())
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .buttonStyle(CCPrimaryButtonStyle(tone: .alert))
                .padding(.top, 4)
            }
        }
        .padding(CCSpacing.md)
        .background(Color.ccLinen)
        .clipShape(RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                .stroke(alert.isResolved ? Color.ccHairline : Color.ccAlert.opacity(0.3), lineWidth: 1)
        )
    }
}
