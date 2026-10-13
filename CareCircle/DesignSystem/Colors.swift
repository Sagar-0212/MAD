import SwiftUI

// MARK: - CareCircle Color Tokens
// Exact specifications from design brief:
// ink:     #1F2A24  (primary text, warm near-black, never pure black)
// paper:   #F7F5EF  (background)
// hearth:  #B75B3E  (confirmed check-in / primary action — warm clay, not red)
// waiting: #D8A93E  (grace-period state — dusty gold)
// alert:   #A63D3D  (confirmed missed check-in — brick red, used sparingly)
// linen:   #E7E2D4  (card/surface background, one step off paper)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    public static let ccInk = Color(hex: "#1F2A24")
    public static let ccPaper = Color(hex: "#F7F5EF")
    public static let ccHearth = Color(hex: "#B75B3E")
    public static let ccWaiting = Color(hex: "#D8A93E")
    public static let ccAlert = Color(hex: "#A63D3D")
    public static let ccLinen = Color(hex: "#E7E2D4")
    
    // Hairline border: Ink at 10% opacity
    public static let ccHairline = Color(hex: "#1F2A24").opacity(0.10)
}
