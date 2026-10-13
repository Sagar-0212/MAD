import SwiftUI

public struct WelcomeView: View {
    public var onGetStarted: () -> Void
    public var onHaveInviteCode: () -> Void

    public init(
        onGetStarted: @escaping () -> Void = {},
        onHaveInviteCode: @escaping () -> Void = {}
    ) {
        self.onGetStarted = onGetStarted
        self.onHaveInviteCode = onHaveInviteCode
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Brand Mark & Emblem
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.ccHairline, lineWidth: 1.5)
                        .frame(width: 88, height: 88)

                    Circle()
                        .stroke(Color.ccHearth.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 64, height: 64)

                    Image(systemName: "circle.grid.cross.fill")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(Color.ccHearth)
                }

                VStack(spacing: 8) {
                    Text("CareCircle")
                        .font(.familyHeadingLarge())
                        .foregroundColor(Color.ccInk)

                    Text("Private, gentle daily connection\nfor aging parents and families.")
                        .font(.familyBody())
                        .foregroundColor(Color.ccInk.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Value pillars: quiet, private, reliable
            VStack(alignment: .leading, spacing: 18) {
                PillarRow(
                    icon: "checkmark.circle",
                    title: "One-tap daily check-in",
                    subtitle: "Zero confusion for parents. One clear button each morning."
                )
                PillarRow(
                    icon: "bell.badge",
                    title: "Quiet grace period",
                    subtitle: "Subtle 90-minute window before alerting family members."
                )
                PillarRow(
                    icon: "lock.shield",
                    title: "Private & family-only",
                    subtitle: "No social feeds or spam. Strictly your family circle."
                )
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(Color.ccLinen.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.ccHairline, lineWidth: 1)
            )
            .padding(.horizontal, 24)

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                Button(action: onGetStarted) {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.ccPaper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.ccHearth)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button(action: onHaveInviteCode) {
                    Text("I have an invite code")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color.ccInk.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .paperBackground()
    }
}

private struct PillarRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.ccHearth)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.familyBodyBold())
                    .foregroundColor(Color.ccInk)
                Text(subtitle)
                    .font(.familyCaption())
                    .foregroundColor(Color.ccInk.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
