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
                CCBackButton(action: onBack)
                Spacer()
            }
            .padding(.horizontal, CCSpacing.lg)
            .padding(.top, CCSpacing.sm)
            .padding(.bottom, CCSpacing.sm)

            ScrollView {
                VStack(alignment: .leading, spacing: CCSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: CCSpacing.xs) {
                        Text("Welcome to CareCircle")
                            .font(.familyHeadingLarge())
                            .foregroundColor(Color.ccInk)

                        Text("How will you be using this device?")
                            .font(.familyBody())
                            .foregroundColor(Color.ccTextSecondary)
                    }

                    // Role Selection Cards
                    VStack(spacing: CCSpacing.sm) {
                        RoleSelectionCard(
                            role: .parent,
                            isSelected: selectedRole == .parent,
                            icon: "heart.fill",
                            title: "Parent Mode",
                            description: "Simple, high-contrast screen with one large daily check-in button and medication reminders."
                        ) {
                            withAnimation(CCMotion.snappy) {
                                selectedRole = .parent
                            }
                            CCHaptics.light()
                            isNameFocused = true
                        }

                        RoleSelectionCard(
                            role: .child,
                            isSelected: selectedRole == .child,
                            icon: "person.2.fill",
                            title: "Family Caregiver",
                            description: "Coordinate with siblings, monitor parents' check-in status, manage health notes, and receive alerts."
                        ) {
                            withAnimation(CCMotion.snappy) {
                                selectedRole = .child
                            }
                            CCHaptics.light()
                            isNameFocused = true
                        }
                    }

                    // Display Name Field
                    CCFieldContainer(
                        label: "Your Name",
                        icon: "person",
                        isFocused: isNameFocused
                    ) {
                        TextField(selectedRole == .parent ? "e.g. Dad (Arthur)" : "e.g. Alice", text: $displayName)
                            .font(.familyBody())
                            .foregroundColor(Color.ccInk)
                            .textContentType(.name)
                            .submitLabel(.done)
                            .onSubmit {
                                if isValid {
                                    onContinue()
                                }
                            }
                            .focused($isNameFocused)
                    }
                }
                .padding(.horizontal, CCSpacing.lg)
                .padding(.vertical, CCSpacing.xs)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                CCHaptics.medium()
                onContinue()
            }) {
                Text("Continue")
            }
            .buttonStyle(CCPrimaryButtonStyle(tone: .hearth))
            .disabled(!isValid)
            .padding(.horizontal, CCSpacing.lg)
            .padding(.vertical, CCSpacing.sm)
            .background(Color.ccPaper)
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
            HStack(alignment: .top, spacing: CCSpacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.ccHearthSoft : Color.ccLinen)
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? Color.ccHearth : Color.ccTextSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.familyBodyBold())
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
                        .font(.familyCaption())
                        .foregroundColor(Color.ccTextSecondary)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(CCSpacing.md)
            .background(isSelected ? Color.ccHearthSoft.opacity(0.4) : Color.ccSurfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.lg, style: .continuous)
                    .stroke(isSelected ? Color.ccHearth : Color.ccHairline, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
