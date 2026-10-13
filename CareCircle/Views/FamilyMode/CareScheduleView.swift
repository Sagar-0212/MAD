import SwiftUI

// MARK: - Care Schedule View
// Screen 2c: Simple weekly grid, assign days to family members.

public struct CareScheduleView: View {
    @ObservedObject var service: FirebaseService
    @State private var showingAddEntrySheet: Bool = false
    @State private var preselectedDay: Int = 2

    public init(service: FirebaseService = .shared) {
        self.service = service
    }

    private let days = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]

    private var currentWeekday: Int {
        Calendar.current.component(.weekday, from: Date())
    }

    public var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: CCSpacing.lg) {
                        // Header
                        CCScreenHeader(
                            title: "Weekly Care Schedule",
                            subtitle: "Coordinated check-ins, visits, and family calls"
                        )
                        .padding(.horizontal, CCSpacing.lg)
                        .padding(.top, CCSpacing.sm)

                        // Weekly Grid
                        VStack(spacing: 12) {
                            ForEach(days, id: \.0) { dayNumber, dayName in
                                let entries = service.careSchedule.filter { $0.dayOfWeek == dayNumber }
                                let isToday = dayNumber == currentWeekday

                                if entries.isEmpty {
                                    // Compact unassigned row
                                    Button(action: {
                                        preselectedDay = dayNumber
                                        showingAddEntrySheet = true
                                    }) {
                                        ViewThatFits(in: .horizontal) {
                                            HStack {
                                                if isToday {
                                                    Rectangle()
                                                        .fill(Color.ccHearth)
                                                        .frame(width: 4, height: 28)
                                                        .clipShape(Capsule())
                                                }

                                                Text(dayName)
                                                    .font(.familyBodyBold())
                                                    .foregroundColor(Color.ccInk)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.85)

                                                if isToday {
                                                    CCStatusChip(text: "Today", tone: .hearth, icon: nil)
                                                }

                                                Spacer()

                                                HStack(spacing: 4) {
                                                    Image(systemName: "plus.circle")
                                                        .font(.caption)
                                                    Text("Open")
                                                        .font(.familyCaption())
                                                        .fixedSize(horizontal: true, vertical: false)
                                                }
                                                .foregroundColor(Color.ccTextTertiary)
                                            }

                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack {
                                                    if isToday {
                                                        Rectangle()
                                                            .fill(Color.ccHearth)
                                                            .frame(width: 4, height: 28)
                                                            .clipShape(Capsule())
                                                    }

                                                    Text(dayName)
                                                        .font(.familyBodyBold())
                                                        .foregroundColor(Color.ccInk)
                                                        .lineLimit(1)
                                                        .minimumScaleFactor(0.85)

                                                    if isToday {
                                                        CCStatusChip(text: "Today", tone: .hearth, icon: nil)
                                                    }
                                                }

                                                HStack(spacing: 4) {
                                                    Image(systemName: "plus.circle")
                                                        .font(.caption)
                                                    Text("Open")
                                                        .font(.familyCaption())
                                                        .fixedSize(horizontal: true, vertical: false)
                                                }
                                                .foregroundColor(Color.ccTextTertiary)
                                            }
                                        }
                                        .padding(.horizontal, CCSpacing.md)
                                        .padding(.vertical, 12)
                                        .background(isToday ? Color.ccSurfaceRaised : Color.ccLinen.opacity(0.6))
                                        .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: CCRadius.sm, style: .continuous)
                                                .stroke(isToday ? Color.ccHearth.opacity(0.4) : Color.ccHairline, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .id(dayNumber)
                                } else {
                                    // Assigned day card
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            if isToday {
                                                Rectangle()
                                                    .fill(Color.ccHearth)
                                                    .frame(width: 4, height: 24)
                                                    .clipShape(Capsule())
                                            }

                                            Text(dayName)
                                                .font(.familyBodyBold())
                                                .foregroundColor(Color.ccInk)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.85)

                                            if isToday {
                                                CCStatusChip(text: "Today", tone: .hearth, icon: nil)
                                            }

                                            Spacer()
                                        }

                                        ForEach(entries) { entry in
                                            let member = service.members.first(where: { $0.userId == entry.familyMemberId || $0.id == entry.familyMemberId })
                                            let memberName = member?.displayName ?? "Family Member"

                                            HStack(alignment: .top, spacing: CCSpacing.sm) {
                                                CCAvatar(name: memberName, tone: .hearth, size: 32)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(memberName)
                                                        .font(.familyBodyBold())
                                                        .foregroundColor(Color.ccInk)
                                                    Text(entry.notes)
                                                        .font(.familyBody())
                                                        .foregroundColor(Color.ccTextSecondary)
                                                }
                                                Spacer()
                                            }
                                            .padding(.top, 4)
                                        }
                                    }
                                    .padding(CCSpacing.md)
                                    .background(isToday ? Color.ccSurfaceRaised : Color.ccLinen)
                                    .clipShape(RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                                            .stroke(isToday ? Color.ccHearth.opacity(0.5) : Color.ccHairline, lineWidth: 1)
                                    )
                                    .id(dayNumber)
                                }
                            }
                        }
                        .padding(.horizontal, CCSpacing.lg)

                        // Add Entry Bottom Button
                        Button(action: {
                            preselectedDay = currentWeekday
                            showingAddEntrySheet = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                Text("Assign Day or Add Note")
                            }
                        }
                        .buttonStyle(CCPrimaryButtonStyle(tone: .hearth))
                        .padding(.horizontal, CCSpacing.lg)
                        .padding(.top, CCSpacing.xs)

                        Spacer(minLength: 96)
                    }
                }
                .paperBackground()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            preselectedDay = currentWeekday
                            showingAddEntrySheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.ccInk)
                        }
                        .accessibilityLabel("Add Schedule Entry")
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(CCMotion.gentle) {
                            proxy.scrollTo(currentWeekday, anchor: .center)
                        }
                    }
                }
                .sheet(isPresented: $showingAddEntrySheet) {
                    AddScheduleEntrySheet(service: service, initialDay: preselectedDay)
                }
            }
        }
    }
}

