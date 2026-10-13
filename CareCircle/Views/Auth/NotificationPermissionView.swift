import SwiftUI
import UserNotifications

public struct NotificationPermissionView: View {
    public var role: MemberRole
    public var onContinue: () -> Void
    public var onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bellAngle: Double = 0

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
                    .fill(Color.ccHearthSoft)
                    .frame(width: 96, height: 96)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 42))
                    .foregroundColor(Color.ccHearth)
                    .rotationEffect(.degrees(bellAngle))
            }
            .padding(.bottom, CCSpacing.lg)

            // Header
            VStack(spacing: CCSpacing.xs) {
                Text(role == .parent ? "Never miss a day" : "Peace of mind alerts")
                    .font(.familyHeadingLarge())
                    .foregroundColor(Color.ccInk)
                    .multilineTextAlignment(.center)

                Text(role == .parent
                     ? "CareCircle sends a gentle morning chime to remind you to tap 'I'm okay today'."
                     : "If Dad or Mom doesn't check in by the morning cutoff and grace period expires, we send an instant high-priority notification.")
                    .font(.familyBody())
                    .foregroundColor(Color.ccTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, CCSpacing.xl)
            }

            Spacer()

            // Visual Notification preview card
            HStack(alignment: .top, spacing: CCSpacing.sm) {
                // App icon square
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.ccHearth)
                        .frame(width: 38, height: 38)
                    Image(systemName: "circle.grid.cross.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.ccPaper)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("CareCircle")
                            .font(.familyLabel())
                            .fontWeight(.bold)
                            .foregroundColor(Color.ccInk)
                        Text("· now")
                            .font(.caption2)
                            .foregroundColor(Color.ccTextSecondary)
                        Spacer()
                    }

                    Text(role == .parent ? "Morning Check-In" : "Daily Status Alert")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundColor(Color.ccInk)

                    Text(role == .parent
                         ? "Good morning! Time for your daily check-in."
                         : "Grace period expired: Arthur has not checked in today.")
                        .font(.familyCaption())
                        .foregroundColor(Color.ccTextSecondary)
                        .lineLimit(2)
                }
            }
            .padding(CCSpacing.md)
            .background(Color.ccSurfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.lg, style: .continuous)
                    .stroke(Color.ccHairline, lineWidth: 1)
            )
            .padding(.horizontal, CCSpacing.lg)

            Spacer()

            // Actions
            VStack(spacing: CCSpacing.sm) {
                Button(action: {
                    CCHaptics.medium()
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                        DispatchQueue.main.async {
                            onContinue()
                        }
                    }
                }) {
                    Text("Turn on Notifications")
                }
                .buttonStyle(CCPrimaryButtonStyle(tone: .hearth))

                Button(action: {
                    CCHaptics.light()
                    onSkip()
                }) {
                    Text("Maybe later")
                }
                .buttonStyle(CCTextButtonStyle())
            }
            .padding(.horizontal, CCSpacing.lg)
            .padding(.bottom, CCSpacing.lg)
        }
        .paperBackground()
        .onAppear {
            if !reduceMotion {
                withAnimation(Animation.easeInOut(duration: 0.15).repeatCount(4, autoreverses: true)) {
                    bellAngle = 10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(CCMotion.gentle) {
                        bellAngle = 0
                    }
                }
            }
        }
    }
}
