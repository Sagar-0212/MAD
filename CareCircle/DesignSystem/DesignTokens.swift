import SwiftUI
import UIKit

// MARK: - Spacing, Radius, Motion Tokens
public enum CCSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
}

public enum CCRadius {
    public static let sm: CGFloat = 10
    public static let md: CGFloat = 14
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 28
}

public enum CCMotion {
    public static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.8)
    public static let gentle = Animation.spring(response: 0.45, dampingFraction: 0.85)
}

// MARK: - Centralized Haptics Helper (§3.4)
public enum CCHaptics {
    public static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    public static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    public static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// MARK: - Static Date Formatters (§4)
public enum CCFormatters {
    public static let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    public static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    public static let dayMonth: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    public static let shortDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    private static let isoDayParser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    public static func isoDay(_ dateString: String) -> String {
        if let date = isoDayParser.date(from: dateString) {
            return dayMonth.string(from: date)
        }
        return dateString
    }

    public static func isoDay(from dateString: String) -> String {
        return isoDay(dateString)
    }
}

// MARK: - Card Modifiers (Updated with .continuous style)
struct LinenCardModifier: ViewModifier {
    var cornerRadius: CGFloat = CCRadius.lg
    var padding: CGFloat = CCSpacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.ccLinen)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.ccHairline, lineWidth: 1)
            )
    }
}

struct HairlineBorderModifier: ViewModifier {
    var cornerRadius: CGFloat = CCRadius.md

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.ccHairline, lineWidth: 1)
            )
    }
}

// MARK: - Form Style for Sheets
public struct CCFormStyleModifier: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(Color.ccPaper)
            .tint(Color.ccHearth)
    }
}

extension View {
    public func linenCard(cornerRadius: CGFloat = CCRadius.lg, padding: CGFloat = CCSpacing.md) -> some View {
        self.modifier(LinenCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    public func ccHairlineBorder(cornerRadius: CGFloat = CCRadius.md) -> some View {
        self.modifier(HairlineBorderModifier(cornerRadius: cornerRadius))
    }

    public func paperBackground() -> some View {
        self.background(Color.ccPaper.ignoresSafeArea())
    }

    public func ccFormStyle() -> some View {
        self.modifier(CCFormStyleModifier())
    }
}

// MARK: - Button Styles (§4)
public enum CCButtonTone {
    case hearth
    case ink
    case alert
}

public struct CCPrimaryButtonStyle: ButtonStyle {
    public var tone: CCButtonTone
    public var isLoading: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(tone: CCButtonTone = .hearth, isLoading: Bool = false) {
        self.tone = tone
        self.isLoading = isLoading
    }

    private var backgroundColor: Color {
        guard isEnabled else { return Color.ccLinen }
        switch tone {
        case .hearth: return Color.ccHearth
        case .ink: return Color.ccInk
        case .alert: return Color.ccAlert
        }
    }

    private var foregroundColor: Color {
        guard isEnabled else { return Color.ccTextTertiary }
        return Color.ccPaper
    }

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: CCSpacing.xs) {
            if isLoading {
                ProgressView()
                    .tint(foregroundColor)
            }
            configuration.label
                .font(.familyButton())
                .foregroundColor(foregroundColor)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 54)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous))
        .overlay(
            Group {
                if !isEnabled {
                    RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                        .stroke(Color.ccHairline, lineWidth: 1)
                }
            }
        )
        .scaleEffect(reduceMotion || !configuration.isPressed ? 1.0 : 0.97)
        .opacity(configuration.isPressed ? 0.9 : 1.0)
        .animation(CCMotion.snappy, value: configuration.isPressed)
    }
}

public struct CCSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.familyButton())
            .foregroundColor(isEnabled ? Color.ccInk : Color.ccTextTertiary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(Color.ccSurfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                    .stroke(Color.ccHairline, lineWidth: 1)
            )
            .scaleEffect(reduceMotion || !configuration.isPressed ? 1.0 : 0.97)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(CCMotion.snappy, value: configuration.isPressed)
    }
}

public struct CCTextButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.familyButton())
            .foregroundColor(Color.ccInk)
            .frame(minHeight: 44)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

// MARK: - Back Button Component (§4)
public struct CCBackButton: View {
    public var action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: {
            CCHaptics.light()
            action()
        }) {
            HStack(spacing: CCSpacing.xxs) {
                Image(systemName: "chevron.left")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                Text("Back")
                    .font(.familyButton())
            }
            .foregroundColor(Color.ccInk)
            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Back")
    }
}

// MARK: - Segmented Toggle Component (§4)
public struct CCSegmentedToggle<T: Hashable>: View {
    public let options: [(T, String)]
    @Binding public var selection: T
    @Namespace private var toggleNamespace

