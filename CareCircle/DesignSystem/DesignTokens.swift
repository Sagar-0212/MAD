import SwiftUI

// MARK: - CareCircle Surface & Card Modifiers
// Layout Principles:
// - No shadows, no gradients, no glassmorphism anywhere in the app.
// - Flat, warm, high-contrast, calm.
// - One hairline border style only: ink at 10% opacity.
// - Generous whitespace over dense packing.

struct LinenCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.ccLinen)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.ccHairline, lineWidth: 1)
            )
    }
}

struct HairlineBorderModifier: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.ccHairline, lineWidth: 1)
            )
    }
}

extension View {
    public func linenCard(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        self.modifier(LinenCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    public func ccHairlineBorder(cornerRadius: CGFloat = 12) -> some View {
        self.modifier(HairlineBorderModifier(cornerRadius: cornerRadius))
    }

    public func paperBackground() -> some View {
        self.background(Color.ccPaper.ignoresSafeArea())
    }
}
