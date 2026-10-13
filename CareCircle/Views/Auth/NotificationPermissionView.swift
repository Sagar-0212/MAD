import SwiftUI
import UserNotifications

public struct NotificationPermissionView: View {
    public var role: MemberRole
    public var onContinue: () -> Void
    public var onSkip: () -> Void

    public init(
        role: MemberRole = .child,
        onContinue: @escaping () -> Void = {},
        onSkip: @escaping () -> Void = {}
    ) {
        self.role = role
        self.onContinue = onContinue
        self.onSkip = onSkip
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon graphic
            ZStack {
                Circle()
                    .fill(Color.ccHearth.opacity(0.12))
                    .frame(width: 100, height: 100)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 42))
                    .foregroundColor(Color.ccHearth)
            }
            .padding(.bottom, 24)

            // Header
            VStack(spacing: 10) {
                Text(role == .parent ? "Never miss a day" : "Peace of mind alerts")
                    .font(.familyHeadingLarge())
                    .foregroundColor(Color.ccInk)
                    .multilineTextAlignment(.center)

                Text(role == .parent
                     ? "CareCircle sends a gentle morning chime to remind you to tap 'I'm okay today'."
                     : "If Dad or Mom doesn't check in by the morning cutoff and grace period expires, we send an instant high-priority notification.")
                    .font(.familyBody())
                    .foregroundColor(Color.ccInk.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Visual Notification preview pill
            HStack(spacing: 14) {
                Image(systemName: "circle.grid.cross.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.ccHearth)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CareCircle")
                        .font(.familyNumeral(size: 11))
                        .foregroundColor(Color.ccInk.opacity(0.5))

                    Text(role == .parent ? "Good morning! Time for your daily check-in." : "Alert: Dad has not checked in today.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.ccInk)
                }
                Spacer()
            }
            .padding(16)
            .background(Color.ccPaper)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.ccHairline, lineWidth: 1)
            )
            .padding(.horizontal, 28)

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button(action: {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                        DispatchQueue.main.async {
                            onContinue()
                        }
                    }
                }) {
                    Text("Turn on Notifications")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.ccPaper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.ccHearth)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button(action: onSkip) {
                    Text("Maybe later")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color.ccInk.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .paperBackground()
    }
}
