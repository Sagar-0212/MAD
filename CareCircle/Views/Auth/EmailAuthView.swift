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
                VStack(alignment: .leading, spacing: 24) {
                    // Title & Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mode == .signUp ? "Create your account" : "Welcome back")
                            .font(.familyHeadingLarge())
                            .foregroundColor(Color.ccInk)

                        Text(mode == .signUp
                            ? "Sign up with your email to coordinate care securely on the free plan."
                            : "Enter your email and password to access your family circle.")
                            .font(.familyBody())
                            .foregroundColor(Color.ccInk.opacity(0.65))
                            .lineSpacing(3)
                    }

                    // Mode Toggle (Sign In vs Create Account)
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                mode = .signUp
                            }
                        }) {
                            Text("New Account")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(mode == .signUp ? Color.ccPaper : Color.ccInk)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(mode == .signUp ? Color.ccHearth : Color.clear)
                                .clipShape(Capsule())
                        }

                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                mode = .signIn
                            }
                        }) {
                            Text("Sign In")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(mode == .signIn ? Color.ccPaper : Color.ccInk)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(mode == .signIn ? Color.ccHearth : Color.clear)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(4)
                    .background(Color.ccLinen)
                    .clipShape(Capsule())

                    // Email Input Box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EMAIL ADDRESS")
                            .font(.familyNumeral(size: 11))
                            .foregroundColor(Color.ccInk.opacity(0.45))
                            .tracking(1.2)

                        TextField("name@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(Color.ccInk)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.ccLinen.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(focusedField == .email ? Color.ccHearth : Color.ccHairline, lineWidth: 1.5)
                            )
                            .focused($focusedField, equals: .email)
                    }

                    // Password Input Box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PASSWORD")
                            .font(.familyNumeral(size: 11))
                            .foregroundColor(Color.ccInk.opacity(0.45))
                            .tracking(1.2)

                        SecureField("Minimum 6 characters", text: $password)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(Color.ccInk)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.ccLinen.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(focusedField == .password ? Color.ccHearth : Color.ccHairline, lineWidth: 1.5)
                            )
                            .focused($focusedField, equals: .password)

                        if password.count > 0 && password.count < 6 {
                            Text("Password must be at least 6 characters")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccAlert)
                        }
                    }

                    // Demo Credentials Helper Buttons
                    VStack(alignment: .leading, spacing: 8) {
                        Text("QUICK DEMO CREDENTIALS")
                            .font(.familyNumeral(size: 11))
                            .foregroundColor(Color.ccInk.opacity(0.45))
                            .tracking(1.2)

                        HStack(spacing: 8) {
                            Button(action: {
                                email = "parent@carecircle.demo"
                                password = "password123"
                                mode = .signIn
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 11))
                                    Text("Parent Demo")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(Color.ccInk)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.ccLinen)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.ccHairline, lineWidth: 1))
                            }

                            Button(action: {
                                email = "sarah@carecircle.demo"
                                password = "password123"
                                mode = .signIn
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 11))
                                    Text("Caregiver Demo")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(Color.ccInk)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.ccLinen)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.ccHairline, lineWidth: 1))
                            }
                        }
                    }
                    .padding(.top, 2)

                    // Free Spark Plan reassurance
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color.ccHearth)
                        Text("Free Email Authentication (No SMS fees or billing required)")
                            .font(.familyCaption())
                            .foregroundColor(Color.ccInk.opacity(0.6))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // Submit Button
            VStack(spacing: 12) {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onSubmit()
                }) {
                    Text(mode == .signUp ? "Create Account & Continue" : "Sign In & Continue")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.ccPaper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(isValidInput ? Color.ccHearth : Color.ccInk.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!isValidInput)

                if let onGuestAccess = onGuestAccess {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        onGuestAccess()
                    }) {
                        Text("Continue as Instant Guest / Demo")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color.ccInk.opacity(0.7))
                            .underline()
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .paperBackground()
        .onAppear {
            focusedField = .email
        }
    }
}
