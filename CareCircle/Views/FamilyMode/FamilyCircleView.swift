import SwiftUI

// MARK: - Family Circle View
// Screen 2b: List of members, roles (parent/child), invite by phone number.

public struct FamilyCircleView: View {
    @ObservedObject var service: FirebaseService
    @State private var showingInviteSheet: Bool = false
    @State private var isCopied: Bool = false

    public init(service: FirebaseService = .shared) {
        self.service = service
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CCSpacing.lg) {
                    // Header
                    CCScreenHeader(
                        title: service.currentFamily.name,
                        subtitle: "Private family coordination circle"
                    )
                    .padding(.horizontal, CCSpacing.lg)
                    .padding(.top, CCSpacing.sm)

                    // Invite Code Card
                    if let code = service.currentFamily.inviteCode, !code.isEmpty {
                        VStack(alignment: .leading, spacing: CCSpacing.sm) {
                            Text("CIRCLE INVITE CODE")
                                .font(.familyLabel())
                                .foregroundColor(Color.ccTextSecondary)
                                .tracking(1.0)

                            HStack {
                                Text(code)
                                    .font(.system(.title2, design: .monospaced, weight: .bold))
                                    .foregroundColor(Color.ccHearth)
                                    .tracking(2.0)

                                Spacer()

                                HStack(spacing: 8) {
                                    // Copy Button
                                    Button(action: {
                                        UIPasteboard.general.string = code
                                        CCHaptics.success()
                                        UIAccessibility.post(notification: .announcement, argument: "Invite code copied to clipboard.")
                                        isCopied = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            isCopied = false
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                            Text(isCopied ? "Copied ✓" : "Copy")
                                        }
                                        .font(.familyCaption())
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.ccInk)
                                        .padding(.horizontal, 12)
                                        .frame(height: 36)
                                        .background(Color.ccPaper)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.ccHairline, lineWidth: 1))
                                    }

                                    // Share Link
                                    ShareLink(
                                        item: "Join our CareCircle family circle with invite code: \(code)",
                                        subject: Text("Join our CareCircle"),
                                        message: Text("Join our CareCircle family circle with invite code: \(code)")
                                    ) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Share")
                                        }
                                        .font(.familyCaption())
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.ccInk)
                                        .padding(.horizontal, 12)
                                        .frame(height: 36)
                                        .background(Color.ccPaper)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.ccHairline, lineWidth: 1))
                                    }
                                }
                            }
                        }
                        .padding(CCSpacing.md)
                        .background(Color.ccSurfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: CCRadius.lg, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: CCRadius.lg, style: .continuous)
                                .stroke(Color.ccHairline, lineWidth: 1)
                        )
                        .padding(.horizontal, CCSpacing.lg)
                    }

                    // Members List
                    VStack(alignment: .leading, spacing: CCSpacing.sm) {
                        CCSectionHeader(title: "Circle Members (\(service.members.count))")
                            .padding(.horizontal, CCSpacing.lg)

                        VStack(spacing: 10) {
                            ForEach(service.members) { member in
                                let isCurrentUser = member.userId == service.currentUserId
                                HStack(spacing: CCSpacing.md) {
                                    CCAvatar(
                                        name: member.displayName,
                                        tone: member.role == .parent ? .hearth : .neutral,
                                        size: 48
                                    )

                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(member.displayName)
                                                .font(.familyBodyBold())
                                                .foregroundColor(Color.ccInk)

                                            if isCurrentUser {
                                                Text("You")
                                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                                    .foregroundColor(Color.ccHearth)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.ccHearthSoft)
                                                    .clipShape(Capsule())
                                            }
                                        }

                                        Text(member.email ?? member.phoneNumber)
                                            .font(.familyCaption())
                                            .foregroundColor(Color.ccTextSecondary)
                                    }

                                    Spacer()

                                    CCStatusChip(
                                        text: member.role == .parent ? "Parent" : "Caregiver",
                                        tone: member.role == .parent ? .hearth : .neutral,
                                        icon: member.role == .parent ? "heart.fill" : "person.fill"
                                    )
                                }
                                .padding(.horizontal, CCSpacing.md)
                                .padding(.vertical, 14)
                                .background(Color.ccLinen)
                                .clipShape(RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                                        .stroke(Color.ccHairline, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, CCSpacing.lg)
                    }

                    // Invite Button
                    Button(action: {
                        CCHaptics.light()
                        showingInviteSheet = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.badge.shield.half.filled")
                                .font(.system(size: 18))
                            Text("Invite Member by Email")
                        }
                    }
                    .buttonStyle(CCPrimaryButtonStyle(tone: .ink))
                    .padding(.horizontal, CCSpacing.lg)
                    .padding(.top, CCSpacing.xs)

                    Spacer(minLength: 96)
                }
            }
            .paperBackground()
            .sheet(isPresented: $showingInviteSheet) {
                InviteMemberSheet(service: service)
            }
        }
    }
}

// MARK: - Invite Member Sheet
struct InviteMemberSheet: View {
    @ObservedObject var service: FirebaseService
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var selectedRole: MemberRole = .parent

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Member Details").font(.familyCaption())) {
                    TextField("Full Name (e.g. Grandma Rose)", text: $name)
                        .font(.familyBody())
                        .textContentType(.name)

                    TextField("Email Address (e.g. rose@example.com)", text: $email)
                        .font(.familyBody())
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textContentType(.emailAddress)

                    Picker("Role", selection: $selectedRole) {
                        Text("Parent").tag(MemberRole.parent)
                        Text("Caregiver").tag(MemberRole.child)
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color.ccSurfaceRaised)
            }
            .ccFormStyle()
            .navigationTitle("Invite to Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.familyBody())
                    .foregroundColor(Color.ccInk)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send Invite") {
                        guard !name.isEmpty, !email.isEmpty else { return }
                        CCHaptics.success()
                        service.inviteMember(displayName: name, email: email, role: selectedRole)
                        dismiss()
                    }
                    .font(.familyBodyBold())
                    .foregroundColor(Color.ccHearth)
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
