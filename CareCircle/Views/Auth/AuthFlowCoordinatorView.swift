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

    private var stepProgressIndex: Int? {
        switch currentStep {
        case .welcome: return nil
        case .emailAuth: return 1
        case .profile: return 2
        case .familySetup: return 3
        case .notification: return 4
        }
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Main Step Views
            VStack(spacing: 0) {
                if let stepIndex = stepProgressIndex {
                    CCStepProgress(current: stepIndex, total: 4)
                        .padding(.top, CCSpacing.xs)
                        .padding(.horizontal, CCSpacing.lg)
                        .transition(.opacity)
                }

                Group {
                    switch currentStep {
                    case .welcome:
                        WelcomeView(
                            onGetStarted: {
                                errorMessage = nil
                                authMode = .signUp
                                withAnimation(CCMotion.gentle) { currentStep = .emailAuth }
                            },
                            onHaveInviteCode: {
                                errorMessage = nil
                                authMode = .signIn
                                withAnimation(CCMotion.gentle) { currentStep = .emailAuth }
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
                                withAnimation(CCMotion.gentle) { currentStep = .welcome }
                            }
                        )
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

                    case .profile:
                        ProfileSetupView(
                            displayName: $displayName,
                            selectedRole: $selectedRole,
                            onContinue: {
                                errorMessage = nil
                                withAnimation(CCMotion.gentle) { currentStep = .familySetup }
                            },
                            onBack: {
                                errorMessage = nil
                                withAnimation(CCMotion.gentle) { currentStep = .emailAuth }
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
                                withAnimation(CCMotion.gentle) { currentStep = .profile }
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
            }

            // Global Error Banner
            if let error = errorMessage {
                CCBanner(message: error, tone: .alert) {
                    withAnimation(CCMotion.snappy) {
                        errorMessage = nil
                    }
                }
                .padding(.horizontal, CCSpacing.lg)
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                        withAnimation(CCMotion.snappy) {
                            if errorMessage == error {
                                errorMessage = nil
                            }
                        }
                    }
                }
            }

            // Loading overlay
            if service.isLoading || isSubmitting {
                ZStack {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()

                    VStack(spacing: CCSpacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(Color.ccHearth)
                        Text("Just a moment…")
                            .font(.familyBody())
                            .foregroundColor(Color.ccInk)
                    }
                    .padding(.horizontal, CCSpacing.xl)
                    .padding(.vertical, CCSpacing.lg)
                    .background(Color.ccSurfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: CCRadius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: CCRadius.lg, style: .continuous)
                            .stroke(Color.ccHairline, lineWidth: 1)
                    )
                    .accessibilityLabel("Loading")
                }
                .transition(.opacity)
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
