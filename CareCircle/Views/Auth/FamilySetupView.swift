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

    @FocusState private var isFieldFocused: Bool

    private var trimmedName: String {
        familyName.trimmingCharacters(in: .whitespaces)
    }

    private var trimmedCode: String {
        inviteCode.trimmingCharacters(in: .whitespaces)
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
                        Text("Connect your Family")
                            .font(.familyHeadingLarge())
                            .foregroundColor(Color.ccInk)

                        Text("Create a shared private circle for your household, or join one already set up.")
                            .font(.familyBody())
                            .foregroundColor(Color.ccTextSecondary)
                            .lineSpacing(3)
                    }

                    // Mode Toggle (Create vs Join)
                    CCSegmentedToggle(
                        options: [
                            (FamilySetupMode.create, "Create Circle"),
                            (FamilySetupMode.join, "Join Circle")
                        ],
                        selection: $setupMode
                    )

                    // Dynamic Section depending on mode
                    if setupMode == .create {
                        VStack(alignment: .leading, spacing: CCSpacing.xs) {
                            CCFieldContainer(
                                label: "Family Circle Name",
                                icon: "person.3",
                                isFocused: isFieldFocused
                            ) {
                                TextField("e.g. The Johnsons", text: $familyName)
                                    .font(.familyBody())
                                    .foregroundColor(Color.ccInk)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        if !trimmedName.isEmpty {
                                            onCreateFamily()
                                        }
                                    }
                                    .focused($isFieldFocused)
                            }

                            Text("You can invite parents, siblings, and family members right after.")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccTextSecondary)
                                .padding(.horizontal, CCSpacing.xs)
                        }
                        .transition(.opacity)
                    } else {
                        VStack(alignment: .leading, spacing: CCSpacing.xs) {
                            CCFieldContainer(
                                label: "6-Character Invite Code",
                                icon: "key",
                                isFocused: isFieldFocused
                            ) {
                                HStack {
                                    TextField("CARE92", text: $inviteCode)
                                        .font(.system(.title3, design: .monospaced, weight: .bold))
                                        .foregroundColor(Color.ccInk)
                                        .tracking(2.0)
                                        .textInputAutocapitalization(.characters)
                                        .autocorrectionDisabled(true)
                                        .submitLabel(.go)
                                        .onSubmit {
                                            if !trimmedCode.isEmpty {
                                                onJoinFamily()
                                            }
                                        }
                                        .focused($isFieldFocused)
                                        .onChange(of: inviteCode) { newValue in
                                            if newValue.count > 6 {
                                                inviteCode = String(newValue.prefix(6))
                                            }
                                        }

                                    Text("\(min(inviteCode.count, 6))/6")
                                        .font(.familyLabel())
                                        .foregroundColor(Color.ccTextSecondary)
                                }
                            }

                            Text("Ask your family organizer for the 6-character invite code.")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccTextSecondary)
                                .padding(.horizontal, CCSpacing.xs)
                        }
                        .transition(.opacity)
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
                if setupMode == .create {
                    onCreateFamily()
                } else {
                    onJoinFamily()
                }
            }) {
                Text(setupMode == .create ? "Create Family Circle" : "Join Family Circle")
            }
            .buttonStyle(CCPrimaryButtonStyle(tone: .hearth))
            .disabled(setupMode == .create ? trimmedName.isEmpty : trimmedCode.isEmpty)
            .padding(.horizontal, CCSpacing.lg)
            .padding(.vertical, CCSpacing.sm)
            .background(Color.ccPaper)
        }
        .paperBackground()
    }
}
