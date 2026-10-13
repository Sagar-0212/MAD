import SwiftUI

// MARK: - Resolve Alert Sheet
// One-tap resolution for missed check-in alerts:
// Allows family child member to mark "Confirmed OK" or "False Alarm".
// Synchronizes directly with Firestore trigger to clear the alert state.

struct ResolveAlertSheet: View {
    let alert: CareAlert
    @ObservedObject var service: FirebaseService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "shield.checkmark")
                        .font(.system(size: 40))
                        .foregroundColor(Color.ccHearth)
                        .padding(.top, 24)

                    Text("Resolve Missed Check-In")
                        .font(.familyHeadingMedium())
                        .foregroundColor(Color.ccInk)

                    Text("Please confirm that you have checked in with your parent and choose how to resolve this alert.")
                        .font(.familyBody())
                        .foregroundColor(Color.ccInk.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 14) {
                    // Option 1: Confirmed OK
                    Button(action: {
                        service.resolveAlert(alertId: alert.id, resolution: .confirmedOk)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Confirmed OK")
                                    .font(.familyBodyBold())
                                    .foregroundColor(Color.ccInk)
                                Text("Spoke with parent; they are safe and confirmed doing well.")
                                    .font(.familyCaption())
                                    .foregroundColor(Color.ccInk.opacity(0.6))
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color.ccHearth)
                        }
                        .padding(18)
                        .background(Color.ccLinen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.ccHairline, lineWidth: 1)
                        )
                    }

                    // Option 2: False Alarm
                    Button(action: {
                        service.resolveAlert(alertId: alert.id, resolution: .falseAlarm)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("False Alarm")
                                    .font(.familyBodyBold())
                                    .foregroundColor(Color.ccInk)
                                Text("Parent was busy, traveling, or check-in was delayed.")
                                    .font(.familyCaption())
                                    .foregroundColor(Color.ccInk.opacity(0.6))
                            }
                            Spacer()
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 22))
                                .foregroundColor(Color.ccWaiting)
                        }
                        .padding(18)
                        .background(Color.ccLinen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.ccHairline, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)

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
    }
}
