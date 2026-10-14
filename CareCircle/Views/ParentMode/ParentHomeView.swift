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
    @State private var breathingScale: CGFloat = 1.0
    @State private var ringExpandScale: CGFloat = 1.0
    @State private var ringExpandOpacity: Double = 0.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var circleSizeMetric: CGFloat = 240

    @State private var activeParentId: String = ""

    public init(service: FirebaseService = .shared, parentMemberId: String = "member_parent_arthur") {
        self.service = service
        self.parentMemberId = parentMemberId
    }

    private var parentMembers: [FamilyMember] {
        service.members.filter { $0.role == .parent }
    }

    private var resolvedParentId: String {
        if !activeParentId.isEmpty {
            return activeParentId
        }
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

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        if hour < 12 {
            timeGreeting = "Good morning"
        } else if hour < 17 {
            timeGreeting = "Good afternoon"
        } else {
            timeGreeting = "Good evening"
        }

        if let parentMember = service.members.first(where: { $0.id == resolvedParentId }) {
            let firstName = parentMember.displayName.components(separatedBy: " ").first ?? parentMember.displayName
            return "\(timeGreeting), \(firstName)"
        }
        return timeGreeting
    }

    private var formattedDateString: String {
        CCFormatters.dayMonth.string(from: Date())
    }

    private var clampedCircleSize: CGFloat {
        min(circleSizeMetric, UIScreen.main.bounds.width - 48)
    }

    private var takenMedsCount: Int {
        service.medications.filter { $0.isTakenToday == true }.count
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: CCSpacing.xl) {
                // Top bar: Greeting, Date & Help affordance
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greetingText)
                                .font(.parentHeadline())
                                .foregroundColor(Color.ccInk)

                            Text(formattedDateString)
                                .font(.parentCallout())
                                .foregroundColor(Color.ccTextSecondary)
                        }

                        Spacer()

                        helpButton
                    }

                    VStack(alignment: .leading, spacing: CCSpacing.sm) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greetingText)
                                .font(.parentHeadline())
                                .foregroundColor(Color.ccInk)

                            Text(formattedDateString)
                                .font(.parentCallout())
                                .foregroundColor(Color.ccTextSecondary)
                        }

                        helpButton
                    }
                }
                .padding(.horizontal, CCSpacing.lg)
                .padding(.top, CCSpacing.sm)

                // Multi-parent selector (for demonstrating both parents)
                if parentMembers.count > 1 {
                    HStack(spacing: 8) {
                        ForEach(parentMembers) { parent in
                            let isSelected = (parent.id == resolvedParentId)
                            let isChecked = service.parentCheckins[parent.id]?.status == .ok
                            Button(action: {
                                withAnimation(CCMotion.snappy) {
                                    activeParentId = parent.id
                                }
                                CCHaptics.selection()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(isChecked ? Color.ccHearth : Color.ccTextTertiary)
                                    Text(parent.displayName)
                                        .font(.parentCallout())
                                        .fontWeight(isSelected ? .bold : .medium)
                                }
                                .foregroundColor(isSelected ? Color.ccInk : Color.ccTextSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? Color.ccSurfaceRaised : Color.ccLinen)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(isSelected ? Color.ccHearth : Color.ccHairline, lineWidth: isSelected ? 1.5 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, CCSpacing.lg)
                }

                // Large Primary Check-In Button
                VStack(spacing: CCSpacing.md) {
                    Button(action: {
                        CCHaptics.heavy()
                        service.recordParentCheckin(memberId: resolvedParentId)
                        withAnimation(CCMotion.gentle) {
                            checkinAnimation = true
                            if !reduceMotion {
                                ringExpandScale = 1.3
                                ringExpandOpacity = 0.0
                            }
                        }
                        UIAccessibility.post(notification: .announcement, argument: "Checked in. Your family has been notified.")
                    }) {
                        ZStack {
                            // Breathing outer ring when not checked in
                            if !isCheckedInToday && !reduceMotion {
                                Circle()
                                    .stroke(Color.ccHearth.opacity(0.4), lineWidth: 1.5)
                                    .frame(width: clampedCircleSize + 16, height: clampedCircleSize + 16)
                                    .scaleEffect(breathingScale)
                            }

                            // One-shot expanding ring on checkin tap
                            if !reduceMotion && ringExpandOpacity > 0 {
                                Circle()
                                    .stroke(Color.ccHearth, lineWidth: 2)
                                    .frame(width: clampedCircleSize, height: clampedCircleSize)
                                    .scaleEffect(ringExpandScale)
                                    .opacity(ringExpandOpacity)
                            }

                            // Background soft halo when checked in
                            if isCheckedInToday {
                                Circle()
                                    .fill(Color.ccHearthSoft)
                                    .frame(width: clampedCircleSize + 16, height: clampedCircleSize + 16)
                            }

                            // Main Check-In Circle
                            Circle()
                                .fill(isCheckedInToday ? Color.ccLinen : Color.ccHearth)
                                .frame(width: clampedCircleSize, height: clampedCircleSize)
                                .overlay(
                                    Circle()
                                        .stroke(Color.ccHairline, lineWidth: isCheckedInToday ? 1.5 : 0)
                                )

                            VStack(spacing: 10) {
                                if isCheckedInToday {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(Color.ccInk)
                                        .scaleEffect(checkinAnimation ? 1.0 : 0.8)

                                    Text("You're checked in")
                                        .font(.parentHeadline())
                                        .foregroundColor(Color.ccInk)
                                        .multilineTextAlignment(.center)

                                    if let checkedAt = currentCheckin?.checkedInAt {
                                        Text(CCFormatters.shortTime.string(from: checkedAt))
                                            .font(.parentCallout())
                                            .foregroundColor(Color.ccTextSecondary)
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
                            .foregroundColor(Color.ccTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, CCSpacing.xl)
                    }
                }

                // Divider line (hairline border style)
                Rectangle()
                    .fill(Color.ccHairline)
                    .frame(height: 1)
                    .padding(.horizontal, CCSpacing.lg)

                // Today's Medications List
                VStack(alignment: .leading, spacing: CCSpacing.md) {
                    HStack {
                        Text("Today's Medications")
                            .font(.parentHeadline())
                            .foregroundColor(Color.ccInk)

                        Spacer()

                        if !service.medications.isEmpty {
                            CCStatusChip(
                                text: "\(takenMedsCount) of \(service.medications.count) taken",
                                tone: takenMedsCount == service.medications.count ? .hearth : .neutral,
                                icon: takenMedsCount == service.medications.count ? "checkmark.circle.fill" : nil
                            )
                        }
                    }
                    .padding(.horizontal, CCSpacing.lg)

                    if service.medications.isEmpty {
                        CCEmptyState(
                            icon: "pills",
                            title: "No Medications",
                            message: "No scheduled medications for today."
                        )
                        .padding(.horizontal, CCSpacing.lg)
                    } else {
                        VStack(spacing: CCSpacing.sm) {
                            ForEach(service.medications) { med in
                                MedicationRowView(
                                    medication: med,
                                    onToggle: {
                                        CCHaptics.medium()
                                        service.toggleMedicationTaken(medId: med.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, CCSpacing.lg)

                        if takenMedsCount == service.medications.count {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.ccHearth)
                                Text("All done for today")
                                    .font(.parentCallout())
                                    .foregroundColor(Color.ccTextSecondary)
                            }
                            .padding(.horizontal, CCSpacing.lg)
                            .padding(.top, 2)
                        }
                    }
                }

                Spacer(minLength: 40)
            }
        }
        .paperBackground()
        .onAppear {
            if !reduceMotion {
                withAnimation(Animation.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    breathingScale = 1.06
                }
            }
        }
        .onDisappear {
            breathingScale = 1.0
        }
        .sheet(isPresented: $showingHelpModal) {
            ParentHelpModalView()
        }
    }

    private var helpButton: some View {
        Button(action: {
            CCHaptics.light()
            showingHelpModal = true
        }) {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 15, weight: .semibold))
                Text("Help")
                    .font(.parentCallout())
                    .fontWeight(.semibold)
            }
            .foregroundColor(Color.ccTextSecondary)
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(Color.ccLinen)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.ccHairline, lineWidth: 1))
        }
        .accessibilityLabel("Need Help or Emergency Assistance")
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
        Button(action: {
            withAnimation(CCMotion.snappy) {
                onToggle()
            }
        }) {
            HStack(spacing: CCSpacing.md) {
                // Large Checkbox (at least 48x48pt tap area for accessibility)
                ZStack {
                    RoundedRectangle(cornerRadius: CCRadius.sm, style: .continuous)
                        .fill(isTaken ? Color.ccHearth : Color.ccSurfaceRaised)
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: CCRadius.sm, style: .continuous)
                                .stroke(isTaken ? Color.clear : Color.ccHairline, lineWidth: 1.5)
                        )

                    if isTaken {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color.ccPaper)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.parentBody())
                        .foregroundColor(Color.ccInk)
                        .strikethrough(isTaken, color: Color.ccTextTertiary)
                        .opacity(isTaken ? 0.7 : 1.0)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(Color.ccTextSecondary)
                        Text(medication.scheduledTime)
                            .font(.parentCallout())
                            .foregroundColor(Color.ccTextSecondary)
                    }
                }

                Spacer()
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
            VStack(spacing: CCSpacing.lg) {
                Text("Need Assistance?")
                    .font(.parentHero())
                    .foregroundColor(Color.ccInk)
                    .padding(.top, CCSpacing.lg)

                Text("If this is a medical emergency, please dial 911 immediately.")
                    .font(.parentBody())
                    .foregroundColor(Color.ccAlert)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CCSpacing.lg)

                VStack(spacing: CCSpacing.md) {
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
                        }
                    }
                    .buttonStyle(CCPrimaryButtonStyle(tone: .alert))
                    .frame(height: 64)

                    // Call Family Contact
                    Button(action: {
                        // UX-TODO: wire to a family member's phone
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                            Text("Contact Family")
                        }
                    }
                    .buttonStyle(CCSecondaryButtonStyle())
                    .frame(height: 64)
                }
                .padding(.horizontal, CCSpacing.lg)

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
                    .frame(minWidth: 48, minHeight: 48)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
