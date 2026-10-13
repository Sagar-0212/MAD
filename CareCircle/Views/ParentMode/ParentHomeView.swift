import SwiftUI

// MARK: - Parent Mode Home View
// Hard requirements:
// 1. Radically simple, warm, calm, high-contrast.
// 2. One large circular primary button: "I'm okay today." (or "Checked in" state once tapped).
// 3. Below: today's medications as a simple list, each with a large tap target checkbox.
// 4. Small, low-contrast "Help" affordance in a corner.
// 5. System SF Pro Rounded only, full Dynamic Type support at the largest accessibility sizes.
// 6. Zero gradients, zero glassmorphism, zero shadows.

public struct ParentHomeView: View {
    @ObservedObject var service: FirebaseService
    let parentMemberId: String

    @State private var showingHelpModal: Bool = false
    @State private var checkinAnimation: Bool = false

    public init(service: FirebaseService = .shared, parentMemberId: String = "member_parent_arthur") {
        self.service = service
        self.parentMemberId = parentMemberId
    }

    private var resolvedParentId: String {
        if !parentMemberId.isEmpty && parentMemberId != "member_parent_arthur" {
            return parentMemberId
        }
        if let currentParent = service.members.first(where: { $0.userId == service.currentUserId && $0.role == .parent }) {
            return currentParent.id
        }
        if let firstParent = service.members.first(where: { $0.role == .parent }) {
            return firstParent.id
        }
        return service.currentUserId.isEmpty ? "member_parent_arthur" : service.currentUserId
    }

    private var currentCheckin: DailyCheckin? {
        service.parentCheckins[resolvedParentId]
    }

    private var isCheckedInToday: Bool {
        currentCheckin?.status == .ok
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                // Top bar: small low-contrast Help affordance in corner only
                HStack {
                    Spacer()
                    Button(action: {
                        showingHelpModal = true
                    }) {
                        Text("Help")
                            .font(.parentCallout())
                            .foregroundColor(Color.ccInk.opacity(0.40))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.ccLinen.opacity(0.6))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("Need Help or Emergency Assistance")
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                // Large Primary Check-In Button
                VStack(spacing: 16) {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.impactOccurred()
                        service.recordParentCheckin(memberId: resolvedParentId)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            checkinAnimation = true
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(isCheckedInToday ? Color.ccLinen : Color.ccHearth)
                                .frame(width: 240, height: 240)
                                .overlay(
                                    Circle()
                                        .stroke(Color.ccInk.opacity(0.15), lineWidth: isCheckedInToday ? 2 : 0)
                                )

                            VStack(spacing: 10) {
                                if isCheckedInToday {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 44, weight: .bold, design: .rounded))
                                        .foregroundColor(Color.ccInk)

                                    Text("You're checked in")
                                        .font(.parentHeadline())
                                        .foregroundColor(Color.ccInk)
                                        .multilineTextAlignment(.center)

                                    if let checkedAt = currentCheckin?.checkedInAt {
                                        Text(timeString(from: checkedAt))
                                            .font(.parentCallout())
                                            .foregroundColor(Color.ccInk.opacity(0.6))
                                    }
                                } else {
                                    Text("I'm okay\ntoday.")
                                        .font(.parentButton())
                                        .foregroundColor(Color.ccPaper)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(4)
                                }
                            }
                            .padding(20)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isCheckedInToday ? "You have already checked in today" : "I'm okay today. Tap to check in.")
                    .accessibilityHint(isCheckedInToday ? "Tap to reconfirm your status" : "Notifies your family that you are doing well today")

                    if !isCheckedInToday {
                        Text("Tap circle once to let family know you are okay")
                            .font(.parentCallout())
                            .foregroundColor(Color.ccInk.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                // Divider line (hairline border style)
                Rectangle()
                    .fill(Color.ccHairline)
                    .frame(height: 1)
                    .padding(.horizontal, 24)

                // Today's Medications List
                VStack(alignment: .leading, spacing: 18) {
                    Text("Today's Medications")
                        .font(.parentHeadline())
                        .foregroundColor(Color.ccInk)
                        .padding(.horizontal, 24)

                    if service.medications.isEmpty {
                        Text("No scheduled medications today")
                            .font(.parentBody())
                            .foregroundColor(Color.ccInk.opacity(0.6))
                            .padding(.horizontal, 24)
                    } else {
                        VStack(spacing: 14) {
                            ForEach(service.medications) { med in
                                MedicationRowView(
                                    medication: med,
                                    onToggle: {
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                        service.toggleMedicationTaken(medId: med.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                Spacer(minLength: 40)
            }
        }
        .paperBackground()
        .sheet(isPresented: $showingHelpModal) {
            ParentHelpModalView()
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Large Tap-Target Medication Row
struct MedicationRowView: View {
    let medication: Medication
    let onToggle: () -> Void

    private var isTaken: Bool {
        medication.isTakenToday ?? false
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 18) {
                // Large Checkbox (at least 48x48pt tap area for accessibility)
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isTaken ? Color.ccHearth : Color.ccPaper)
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isTaken ? Color.clear : Color.ccInk.opacity(0.3), lineWidth: 2)
                        )

                    if isTaken {
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color.ccPaper)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.parentBody())
                        .foregroundColor(Color.ccInk)
                        .strikethrough(isTaken, color: Color.ccInk.opacity(0.4))

                    Text(medication.scheduledTime)
                        .font(.parentCallout())
                        .foregroundColor(Color.ccInk.opacity(0.6))
                }

                Spacer()
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
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(medication.name), scheduled for \(medication.scheduledTime)")
        .accessibilityValue(isTaken ? "Taken" : "Not yet taken")
        .accessibilityHint("Double tap to toggle medication status")
    }
}

// MARK: - Parent Help Modal
struct ParentHelpModalView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Need Assistance?")
                    .font(.parentHero())
                    .foregroundColor(Color.ccInk)
                    .padding(.top, 24)

                Text("If this is a medical emergency, please dial 911 immediately.")
                    .font(.parentBody())
                    .foregroundColor(Color.ccAlert)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(spacing: 16) {
                    // Call Emergency Services
                    Button(action: {
                        if let url = URL(string: "tel://911"), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Text("Call 911 (Emergency)")
                                .font(.parentHeadline())
                        }
                        .foregroundColor(Color.ccPaper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color.ccAlert)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Call Family Contact
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                            Text("Contact Family")
                                .font(.parentHeadline())
                        }
                        .foregroundColor(Color.ccInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color.ccLinen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.ccHairline, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .paperBackground()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.parentBody())
                    .foregroundColor(Color.ccInk)
                }
            }
        }
    }
}
