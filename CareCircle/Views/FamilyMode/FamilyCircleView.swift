import SwiftUI

// MARK: - Family Circle View
// Screen 2b: List of members, roles (parent/child), invite by phone number.

public struct FamilyCircleView: View {
    @ObservedObject var service: FirebaseService
    @State private var showingInviteSheet: Bool = false

    public init(service: FirebaseService = .shared) {
        self.service = service
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 6) {
                        Text(service.currentFamily.name)
                            .font(.familyHeadingLarge())
                            .foregroundColor(Color.ccInk)
                        Text("Private family coordination circle")
                            .font(.familyCaption())
                            .foregroundColor(Color.ccInk.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Invite Code Card
                    if let code = service.currentFamily.inviteCode, !code.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("CIRCLE INVITE CODE")
                                    .font(.familyNumeral(size: 11))
                                    .foregroundColor(Color.ccInk.opacity(0.45))
                                    .tracking(1.2)
                                Text(code)
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.ccHearth)
                            }
                            Spacer()
                            Button(action: {
                                UIPasteboard.general.string = code
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                                .font(.familyCaption())
                                .foregroundColor(Color.ccInk)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.ccPaper)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.ccHairline, lineWidth: 1))
                            }
                        }
                        .padding(14)
                        .background(Color.ccLinen.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ccHairline, lineWidth: 1))
                        .padding(.horizontal, 24)
                    }

                    // Members List
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Circle Members (\(service.members.count))")
                                .font(.familyHeadingMedium())
                                .foregroundColor(Color.ccInk)
                            Spacer()
                        }
                        .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            ForEach(service.members) { member in
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(member.role == .parent ? Color.ccHearth.opacity(0.15) : Color.ccLinen)
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(String(member.displayName.prefix(1)))
                                                .font(.familyHeadingMedium())
                                                .foregroundColor(member.role == .parent ? Color.ccHearth : Color.ccInk)
                                        )

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(member.displayName)
                                            .font(.familyBodyBold())
                                            .foregroundColor(Color.ccInk)

                                        Text(member.email ?? member.phoneNumber)
                                            .font(.familyNumeral(size: 13))
                                            .foregroundColor(Color.ccInk.opacity(0.55))
                                    }

                                    Spacer()

                                    Text(member.role == .parent ? "Parent" : "Child")
                                        .font(.familyCaption())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(member.role == .parent ? Color.ccHearth.opacity(0.12) : Color.ccInk.opacity(0.06))
                                        .foregroundColor(member.role == .parent ? Color.ccHearth : Color.ccInk)
                                        .clipShape(Capsule())
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.ccLinen)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.ccHairline, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Invite Affordance
                    Button(action: {
                        showingInviteSheet = true
                    }) {
                        HStack {
                            Image(systemName: "envelope.badge.shield.half.filled")
                                .font(.system(size: 18))
                            Text("Invite Member by Email")
                                .font(.familyBodyBold())
                        }
                        .foregroundColor(Color.ccPaper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.ccInk)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    Spacer(minLength: 40)
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

                    TextField("Email Address (e.g. rose@example.com)", text: $email)
                        .font(.familyBody())
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    Picker("Role", selection: $selectedRole) {
                        Text("Parent").tag(MemberRole.parent)
                        Text("Child / Caregiver").tag(MemberRole.child)
                    }
                    .font(.familyBody())
                }
            }
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
                        service.inviteMember(displayName: name, email: email, role: selectedRole)
                        dismiss()
                    }
                    .font(.familyBodyBold())
                    .foregroundColor(Color.ccHearth)
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
    }
}
