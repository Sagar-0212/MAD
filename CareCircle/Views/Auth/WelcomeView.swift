import SwiftUI

public struct WelcomeView: View {
    public var onGetStarted: () -> Void
    public var onHaveInviteCode: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var emblemScale: CGFloat = 0.92

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
            VStack(spacing: CCSpacing.md) {
                ZStack {
                    Circle()
                        .stroke(Color.ccHairline, lineWidth: 1.5)
                        .frame(width: 96, height: 96)

                    Circle()
                        .stroke(Color.ccHearth.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 72, height: 72)

                    Image(systemName: "circle.grid.cross.fill")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(Color.ccHearth)
                }
                .scaleEffect(emblemScale)

                VStack(spacing: CCSpacing.xs) {
                    Text("CareCircle")
                        .font(.familyHeadingLarge())
                        .foregroundColor(Color.ccInk)

                    Text("Private, gentle daily connection\nfor aging parents and families.")
                        .font(.familyBody())
                        .foregroundColor(Color.ccTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.horizontal, CCSpacing.xl)

            Spacer()

            // Value pillars: quiet, private, reliable
            VStack(alignment: .leading, spacing: CCSpacing.md) {
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
            .linenCard()
            .padding(.horizontal, CCSpacing.lg)

            Spacer()

            // Action Buttons
            VStack(spacing: CCSpacing.sm) {
                Button(action: {
                    CCHaptics.light()
                    onGetStarted()
                }) {
                    Text("Get Started")
                }
                .buttonStyle(CCPrimaryButtonStyle(tone: .hearth))

                Button(action: {
                    CCHaptics.light()
                    onHaveInviteCode()
                }) {
                    Text("I already have an account")
                }
                .buttonStyle(CCTextButtonStyle())
            }
            .padding(.horizontal, CCSpacing.lg)
            .padding(.bottom, CCSpacing.lg)
        }
        .paperBackground()
        .onAppear {
            if reduceMotion {
                emblemScale = 1.0
            } else {
                withAnimation(CCMotion.gentle) {
                    emblemScale = 1.0
                }
            }
        }
    }
}

private struct PillarRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: CCSpacing.sm) {
                iconView
                textView
            }

            VStack(alignment: .leading, spacing: CCSpacing.xs) {
                iconView
                textView
            }
        }
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(Color.ccHearthSoft)
                .frame(width: 36, height: 36)
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.ccHearth)
        }
    }

    private var textView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.familyBodyBold())
                .foregroundColor(Color.ccInk)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.familyCaption())
                .foregroundColor(Color.ccTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
