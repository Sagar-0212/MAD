import SwiftUI

// MARK: - CareCircle Typography Tokens
// Parent Mode: System SF Pro Rounded ONLY, full Dynamic Type support.
// Family Mode Headings: Fraunces / Serif (light optical size).
// Family Mode Body: IBM Plex Sans / System Sans.
// Family Mode Numerals: IBM Plex Mono / System Monospaced (small sizes only).

extension Font {
    // MARK: - Parent Mode Fonts (SF Pro Rounded)
    public static func parentHero() -> Font {
        .system(size: 32, weight: .bold, design: .rounded)
    }

    public static func parentTitle() -> Font {
        .system(.title, design: .rounded, weight: .bold)
    }

    public static func parentHeadline() -> Font {
        .system(.title2, design: .rounded, weight: .semibold)
    }

    public static func parentBody() -> Font {
        .system(.body, design: .rounded, weight: .medium)
    }

    public static func parentCallout() -> Font {
        .system(.callout, design: .rounded, weight: .regular)
    }

    public static func parentButton() -> Font {
        .system(size: 26, weight: .bold, design: .rounded)
    }

    // MARK: - Family Mode Fonts
    public static func familyHeadingLarge() -> Font {
        if let _ = UIFont(name: "Fraunces-Light", size: 28) {
            return .custom("Fraunces-Light", size: 28, relativeTo: .title)
        }
        return .system(.title, design: .serif, weight: .light)
    }

    public static func familyHeadingMedium() -> Font {
        if let _ = UIFont(name: "Fraunces-Light", size: 22) {
            return .custom("Fraunces-Light", size: 22, relativeTo: .title2)
        }
        return .system(.title2, design: .serif, weight: .light)
    }

    public static func familyHeadingSmall() -> Font {
        if let _ = UIFont(name: "Fraunces-Light", size: 18) {
            return .custom("Fraunces-Light", size: 18, relativeTo: .headline)
        }
        return .system(.headline, design: .serif, weight: .regular)
    }

    public static func familyBody() -> Font {
        if let _ = UIFont(name: "IBMPlexSans", size: 16) {
            return .custom("IBMPlexSans", size: 16, relativeTo: .body)
        }
        return .system(.body, design: .default)
    }

    public static func familyBodyBold() -> Font {
        if let _ = UIFont(name: "IBMPlexSans-SemiBold", size: 16) {
            return .custom("IBMPlexSans-SemiBold", size: 16, relativeTo: .body)
        }
        return .system(.body, design: .default, weight: .semibold)
    }

    public static func familyCaption() -> Font {
        if let _ = UIFont(name: "IBMPlexSans", size: 13) {
            return .custom("IBMPlexSans", size: 13, relativeTo: .caption)
        }
        return .system(.caption, design: .default)
    }

    public static func familyNumeral(size: CGFloat = 13) -> Font {
        if let _ = UIFont(name: "IBMPlexMono", size: size) {
            return .custom("IBMPlexMono", size: size, relativeTo: .caption)
        }
        return .system(size: size, weight: .regular, design: .monospaced)
    }
}
