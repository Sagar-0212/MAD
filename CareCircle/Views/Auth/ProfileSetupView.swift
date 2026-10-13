import SwiftUI

public struct ProfileSetupView: View {
    @Binding public var displayName: String
    @Binding public var selectedRole: MemberRole
    public var onContinue: () -> Void
    public var onBack: () -> Void

    @FocusState private var isNameFocused: Bool

    public init(
        displayName: Binding<String>,
        selectedRole: Binding<MemberRole>,
        onContinue: @escaping () -> Void = {},
        onBack: @escaping () -> Void = {}
    ) {
        self._displayName = displayName
        self._selectedRole = selectedRole
        self.onContinue = onContinue
        self.onBack = onBack
    }

    private var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
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
                        Text("Welcome to CareCircle")
                            .font(.familyHeadingLarge())
                            .foregroundColor(Color.ccInk)

                        Text("How will you be using this device?")
                            .font(.familyBody())
                            .foregroundColor(Color.ccInk.opacity(0.65))
                    }

                    // Role Selection Cards
                    VStack(spacing: 14) {
                        RoleSelectionCard(
                            role: .parent,
                            isSelected: selectedRole == .parent,
                            icon: "heart.fill",
                            title: "Parent Mode",
                            description: "Simple, high-contrast screen with one large daily check-in button and medication reminders."
                        ) {
                            selectedRole = .parent
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }

                        RoleSelectionCard(
                            role: .child,
                            isSelected: selectedRole == .child,
                            icon: "person.2.fill",
                            title: "Family Caregiver",
                            description: "Coordinate with siblings, monitor parents' check-in status, manage health notes, and receive alerts."
                        ) {
                            selectedRole = .child
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                    }

                    // Display Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR NAME")
                            .font(.familyNumeral(size: 11))
                            .foregroundColor(Color.ccInk.opacity(0.45))
                            .tracking(1.2)

                        TextField(selectedRole == .parent ? "e.g. Dad (Arthur)" : "e.g. Alice", text: $displayName)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(Color.ccInk)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.ccLinen.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isNameFocused ? Color.ccHearth : Color.ccHairline, lineWidth: 1.5)
                            )
                            .focused($isNameFocused)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // CTA Button
            VStack(spacing: 12) {
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.ccPaper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(isValid ? Color.ccHearth : Color.ccInk.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!isValid)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .paperBackground()
    }
}

private struct RoleSelectionCard: View {
    let role: MemberRole
    let isSelected: Bool
    let icon: String
    let title: String
    let description: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.ccHearth.opacity(0.15) : Color.ccLinen)
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(isSelected ? Color.ccHearth : Color.ccInk.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(Color.ccInk)

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color.ccHearth)
                        } else {
                            Circle()
                                .stroke(Color.ccHairline, lineWidth: 1.5)
                                .frame(width: 20, height: 20)
                        }
                    }

                    Text(description)
                        .font(.familyBody())
                        .foregroundColor(Color.ccInk.opacity(0.65))
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(18)
            .background(isSelected ? Color.ccLinen.opacity(0.8) : Color.ccLinen.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.ccHearth : Color.ccHairline, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
