import SwiftUI

public enum EmailAuthMode {
    case signIn
    case signUp
}

public struct EmailAuthView: View {
    @Binding public var email: String
    @Binding public var password: String
    @Binding public var mode: EmailAuthMode
    public var onSubmit: () -> Void
    public var onGuestAccess: (() -> Void)?
    public var onBack: () -> Void

    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    public init(
        email: Binding<String>,
        password: Binding<String>,
        mode: Binding<EmailAuthMode>,
        onSubmit: @escaping () -> Void = {},
        onGuestAccess: (() -> Void)? = nil,
        onBack: @escaping () -> Void = {}
    ) {
        self._email = email
        self._password = password
        self._mode = mode
        self.onSubmit = onSubmit
        self.onGuestAccess = onGuestAccess
        self.onBack = onBack
    }

    private var isValidInput: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        return trimmedEmail.contains("@") && trimmedEmail.contains(".") && password.count >= 6
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack {
                CCBackButton(action: onBack)
                Spacer()
            }
            .padding(.horizontal, CCSpacing.lg)
            .padding(.top, CCSpacing.sm)
            .padding(.bottom, CCSpacing.sm)

            ScrollView {
                VStack(alignment: .leading, spacing: CCSpacing.lg) {
                    // Title & Description
                    VStack(alignment: .leading, spacing: CCSpacing.xs) {
                        Text(mode == .signUp ? "Create your account" : "Welcome back")
                            .font(.familyHeadingLarge())
                            .foregroundColor(Color.ccInk)

                        Text(mode == .signUp
                            ? "Sign up with your email to coordinate care securely on the free plan."
                            : "Enter your email and password to access your family circle.")
                            .font(.familyBody())
                            .foregroundColor(Color.ccTextSecondary)
                            .lineSpacing(3)
                    }

                    // Mode Toggle (Sign In vs Create Account)
                    CCSegmentedToggle(
                        options: [
                            (EmailAuthMode.signUp, "New Account"),
                            (EmailAuthMode.signIn, "Sign In")
                        ],
                        selection: $mode
                    )

                    // Email Input Box
                    CCFieldContainer(
                        label: "Email Address",
                        icon: "envelope",
                        isFocused: focusedField == .email
                    ) {
                        TextField("name@example.com", text: $email)
                            .font(.familyBody())
                            .foregroundColor(Color.ccInk)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textContentType(.username)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .password
                            }
                            .focused($focusedField, equals: .email)
                    }

                    // Password Input Box
                    CCFieldContainer(
                        label: "Password",
                        icon: "lock",
                        isFocused: focusedField == .password,
                        error: password.count > 0 && password.count < 6 ? "Password must be at least 6 characters" : nil
                    ) {
                        CCSecureFieldToggle(
                            placeholder: "Minimum 6 characters",
                            text: $password,
                            textContentType: (mode == .signUp ? .newPassword : .password),
                            submitLabel: .go,
                            onSubmit: {
                                if isValidInput {
                                    onSubmit()
                                }
                            }
                        )
                        .focused($focusedField, equals: .password)
                    }

                    // Demo Credentials Helper Buttons
                    VStack(alignment: .leading, spacing: CCSpacing.xs) {
                        Text("TRY A DEMO ACCOUNT")
                            .font(.familyLabel())
                            .foregroundColor(Color.ccTextSecondary)
                            .tracking(1.0)

                        HStack(spacing: CCSpacing.xs) {
                            Button(action: {
                                CCHaptics.light()
                                email = "parent@carecircle.demo"
                                password = "password123"
                                mode = .signIn
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.fill")
                                        .font(.system(.caption2, design: .rounded, weight: .bold))
                                    Text("Parent Demo")
                                        .font(.familyCaption())
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(Color.ccInk)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.ccSurfaceRaised)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.ccHairline, lineWidth: 1))
                            }

                            Button(action: {
                                CCHaptics.light()
                                email = "sarah@carecircle.demo"
                                password = "password123"
                                mode = .signIn
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(.caption2, design: .rounded, weight: .bold))
                                    Text("Caregiver Demo")
                                        .font(.familyCaption())
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(Color.ccInk)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.ccSurfaceRaised)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.ccHairline, lineWidth: 1))
                            }
                        }
                    }

                    // Shield reassurance
                    HStack(spacing: CCSpacing.xs) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.ccHearth)
                        Text("Free, secure email sign-in, no SMS fees.")
                            .font(.familyCaption())
                            .foregroundColor(Color.ccTextSecondary)
                    }
                    .padding(.top, CCSpacing.xxs)
                }
                .padding(.horizontal, CCSpacing.lg)
                .padding(.vertical, CCSpacing.xs)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: CCSpacing.xs) {
                Button(action: {
                    CCHaptics.medium()
                    onSubmit()
                }) {
                    Text(mode == .signUp ? "Create Account & Continue" : "Sign In & Continue")
                }
                .buttonStyle(CCPrimaryButtonStyle(tone: .hearth))
                .disabled(!isValidInput)

                if let onGuestAccess = onGuestAccess {
                    Button(action: {
                        CCHaptics.light()
                        onGuestAccess()
                    }) {
                        Text("Continue as Instant Guest / Demo")
                    }
                    .buttonStyle(CCTextButtonStyle())
                }
            }
            .padding(.horizontal, CCSpacing.lg)
            .padding(.vertical, CCSpacing.sm)
            .background(Color.ccPaper)
        }
        .paperBackground()
        .onAppear {
            focusedField = .email
        }
    }
}
