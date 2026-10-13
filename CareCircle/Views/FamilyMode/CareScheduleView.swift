import SwiftUI

// MARK: - Care Schedule View
// Screen 2c: Simple weekly grid, assign days to family members.

public struct CareScheduleView: View {
    @ObservedObject var service: FirebaseService
    @State private var showingAddEntrySheet: Bool = false

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

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Weekly Care Schedule")
                            .font(.familyHeadingLarge())
                            .foregroundColor(Color.ccInk)
                        Text("Coordinated check-ins, visits, and family calls")
                            .font(.familyCaption())
                            .foregroundColor(Color.ccInk.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Weekly Grid
                    VStack(spacing: 12) {
                        ForEach(days, id: \.0) { dayNumber, dayName in
                            let entries = service.careSchedule.filter { $0.dayOfWeek == dayNumber }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(dayName)
                                        .font(.familyHeadingSmall())
                                        .foregroundColor(Color.ccInk)

                                    Spacer()

                                    if entries.isEmpty {
                                        Text("Unassigned")
                                            .font(.familyCaption())
                                            .foregroundColor(Color.ccInk.opacity(0.35))
                                    }
                                }

                                if entries.isEmpty {
                                    Text("No planned visit or call scheduled")
                                        .font(.familyCaption())
                                        .foregroundColor(Color.ccInk.opacity(0.45))
                                } else {
                                    ForEach(entries) { entry in
                                        let member = service.members.first(where: { $0.userId == entry.familyMemberId || $0.id == entry.familyMemberId })
                                        let memberName = member?.displayName ?? "Family Member"

                                        HStack(alignment: .top, spacing: 10) {
                                            Circle()
                                                .fill(Color.ccHearth)
                                                .frame(width: 8, height: 8)
                                                .padding(.top, 5)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(memberName)
                                                    .font(.familyBodyBold())
                                                    .foregroundColor(Color.ccInk)
                                                Text(entry.notes)
                                                    .font(.familyBody())
                                                    .foregroundColor(Color.ccInk.opacity(0.75))
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
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

                    // Add Entry Button
                    Button(action: {
                        showingAddEntrySheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Assign Day or Add Note")
                                .font(.familyBodyBold())
                        }
                        .foregroundColor(Color.ccPaper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.ccHearth)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
            .paperBackground()
            .sheet(isPresented: $showingAddEntrySheet) {
                AddScheduleEntrySheet(service: service)
            }
        }
    }
}

// MARK: - Add Schedule Entry Sheet
struct AddScheduleEntrySheet: View {
    @ObservedObject var service: FirebaseService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDay: Int = 2
    @State private var selectedMemberId: String = ""
    @State private var notes: String = ""

    private let dayOptions = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Schedule Assignment").font(.familyCaption())) {
                    Picker("Day of Week", selection: $selectedDay) {
                        ForEach(dayOptions, id: \.0) { num, name in
                            Text(name).tag(num)
                        }
                    }
                    .font(.familyBody())

                    Picker("Family Member", selection: $selectedMemberId) {
                        Text("Select Member").tag("")
                        ForEach(service.members) { m in
                            Text(m.displayName).tag(m.id)
                        }
                    }
                    .font(.familyBody())

                    TextField("Notes (e.g. Bring groceries, call at 2pm)", text: $notes)
                        .font(.familyBody())
                }
            }
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
                        service.addCareScheduleEntry(familyMemberId: memberId, dayOfWeek: selectedDay, notes: notes)
                        dismiss()
                    }
                    .font(.familyBodyBold())
                    .foregroundColor(Color.ccHearth)
                    .disabled(notes.isEmpty)
                }
            }
        }
    }
}