    public init(options: [(T, String)], selection: Binding<T>) {
        self.options = options
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { option in
                let isSelected = selection == option.0
                Button(action: {
                    if !isSelected {
                        CCHaptics.selection()
                        withAnimation(CCMotion.snappy) {
                            selection = option.0
                        }
                    }
                }) {
                    Text(option.1)
                        .font(.familyButton())
                        .foregroundColor(isSelected ? Color.ccPaper : Color.ccInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            ZStack {
                                if isSelected {
                                    Capsule()
                                        .fill(Color.ccHearth)
                                        .matchedGeometryEffect(id: "SEGMENT_PILL", in: toggleNamespace)
                                }
                            }
                        )
                        .contentShape(Capsule())
                }
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(4)
        .background(Color.ccLinen)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.ccHairline, lineWidth: 1))
    }
}

// MARK: - Field Container Component (§4)
public struct CCFieldContainer<Content: View>: View {
    public let label: String
    public let icon: String?
    public let isFocused: Bool
    public let error: String?
    @ViewBuilder public let content: () -> Content

    public init(label: String, icon: String? = nil, isFocused: Bool, error: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.icon = icon
        self.isFocused = isFocused
        self.error = error
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: CCSpacing.xs) {
            HStack(spacing: CCSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundColor(Color.ccTextSecondary)
                }
                Text(label.uppercased())
                    .font(.familyLabel())
                    .foregroundColor(Color.ccTextSecondary)
                    .tracking(1.0)
            }

            content()
                .padding(.horizontal, CCSpacing.md)
                .padding(.vertical, 14)
                .background(Color.ccSurfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                        .stroke(
                            error != nil ? Color.ccAlert : (isFocused ? Color.ccHearth : Color.ccHairline),
                            lineWidth: isFocused ? 1.5 : 1.0
                        )
                )

            if let error = error, !error.isEmpty {
                HStack(spacing: CCSpacing.xxs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                    Text(error)
                        .font(.familyCaption())
                }
                .foregroundColor(Color.ccAlert)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Secure Field Toggle (§4)
public struct CCSecureFieldToggle: View {
    @Binding public var text: String
    public var placeholder: String
    public var textContentType: UITextContentType?
    public var submitLabel: SubmitLabel
    public var onSubmit: (() -> Void)?
    @State private var isRevealed: Bool = false

    public init(
        placeholder: String = "",
        text: Binding<String>,
        textContentType: UITextContentType? = nil,
        submitLabel: SubmitLabel = .done,
        onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.textContentType = textContentType
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: CCSpacing.xs) {
            if isRevealed {
                TextField(placeholder, text: $text)
                    .font(.familyBody())
                    .foregroundColor(Color.ccInk)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .textContentType(textContentType)
                    .submitLabel(submitLabel)
                    .onSubmit { onSubmit?() }
            } else {
                SecureField(placeholder, text: $text)
                    .font(.familyBody())
                    .foregroundColor(Color.ccInk)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .textContentType(textContentType)
                    .submitLabel(submitLabel)
                    .onSubmit { onSubmit?() }
            }

            Button(action: {
                CCHaptics.light()
                isRevealed.toggle()
            }) {
                Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.ccTextSecondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
        }
    }
}

// MARK: - Screen Header (§4)
public struct CCScreenHeader<Trailing: View>: View {
    public let title: String
    public let subtitle: String?
    public let trailing: Trailing?

    public init(title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public init(title: String, subtitle: String? = nil) where Trailing == EmptyView {
        self.title = title
        self.subtitle = subtitle
        self.trailing = nil
    }

    public var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: CCSpacing.xxs) {
                Text(title)
                    .font(.familyHeadingLarge())
                    .foregroundColor(Color.ccInk)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.familyBody())
                        .foregroundColor(Color.ccTextSecondary)
                }
            }
            Spacer()
            if let trailing = trailing {
                trailing
            }
        }
        .padding(.horizontal, CCSpacing.lg)
        .padding(.top, CCSpacing.md)
        .padding(.bottom, CCSpacing.xs)
    }
}

// MARK: - Section Header (§4)
public struct CCSectionHeader<Trailing: View>: View {
    public let title: String
    public let subtitle: String?
    public let trailing: Trailing?

    public init(title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public init(title: String, subtitle: String? = nil) where Trailing == EmptyView {
        self.title = title
        self.subtitle = subtitle
        self.trailing = nil
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.familyHeadingMedium())
                    .foregroundColor(Color.ccInk)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.familyCaption())
                        .foregroundColor(Color.ccTextSecondary)
                }
            }
            Spacer()
            if let trailing = trailing {
                trailing
            }
        }
    }
}

// MARK: - Status Chip (§4)
public enum CCStatusTone {
    case hearth
    case waiting
    case alert
    case neutral
}

public struct CCStatusChip: View {
    public let text: String
    public let tone: CCStatusTone
    public let icon: String?

