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

            // Table Center Label: Calm, subtle family marker
            VStack(spacing: 4) {
                Text("Family Table")
                    .font(.familyHeadingSmall())
                    .foregroundColor(Color.ccInk.opacity(0.40))
                
                Text("\(parents.count) \(parents.count == 1 ? "seat" : "seats")")
                    .font(.familyCaption())
                    .foregroundColor(Color.ccInk.opacity(0.35))
            }

            // Radial placement of parent seats
            if parents.isEmpty {
                Text("No parents linked yet")
                    .font(.familyCaption())
                    .foregroundColor(Color.ccInk.opacity(0.5))
            } else {
                ForEach(Array(parents.enumerated()), id: \.element.id) { index, parent in
                    let angle = angleForIndex(index, total: parents.count)
                    let checkin = checkins[parent.id]
                    let status = checkin?.status ?? .none

                    ParentSeatView(
                        parent: parent,
                        status: status,
                        action: {
                            onSelectParent(parent)
                        }
                    )
                    .offset(x: offsetForAngle(angle).x, y: offsetForAngle(angle).y)
                }
            }
        }
        .frame(width: 320, height: 320)
        .padding(.vertical, 16)
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
        let radius: CGFloat = 105
        let x = radius * CGFloat(cos(angle))
        let y = radius * CGFloat(sin(angle))
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Individual Parent Seat Circle
struct ParentSeatView: View {
    let parent: FamilyMember
    let status: CheckinStatus
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Circle background depending on checkin status
                    Circle()
                        .fill(circleFillColor)
                        .frame(width: 68, height: 68)
                        .overlay(
                            Circle()
                                .stroke(circleStrokeColor, lineWidth: strokeWidth)
                        )

                    // Inner status icon or initial
                    if status == .ok {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.ccPaper)
                    } else if status == .waiting {
                        Image(systemName: "hourglass")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.ccInk)
                    } else if status == .missed {
                        Image(systemName: "exclamationmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color.ccPaper)
                    } else {
                        // Empty outline: Show parent's first initial
                        Text(String(parent.displayName.prefix(1)))
                            .font(.familyHeadingMedium())
                            .foregroundColor(Color.ccInk.opacity(0.7))
                    }
                }

                // Member Name
                Text(parent.displayName)
                    .font(.familyCaption())
                    .foregroundColor(Color.ccInk)
                    .lineLimit(1)
                    .frame(width: 80)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(parent.displayName): \(statusDescription)")
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
            return Color.ccPaper        // Empty outline (no check-in yet)
        }
    }

    private var circleStrokeColor: Color {
        switch status {
        case .none:
            return Color.ccInk.opacity(0.35)
        default:
            return Color.clear
        }
    }

    private var strokeWidth: CGFloat {
        status == .none ? 2.5 : 0
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
