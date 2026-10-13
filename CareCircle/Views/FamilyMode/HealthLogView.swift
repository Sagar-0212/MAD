import SwiftUI

// MARK: - Health Log View
// Screen 2d: Chronological list of photographed prescriptions/reports,
// each tagged with doctor name, visit date, optional follow-up date.
// Add via camera or photo picker. Searchable/filterable by date or tag.

public struct HealthLogView: View {
    @ObservedObject var service: FirebaseService
    @State private var searchText: String = ""
    @State private var showingAddRecordSheet: Bool = false

    public init(service: FirebaseService = .shared) {
        self.service = service
    }

    private var filteredRecords: [HealthRecord] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return service.healthRecords
        }
        return service.healthRecords.filter { record in
            record.doctorName.localizedCaseInsensitiveContains(searchText) ||
            record.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CCSpacing.md) {
                    // Header
                    CCScreenHeader(
                        title: "Health & Prescription Log",
                        subtitle: "Shared prescriptions, doctor visit records, and reports"
                    )
                    .padding(.horizontal, CCSpacing.lg)
                    .padding(.top, CCSpacing.sm)

                    // Search & Filter
                    HStack(spacing: CCSpacing.xs) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.ccTextSecondary)
                        TextField("Filter by doctor name or tag...", text: $searchText)
                            .font(.familyBody())

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.ccTextSecondary)
                                    .frame(width: 24, height: 24)
                            }
                            .accessibilityLabel("Clear search")
                        }
                    }
                    .padding(.horizontal, CCSpacing.md)
                    .padding(.vertical, 12)
                    .background(Color.ccSurfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                            .stroke(Color.ccHairline, lineWidth: 1)
                    )
                    .padding(.horizontal, CCSpacing.lg)

                    // Record Count
                    HStack {
                        Text("\(filteredRecords.count) \(filteredRecords.count == 1 ? "record" : "records")")
                            .font(.familyCaption())
                            .foregroundColor(Color.ccTextSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, CCSpacing.lg)

                    // Records List / Empty State
                    if service.healthRecords.isEmpty {
                        CCEmptyState(
                            icon: "doc.text.fill",
                            title: "No Records Yet",
                            message: "Add prescriptions or visit notes to share health updates with family.",
                            actionTitle: "Add First Record",
                            action: {
                                showingAddRecordSheet = true
                            }
                        )
                        .padding(.horizontal, CCSpacing.lg)
                        .padding(.top, CCSpacing.sm)
                    } else if filteredRecords.isEmpty {
                        CCEmptyState(
                            icon: "doc.text.magnifyingglass",
                            title: "No Matching Records",
                            message: "No health records match '\(searchText)'."
                        )
                        .padding(.horizontal, CCSpacing.lg)
                        .padding(.top, CCSpacing.sm)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredRecords) { record in
                                HealthRecordCard(record: record, service: service)
                            }
                        }
                        .padding(.horizontal, CCSpacing.lg)
                    }

                    // Add Record Button
                    Button(action: {
                        CCHaptics.light()
                        showingAddRecordSheet = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                            Text("Add Prescription / Health Record")
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
                        showingAddRecordSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.ccInk)
                    }
                    .accessibilityLabel("Add Health Record")
                }
            }
            .sheet(isPresented: $showingAddRecordSheet) {
                AddHealthRecordSheet(service: service)
            }
        }
    }
}

// MARK: - Health Record Card
struct HealthRecordCard: View {
    let record: HealthRecord
    let service: FirebaseService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                HStack(spacing: CCSpacing.xs) {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.ccHearth)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.doctorName)
                            .font(.familyBodyBold())
                            .foregroundColor(Color.ccInk)

                        Text("Visit: \(CCFormatters.mediumDate.string(from: record.visitDate))")
                            .font(.familyCaption())
                            .foregroundColor(Color.ccTextSecondary)
                    }
                }

                Spacer()

                if let followUp = record.followUpDate {
                    let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: followUp).day ?? 0
                    let tone: CCStatusTone = (daysUntil >= 0 && daysUntil <= 7) ? .waiting : .hearth
                    CCStatusChip(
                        text: "Follow-up \(CCFormatters.dayMonth.string(from: followUp))",
                        tone: tone,
                        icon: "calendar"
                    )
                }
            }

            // Photo Placeholder / Document Card
            HStack(spacing: CCSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: CCRadius.sm, style: .continuous)
                        .fill(Color.ccSurfaceRaised)
                        .frame(width: 54, height: 54)
                        .overlay(
                            RoundedRectangle(cornerRadius: CCRadius.sm, style: .continuous)
                                .stroke(Color.ccHairline, lineWidth: 1)
                        )

                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 22))
                        .foregroundColor(Color.ccTextSecondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Prescription Document")
                        .font(.familyCaption())
                        .foregroundColor(Color.ccTextSecondary)

                    // Tags
                    FlowLayout(spacing: 6) {
                        ForEach(record.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.familyCaption())
                                .foregroundColor(Color.ccInk)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.ccSurfaceRaised)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Color.ccHairline, lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
        .padding(CCSpacing.md)
        .background(Color.ccLinen)
        .clipShape(RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                .stroke(Color.ccHairline, lineWidth: 1)
        )
    }
}

