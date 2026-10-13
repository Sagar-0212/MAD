import SwiftUI
import UIKit

// MARK: - CareCircle Color Tokens
// Exact specifications from design brief:
// Token                   Light        Dark
// ccInk (primary text)    #1F2A24      #ECE8DE
// ccPaper (bg / on-accent)#F7F5EF      #141815
// ccLinen (card surface)  #E7E2D4      #222823
// ccHearth (primary / ok) #B75B3E      #D2785A
// ccWaiting (grace)       #D8A93E      #E2B654
// ccAlert (missed)        #A63D3D      #D46464
// ccHairline              ink @ 10%    #FFFFFF @ 12%

extension UIColor {
    convenience init(lightHex: String, darkHex: String) {
        self.init { traitCollection in
            let hex = (traitCollection.userInterfaceStyle == .dark) ? darkHex : lightHex
            return UIColor(hex: hex)
        }
    }

    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleanHex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: alpha
        )
    }
}

extension Color {
    public init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }

    public init(lightHex: String, darkHex: String) {
        self.init(uiColor: UIColor(lightHex: lightHex, darkHex: darkHex))
    }

    // Adaptive Core Tokens
    public static let ccInk = Color(lightHex: "#1F2A24", darkHex: "#ECE8DE")
    public static let ccPaper = Color(lightHex: "#F7F5EF", darkHex: "#141815")
    public static let ccLinen = Color(lightHex: "#E7E2D4", darkHex: "#222823")
    public static let ccHearth = Color(lightHex: "#B75B3E", darkHex: "#D2785A")
    public static let ccWaiting = Color(lightHex: "#D8A93E", darkHex: "#E2B654")
    public static let ccAlert = Color(lightHex: "#A63D3D", darkHex: "#D46464")

    // Adaptive Hairline: light ink @ 10%, dark #FFFFFF @ 12%
    public static let ccHairline = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(white: 1.0, alpha: 0.12)
        } else {
            return UIColor(hex: "#1F2A24", alpha: 0.10)
        }
    })

    // Semantic Tokens
    public static let ccSurfaceRaised = Color(lightHex: "#FFFDF8", darkHex: "#2B312C")
    public static let ccTextSecondary = ccInk.opacity(0.72)
    public static let ccTextTertiary = ccInk.opacity(0.60)

    public static let ccHearthSoft = ccHearth.opacity(0.14)
    public static let ccWaitingSoft = ccWaiting.opacity(0.14)
    public static let ccAlertSoft = ccAlert.opacity(0.14)
}
