import SwiftUI

public struct FamilySetupView: View {
    @Binding public var familyName: String
    @Binding public var inviteCode: String
    @State private var setupMode: FamilySetupMode = .create
    public var onCreateFamily: () -> Void
    public var onJoinFamily: () -> Void
    public var onBack: () -> Void

    public enum FamilySetupMode {
        case create
        case join
    }

    public init(
        familyName: Binding<String>,
        inviteCode: Binding<String>,
        onCreateFamily: @escaping () -> Void = {},
        onJoinFamily: @escaping () -> Void = {},
        onBack: @escaping () -> Void = {}
    ) {
        self._familyName = familyName
        self._inviteCode = inviteCode
        self.onCreateFamily = onCreateFamily
        self.onJoinFamily = onJoinFamily
        self.onBack = onBack
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Navigation
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(Color.ccInk)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Connect your Family")
                            .font(.familyHeadingLarge())
                            .foregroundColor(Color.ccInk)

                        Text("Create a shared private circle for your household, or join one already set up.")
                            .font(.familyBody())
                            .foregroundColor(Color.ccInk.opacity(0.65))
                            .lineSpacing(3)
                    }

                    // Mode Toggle (Create vs Join)
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                setupMode = .create
                            }
                        }) {
                            Text("Create Circle")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(setupMode == .create ? Color.ccPaper : Color.ccInk)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(setupMode == .create ? Color.ccHearth : Color.clear)
                                .clipShape(Capsule())
                        }

                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                setupMode = .join
                            }
                        }) {
                            Text("Join Circle")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(setupMode == .join ? Color.ccPaper : Color.ccInk)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(setupMode == .join ? Color.ccHearth : Color.clear)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(4)
                    .background(Color.ccLinen)
                    .clipShape(Capsule())

                    // Dynamic Section depending on mode
                    if setupMode == .create {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FAMILY CIRCLE NAME")
                                .font(.familyNumeral(size: 11))
                                .foregroundColor(Color.ccInk.opacity(0.45))
                                .tracking(1.2)

                            TextField("e.g. The Johnsons", text: $familyName)
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(Color.ccInk)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.ccLinen.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.ccHairline, lineWidth: 1)
                                )

                            Text("You can invite parents, siblings, and family members right after.")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccInk.opacity(0.5))
                                .padding(.top, 4)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("6-CHARACTER INVITE CODE")
                                .font(.familyNumeral(size: 11))
                                .foregroundColor(Color.ccInk.opacity(0.45))
                                .tracking(1.2)

                            TextField("e.g. CARE92", text: $inviteCode)
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.ccInk)
                                .textCase(.uppercase)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.ccLinen.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.ccHairline, lineWidth: 1)
                                )

                            Text("Ask your family organizer for the 6-character invite code.")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccInk.opacity(0.5))
                                .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // CTA Button
            VStack(spacing: 12) {
                Button(action: {
                    if setupMode == .create {
                        onCreateFamily()
                    } else {
                        onJoinFamily()
                    }
                }) {
                    Text(setupMode == .create ? "Create Family Circle" : "Join Family Circle")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.ccPaper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.ccHearth)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .paperBackground()
    }
}
