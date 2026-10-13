import SwiftUI

public enum AuthStep {
    case welcome
    case emailAuth
    case profile
    case familySetup
    case notification
}

public struct AuthFlowCoordinatorView: View {
    @ObservedObject var service: FirebaseService
    public var onAuthComplete: (MemberRole) -> Void

    @State private var currentStep: AuthStep = .welcome
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var authMode: EmailAuthMode = .signUp
    @State private var displayName: String = ""
    @State private var selectedRole: MemberRole = .child
    @State private var familyName: String = "The Johnsons"
    @State private var inviteCode: String = ""
    @State private var errorMessage: String? = nil
    @State private var isSubmitting: Bool = false

    public init(service: FirebaseService, onAuthComplete: @escaping (MemberRole) -> Void) {
        self.service = service
        self.onAuthComplete = onAuthComplete
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Main Step Views
            Group {
                switch currentStep {
                case .welcome:
                    WelcomeView(
                        onGetStarted: {
                            errorMessage = nil
                            authMode = .signUp
                            withAnimation { currentStep = .emailAuth }
                        },
                        onHaveInviteCode: {
                            errorMessage = nil
                            authMode = .signIn
                            withAnimation { currentStep = .emailAuth }
                        }
                    )
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))

                case .emailAuth:
                    EmailAuthView(
                        email: $email,
                        password: $password,
                        mode: $authMode,
                        onSubmit: {
                            handleEmailAuthSubmit()
                        },
                        onGuestAccess: {
                            handleGuestAuthSubmit()
                        },
                        onBack: {
                            errorMessage = nil
                            withAnimation { currentStep = .welcome }
                        }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

                case .profile:
                    ProfileSetupView(
                        displayName: $displayName,
                        selectedRole: $selectedRole,
                        onContinue: {
                            errorMessage = nil
                            withAnimation { currentStep = .familySetup }
                        },
                        onBack: {
                            errorMessage = nil
                            withAnimation { currentStep = .emailAuth }
                        }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

                case .familySetup:
                    FamilySetupView(
                        familyName: $familyName,
                        inviteCode: $inviteCode,
                        onCreateFamily: {
                            handleCreateFamily()
                        },
                        onJoinFamily: {
                            handleJoinFamily()
                        },
                        onBack: {
                            errorMessage = nil
                            withAnimation { currentStep = .profile }
                        }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

                case .notification:
                    NotificationPermissionView(
                        role: selectedRole,
                        onContinue: {
                            finishFlow()
                        },
                        onSkip: {
                            finishFlow()
                        }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                }
            }

            // Global Error Banner
            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(Color.ccAlert)
                    Text(error)
                        .font(.familyCaption())
                        .foregroundColor(Color.ccInk)
                        .lineLimit(2)
                    Spacer()
                    Button(action: { errorMessage = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.ccInk.opacity(0.5))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.ccPaper)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ccAlert.opacity(0.4), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Loading overlay
            if service.isLoading || isSubmitting {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                ProgressView()
                    .padding(20)
                    .background(Color.ccPaper)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 8)
                    .padding(.top, 200)
            }
        }
    }

    // MARK: - Handlers
    private func handleEmailAuthSubmit() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty, trimmedEmail.contains("@"), password.count >= 6 else {
            errorMessage = "Please enter a valid email address and a password with at least 6 characters."
            return
        }
        errorMessage = nil
        isSubmitting = true
        Task {
            if authMode == .signUp {
                let success = await service.signUp(email: trimmedEmail, password: password)
                isSubmitting = false
                if success {
                    withAnimation { currentStep = .profile }
                } else {
                    errorMessage = service.authError ?? "Failed to create account. Please try again."
                }
            } else {
                let success = await service.signIn(email: trimmedEmail, password: password)
                isSubmitting = false
                if success {
                    if !service.currentFamilyId.isEmpty {
                        let existingRole = service.members.first(where: { $0.userId == service.currentUserId })?.role ?? .child
                        onAuthComplete(existingRole)
                    } else {
                        withAnimation { currentStep = .profile }
                    }
                } else {
                    errorMessage = service.authError ?? "Invalid email or password."
                }
            }
        }
    }

    private func handleGuestAuthSubmit() {
        errorMessage = nil
        service.loadDemoData(role: .child)
        finishFlow()
    }

    private func handleCreateFamily() {
        guard !familyName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a family name."
            return
        }
        errorMessage = nil
        isSubmitting = true
        Task {
            do {
                _ = try await service.createFamily(
                    name: familyName,
                    displayName: displayName.isEmpty ? "Organizer" : displayName,
                    role: selectedRole,
                    email: email
                )
                isSubmitting = false
                withAnimation { currentStep = .notification }
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handleJoinFamily() {
        let code = inviteCode.trimmingCharacters(in: .whitespaces).uppercased()
        guard !code.isEmpty else {
            errorMessage = "Please enter an invite code."
            return
        }
        errorMessage = nil
        isSubmitting = true
        Task {
            do {
                try await service.joinFamily(
                    inviteCode: code,
                    displayName: displayName.isEmpty ? "Family Member" : displayName,
                    role: selectedRole,
                    email: email
                )
                isSubmitting = false
                withAnimation { currentStep = .notification }
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func finishFlow() {
        onAuthComplete(selectedRole)
    }
}
