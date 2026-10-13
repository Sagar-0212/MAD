import SwiftUI

// MARK: - Radial Status Circles ("Seats at the Table")
// The signature visual element on the Family Dashboard:
// Represents parents seated around a shared family table.
//
// Circle States:
// - Empty outline: No check-in yet (.none)
// - Filled hearth-color: Checked in today (.ok)
// - Gold: In grace period after missed check-in (.waiting)
// - Red: Confirmed missed past grace window (.missed)

public struct RadialStatusCirclesView: View {
    let parents: [FamilyMember]
    let checkins: [String: DailyCheckin]
    let onSelectParent: (FamilyMember) -> Void

    public init(
        parents: [FamilyMember],
        checkins: [String: DailyCheckin],
        onSelectParent: @escaping (FamilyMember) -> Void
    ) {
        self.parents = parents
        self.checkins = checkins
        self.onSelectParent = onSelectParent
    }

    public var body: some View {
        ZStack {
            // "The Table" — Subtle circular outline representing the hearth/table
            Circle()
                .stroke(Color.ccHairline, lineWidth: 1.5)
                .frame(width: 210, height: 210)

            // Table Center Label
            VStack(spacing: 4) {
                Text("Family Table")
                    .font(.familyHeadingSmall())
                    .foregroundColor(Color.ccTextTertiary)
                
                Text("\(parents.count) \(parents.count == 1 ? "seat" : "seats")")
                    .font(.familyCaption())
                    .foregroundColor(Color.ccTextTertiary)
            }

            // Radial placement of parent seats
            if parents.isEmpty {
                Text("No parents linked yet")
                    .font(.familyCaption())
                    .foregroundColor(Color.ccTextSecondary)
            } else {
                ForEach(Array(parents.enumerated()), id: \.element.id) { index, parent in
                    let angle = angleForIndex(index, total: parents.count)
                    let checkin = checkins[parent.id]
                    let status = checkin?.status ?? .none

                    ParentSeatView(
                        parent: parent,
                        status: status,
                        checkedInAt: checkin?.checkedInAt,
                        action: {
                            onSelectParent(parent)
                        }
                    )
                    .offset(x: offsetForAngle(angle).x, y: offsetForAngle(angle).y)
                    .animation(CCMotion.snappy, value: status)
                }
            }
        }
        .frame(width: 340, height: 340)
        .padding(.vertical, CCSpacing.sm)
    }

    private func angleForIndex(_ index: Int, total: Int) -> Double {
        if total == 1 { return -Double.pi / 2 } // Top
        if total == 2 {
            return index == 0 ? -Double.pi / 2 : Double.pi / 2 // Top & Bottom
        }
        let step = (2 * Double.pi) / Double(total)
        return -Double.pi / 2 + step * Double(index)
    }

    private func offsetForAngle(_ angle: Double) -> CGPoint {
        let radius: CGFloat = 110
        let x = radius * CGFloat(cos(angle))
        let y = radius * CGFloat(sin(angle))
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Individual Parent Seat Circle
struct ParentSeatView: View {
    let parent: FamilyMember
    let status: CheckinStatus
    var checkedInAt: Date? = nil
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotationAngle: Double = 0

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Missed status halo
                    if status == .missed {
                        Circle()
                            .fill(Color.ccAlertSoft)
                            .frame(width: 78, height: 78)
                    }

                    // Rotating dashed ring for grace/waiting state
                    if status == .waiting {
                        Circle()
                            .stroke(
                                Color.ccWaiting,
                                style: StrokeStyle(lineWidth: 2.5, dash: [6, 4])
                            )
                            .frame(width: 76, height: 76)
                            .rotationEffect(.degrees(rotationAngle))
                    }

                    // Base Circle
                    Circle()
                        .fill(circleFillColor)
                        .frame(width: 66, height: 66)
                        .overlay(
                            Group {
                                if status == .none {
                                    Circle()
                                        .stroke(
                                            Color.ccHairline,
                                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                                        )
                                } else {
                                    Circle()
                                        .stroke(Color.ccHairline, lineWidth: 1)
                                }
                            }
                        )

                    // Inner status icon or initial
                    if status == .ok {
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color.ccPaper)
                    } else if status == .waiting {
                        Image(systemName: "hourglass")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(Color.ccInk)
                    } else if status == .missed {
                        Image(systemName: "exclamationmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.ccPaper)
                    } else {
                        // Empty outline: Show parent's first initial
                        Text(String(parent.displayName.prefix(1)))
                            .font(.familyHeadingMedium())
                            .foregroundColor(Color.ccInk)
                    }
                }

                // Member Name
                Text(parent.displayName)
                    .font(.familyCaption())
                    .fontWeight(.medium)
                    .foregroundColor(Color.ccInk)
                    .lineLimit(1)
                    .frame(maxWidth: 84)

                // Compact status label under seat
                seatStatusChip
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(parent.displayName): \(statusDescription)")
        .onAppear {
            if status == .waiting && !reduceMotion {
                withAnimation(Animation.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            }
        }
        .onDisappear {
            rotationAngle = 0
        }
    }

    @ViewBuilder
    private var seatStatusChip: some View {
        switch status {
        case .ok:
            if let time = checkedInAt {
                Text("In \(CCFormatters.shortTime.string(from: time))")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Color.ccHearth)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.ccHearthSoft)
                    .clipShape(Capsule())
            } else {
                Text("Checked in")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Color.ccHearth)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.ccHearthSoft)
                    .clipShape(Capsule())
            }
        case .waiting:
            Text("Grace period")
                .font(.caption2.weight(.semibold))
                .foregroundColor(Color.ccWaiting)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.ccWaitingSoft)
                .clipShape(Capsule())
        case .missed:
            Text("Missed")
                .font(.caption2.weight(.semibold))
                .foregroundColor(Color.ccAlert)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.ccAlertSoft)
                .clipShape(Capsule())
        case .none:
            Text("Not yet")
                .font(.caption2.weight(.medium))
                .foregroundColor(Color.ccTextTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.ccLinen)
                .clipShape(Capsule())
        }
    }

    private var circleFillColor: Color {
        switch status {
        case .ok:
            return Color.ccHearth       // Filled hearth-color (checked in today)
        case .waiting:
            return Color.ccWaiting      // Dusty gold (in grace period)
        case .missed:
            return Color.ccAlert        // Brick red (confirmed missed past grace)
        case .none:
            return Color.ccSurfaceRaised // Dashed outline (no check-in yet)
        }
    }

    private var statusDescription: String {
        switch status {
        case .ok: return "Checked in today"
        case .waiting: return "In grace period after cutoff"
        case .missed: return "Missed check-in alert"
        case .none: return "No check-in yet today"
        }
    }
}
