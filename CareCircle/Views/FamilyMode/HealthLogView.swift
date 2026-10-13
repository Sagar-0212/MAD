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
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Health & Prescription Log")
                            .font(.familyHeadingLarge())
                            .foregroundColor(Color.ccInk)
                        Text("Shared prescriptions, doctor visit records, and reports")
                            .font(.familyCaption())
                            .foregroundColor(Color.ccInk.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Search & Filter
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.ccInk.opacity(0.4))
                        TextField("Filter by doctor name or tag...", text: $searchText)
                            .font(.familyBody())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.ccLinen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.ccHairline, lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    // Chronological Records List
                    if filteredRecords.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 36))
                                .foregroundColor(Color.ccInk.opacity(0.3))
                                .padding(.top, 24)
                            Text("No health records match your filter")
                                .font(.familyBody())
                                .foregroundColor(Color.ccInk.opacity(0.5))
                        }
                    } else {
                        VStack(spacing: 14) {
                            ForEach(filteredRecords) { record in
                                HealthRecordCard(record: record, service: service)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Add Record Button
                    Button(action: {
                        showingAddRecordSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Prescription / Health Record")
                                .font(.familyBodyBold())
                        }
                        .foregroundColor(Color.ccPaper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.ccInk)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
            .paperBackground()
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.doctorName)
                        .font(.familyBodyBold())
                        .foregroundColor(Color.ccInk)

                    Text("Visit: \(formattedDate(record.visitDate))")
                        .font(.familyNumeral(size: 13))
                        .foregroundColor(Color.ccInk.opacity(0.6))
                }

                Spacer()

                if let followUp = record.followUpDate {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Follow-up")
                            .font(.familyCaption())
                            .foregroundColor(Color.ccHearth)
                        Text(formattedDate(followUp))
                            .font(.familyNumeral(size: 12))
                            .foregroundColor(Color.ccInk.opacity(0.7))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.ccHearth.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // Photo Placeholder / Display Card
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.ccPaper)
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.ccHairline, lineWidth: 1)
                        )

                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 24))
                        .foregroundColor(Color.ccInk.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Prescription Document")
                        .font(.familyCaption())
                        .foregroundColor(Color.ccInk.opacity(0.7))

                    // Tags
                    FlowLayout(spacing: 6) {
                        ForEach(record.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.familyCaption())
                                .foregroundColor(Color.ccInk)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.ccPaper)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Color.ccHairline, lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.ccLinen)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.ccHairline, lineWidth: 1)
        )
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
                Section(header: Text("Document Information").font(.familyCaption())) {
                    TextField("Doctor / Clinic Name", text: $doctorName)
                        .font(.familyBody())

                    Picker("Family Member", selection: $selectedMemberId) {
                        Text("Select Member").tag("")
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

                Section(header: Text("Photo Attachment").font(.familyCaption())) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 20))
                            .foregroundColor(Color.ccInk.opacity(0.45))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Photo attachment temporarily unavailable")
                                .font(.familyBodyBold())
                                .foregroundColor(Color.ccInk)
                            Text("Document and photo uploads are currently disabled. You can still track visit dates, doctor details, follow-ups, and tags.")
                                .font(.familyCaption())
                                .foregroundColor(Color.ccInk.opacity(0.6))
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Tags").font(.familyCaption())) {
                    HStack {
                        TextField("Add tag (e.g. Blood Test, Heart)", text: $tagInput)
                            .font(.familyBody())
                        Button("Add") {
                            if !tagInput.isEmpty {
                                tags.append(tagInput)
                                tagInput = ""
                            }
                        }
                        .font(.familyBodyBold())
                        .foregroundColor(Color.ccHearth)
                    }

                    ForEach(tags, id: \.self) { tag in
                        Text(tag).font(.familyCaption())
                    }
                }
            }
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