// MARK: - Add Health Record Sheet
struct AddHealthRecordSheet: View {
    @ObservedObject var service: FirebaseService
    @Environment(\.dismiss) private var dismiss

    @State private var doctorName: String = ""
    @State private var selectedMemberId: String = ""
    @State private var visitDate: Date = Date()
    @State private var hasFollowUp: Bool = false
    @State private var followUpDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var tagInput: String = ""
    @State private var tags: [String] = ["Cardiology", "Prescription"]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("DOCUMENT INFORMATION").font(.familyLabel())) {
                    TextField("Doctor / Clinic Name", text: $doctorName)
                        .font(.familyBody())

                    Picker("Family Member", selection: $selectedMemberId) {
                        Text("Select Member (Default: Organizer)").tag("")
                        ForEach(service.members) { m in
                            Text(m.displayName).tag(m.id)
                        }
                    }
                    .font(.familyBody())

                    DatePicker("Visit Date", selection: $visitDate, displayedComponents: .date)
                        .font(.familyBody())

                    Toggle("Has Follow-up Appointment?", isOn: $hasFollowUp)
                        .font(.familyBody())

                    if hasFollowUp {
                        DatePicker("Follow-up Date", selection: $followUpDate, displayedComponents: .date)
                            .font(.familyBody())
                    }
                }
                .listRowBackground(Color.ccSurfaceRaised)

                Section(header: Text("PHOTO ATTACHMENT").font(.familyLabel())) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundColor(Color.ccTextSecondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Document & photo uploads disabled")
                                .font(.familyBodyBold())
                                .foregroundColor(Color.ccInk)
                            Text("You can still track visit dates, doctor details, follow-ups, and tags.")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccTextSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.ccSurfaceRaised)

                Section(header: Text("TAGS").font(.familyLabel())) {
                    HStack {
                        TextField("Add tag (e.g. Blood Test, Heart)", text: $tagInput)
                            .font(.familyBody())
                        Button("Add") {
                            let trimmed = tagInput.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty && !tags.contains(trimmed) {
                                CCHaptics.light()
                                tags.append(trimmed)
                                tagInput = ""
                            }
                        }
                        .font(.familyBodyBold())
                        .foregroundColor(Color.ccHearth)
                    }

                    if !tags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.familyCaption())
                                        .foregroundColor(Color.ccInk)
                                    Button(action: {
                                        tags.removeAll(where: { $0 == tag })
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(Color.ccTextSecondary)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.ccLinen)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listRowBackground(Color.ccSurfaceRaised)
            }
            .ccFormStyle()
            .navigationTitle("New Health Record")
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
                        guard !doctorName.isEmpty else { return }
                        let memberId = selectedMemberId.isEmpty ? (service.members.first?.id ?? "") : selectedMemberId
                        CCHaptics.success()
                        service.addHealthRecord(
                            familyMemberId: memberId,
                            doctorName: doctorName,
                            visitDate: visitDate,
                            followUpDate: hasFollowUp ? followUpDate : nil,
                            tags: tags,
                            photoUrl: ""
                        )
                        dismiss()
                    }
                    .font(.familyBodyBold())
                    .foregroundColor(Color.ccHearth)
                    .disabled(doctorName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// Simple FlowLayout for Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeightInRow: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width {
                x = 0
                y += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            x += size.width + spacing
            maxHeightInRow = max(maxHeightInRow, size.height)
            height = max(height, y + maxHeightInRow)
        }
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeightInRow: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            maxHeightInRow = max(maxHeightInRow, size.height)
        }
    }
}
