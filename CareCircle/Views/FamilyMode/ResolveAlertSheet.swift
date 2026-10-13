import SwiftUI

// MARK: - Resolve Alert Sheet
// One-tap resolution for missed check-in alerts:
// Allows family child member to mark "Confirmed OK" or "False Alarm".
// Synchronizes directly with Firestore trigger to clear the alert state.

struct ResolveAlertSheet: View {
    let alert: CareAlert
    @ObservedObject var service: FirebaseService
    @Environment(\.dismiss) private var dismiss

    private var parent: FamilyMember? {
        service.members.first(where: { $0.id == alert.familyMemberId })
    }

    private var parentName: String {
        parent?.displayName ?? "Parent Member"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: CCSpacing.lg) {
                // Header
                VStack(spacing: CCSpacing.xs) {
                    ZStack {
                        Circle()
                            .fill(Color.ccAlertSoft)
                            .frame(width: 64, height: 64)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color.ccAlert)
                    }
                    .padding(.top, CCSpacing.md)

                    Text("Resolve Missed Check-In")
                        .font(.familyHeadingMedium())
                        .foregroundColor(Color.ccInk)

                    Text("for \(parentName) · \(CCFormatters.isoDay(from: alert.date))")
                        .font(.familyBody())
                        .foregroundColor(Color.ccTextSecondary)
                }

                Text("Please confirm that you have checked in with your parent and choose how to resolve this alert.")
                    .font(.familyCaption())
                    .foregroundColor(Color.ccTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CCSpacing.lg)

                VStack(spacing: CCSpacing.sm) {
                    // Option 1: Confirmed OK
                    Button(action: {
                        CCHaptics.success()
                        service.resolveAlert(alertId: alert.id, resolution: .confirmedOk)
                        dismiss()
                    }) {
                        HStack(spacing: CCSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.ccHearthSoft)
                                    .frame(width: 48, height: 48)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.ccHearth)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Confirmed OK")
                                    .font(.familyBodyBold())
                                    .foregroundColor(Color.ccInk)
                                Text("Spoke with parent; they are safe and confirmed doing well.")
                                    .font(.familyCaption())
                                    .foregroundColor(Color.ccTextSecondary)
                            }

                            Spacer()
                        }
                        .padding(CCSpacing.md)
                        .background(Color.ccSurfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                                .stroke(Color.ccHairline, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    // Option 2: False Alarm
                    Button(action: {
                        CCHaptics.success()
                        service.resolveAlert(alertId: alert.id, resolution: .falseAlarm)
                        dismiss()
                    }) {
                        HStack(spacing: CCSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.ccWaitingSoft)
                                    .frame(width: 48, height: 48)
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Color.ccWaiting)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("False Alarm")
                                    .font(.familyBodyBold())
                                    .foregroundColor(Color.ccInk)
                                Text("Parent was busy, traveling, or check-in was delayed.")
                                    .font(.familyCaption())
                                    .foregroundColor(Color.ccTextSecondary)
                            }

                            Spacer()
                        }
                        .padding(CCSpacing.md)
                        .background(Color.ccSurfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                                .stroke(Color.ccHairline, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, CCSpacing.lg)

                Spacer()
            }
            .paperBackground()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.familyBody())
                    .foregroundColor(Color.ccInk)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