// MARK: - Add Schedule Entry Sheet
struct AddScheduleEntrySheet: View {
    @ObservedObject var service: FirebaseService
    var initialDay: Int = 2
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDay: Int = 2
    @State private var selectedMemberId: String = ""
    @State private var notes: String = ""

    public init(service: FirebaseService, initialDay: Int = 2) {
        self.service = service
        self.initialDay = initialDay
        self._selectedDay = State(initialValue: initialDay)
    }

    private let dayChips = [
        (1, "S", "Sunday"),
        (2, "M", "Monday"),
        (3, "T", "Tuesday"),
        (4, "W", "Wednesday"),
        (5, "T", "Thursday"),
        (6, "F", "Friday"),
        (7, "S", "Saturday")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("DAY OF WEEK").font(.familyLabel())) {
                    HStack(spacing: 8) {
                        ForEach(dayChips, id: \.0) { num, letter, fullName in
                            Button(action: {
                                CCHaptics.selection()
                                selectedDay = num
                            }) {
                                Text(letter)
                                    .font(.familyBodyBold())
                                    .foregroundColor(selectedDay == num ? Color.ccPaper : Color.ccInk)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(selectedDay == num ? Color.ccHearth : Color.ccSurfaceRaised)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.ccHairline, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(fullName)
                            .accessibilityAddTraits(selectedDay == num ? [.isButton, .isSelected] : .isButton)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.ccSurfaceRaised)

                Section(header: Text("ASSIGNED FAMILY MEMBER").font(.familyLabel())) {
                    Picker("Family Member", selection: $selectedMemberId) {
                        Text("Select Member (Default: Organizer)").tag("")
                        ForEach(service.members) { m in
                            Text(m.displayName).tag(m.id)
                        }
                    }
                    .font(.familyBody())
                }
                .listRowBackground(Color.ccSurfaceRaised)

                Section(header: Text("VISIT OR CALL NOTES").font(.familyLabel())) {
                    TextField("Notes (e.g. Bring groceries, call at 2pm)", text: $notes, axis: .vertical)
                        .font(.familyBody())
                        .lineLimit(2...4)
                }
                .listRowBackground(Color.ccSurfaceRaised)
            }
            .ccFormStyle()
            .navigationTitle("Add to Care Schedule")
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
                    Button("Save") {
                        guard !notes.isEmpty else { return }
                        let memberId = selectedMemberId.isEmpty ? (service.members.first?.id ?? "") : selectedMemberId
                        CCHaptics.success()
                        service.addCareScheduleEntry(familyMemberId: memberId, dayOfWeek: selectedDay, notes: notes)
                        dismiss()
                    }
                    .font(.familyBodyBold())
                    .foregroundColor(Color.ccHearth)
                    .disabled(notes.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