    public init(text: String, tone: CCStatusTone = .hearth, icon: String? = nil) {
        self.text = text
        self.tone = tone
        self.icon = icon
    }

    private var accentColor: Color {
        switch tone {
        case .hearth: return Color.ccHearth
        case .waiting: return Color.ccWaiting
        case .alert: return Color.ccAlert
        case .neutral: return Color.ccInk
        }
    }

    private var softBackground: Color {
        switch tone {
        case .hearth: return Color.ccHearthSoft
        case .waiting: return Color.ccWaitingSoft
        case .alert: return Color.ccAlertSoft
        case .neutral: return Color.ccLinen
        }
    }

    public var body: some View {
        HStack(spacing: CCSpacing.xxs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(text)
                .font(.familyCaption())
                .fontWeight(.semibold)
        }
        .foregroundColor(accentColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(softBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.ccHairline, lineWidth: 1))
    }
}

// MARK: - Avatar Component (§4)
public enum CCAvatarTone {
    case hearth
    case neutral
    case alert
    case waiting
}

public struct CCAvatar: View {
    public let name: String
    public let tone: CCAvatarTone
    public let size: CGFloat

    public init(name: String, tone: CCAvatarTone = .neutral, size: CGFloat = 40) {
        self.name = name
        self.tone = tone
        self.size = size
    }

    private var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(1)).uppercased()
    }

    private var fillColor: Color {
        switch tone {
        case .hearth: return Color.ccHearthSoft
        case .alert: return Color.ccAlertSoft
        case .waiting: return Color.ccWaitingSoft
        case .neutral: return Color.ccLinen
        }
    }

    private var textColor: Color {
        switch tone {
        case .hearth: return Color.ccHearth
        case .alert: return Color.ccAlert
        case .waiting: return Color.ccWaiting
        case .neutral: return Color.ccInk
        }
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: size, height: size)
                .overlay(Circle().stroke(Color.ccHairline, lineWidth: 1))

            Text(initial)
                .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
        }
        .accessibilityLabel(name)
    }
}

// MARK: - Empty State Component (§4)
public struct CCEmptyState: View {
    public let icon: String
    public let title: String
    public let message: String
    public let actionTitle: String?
    public let action: (() -> Void)?

    public init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: CCSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.ccHearthSoft)
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(Color.ccHairline, lineWidth: 1))
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(Color.ccHearth)
            }

            VStack(spacing: CCSpacing.xxs) {
                Text(title)
                    .font(.familyHeadingMedium())
                    .foregroundColor(Color.ccInk)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.familyBody())
                    .foregroundColor(Color.ccTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CCSpacing.lg)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    CCHaptics.light()
                    action()
                }) {
                    Text(actionTitle)
                }
                .buttonStyle(CCSecondaryButtonStyle())
                .frame(maxWidth: 220)
                .padding(.top, CCSpacing.xs)
            }
        }
        .padding(.vertical, CCSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Banner Component (§4)
public enum CCBannerTone {
    case alert
    case hearth
    case neutral
}

public struct CCBanner: View {
    public let message: String
    public let tone: CCBannerTone
    public let onDismiss: (() -> Void)?

    public init(message: String, tone: CCBannerTone = .alert, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.tone = tone
        self.onDismiss = onDismiss
    }

    private var iconName: String {
        switch tone {
        case .alert: return "exclamationmark.circle.fill"
        case .hearth: return "checkmark.circle.fill"
        case .neutral: return "info.circle.fill"
        }
    }

    private var toneColor: Color {
        switch tone {
        case .alert: return Color.ccAlert
        case .hearth: return Color.ccHearth
        case .neutral: return Color.ccInk
        }
    }

    public var body: some View {
        HStack(spacing: CCSpacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(toneColor)

            Text(message)
                .font(.familyCaption())
                .foregroundColor(Color.ccInk)
                .lineLimit(3)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: {
                    CCHaptics.light()
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.ccTextSecondary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Dismiss")
            }
        }
        .padding(.horizontal, CCSpacing.md)
        .padding(.vertical, CCSpacing.sm)
        .background(Color.ccSurfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                .stroke(toneColor.opacity(0.35), lineWidth: 1)
        )
        .onAppear {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}

// MARK: - Step Progress Indicator (§4)
public struct CCStepProgress: View {
    public let current: Int
    public let total: Int

    public init(current: Int, total: Int = 4) {
        self.current = current
        self.total = total
    }

    public var body: some View {
        HStack(spacing: CCSpacing.xs) {
            ForEach(1...total, id: \.self) { step in
                Capsule()
                    .fill(step <= current ? Color.ccHearth : Color.ccLinen)
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityLabel("Step \(current) of \(total)")
        .padding(.horizontal, CCSpacing.lg)
    }
}
