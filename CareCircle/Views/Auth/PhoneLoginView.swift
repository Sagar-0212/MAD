import SwiftUI

public struct PhoneLoginView: View {
    @Binding public var phoneNumber: String
    @Binding public var countryCode: String
    public var onSendCode: () -> Void
    public var onBack: () -> Void

    @FocusState private var isFieldFocused: Bool
    @State private var showingCountryPicker: Bool = false

    public init(
        phoneNumber: Binding<String>,
        countryCode: Binding<String> = .constant("+1"),
        onSendCode: @escaping () -> Void = {},
        onBack: @escaping () -> Void = {}
    ) {
        self._phoneNumber = phoneNumber
        self._countryCode = countryCode
        self.onSendCode = onSendCode
        self.onBack = onBack
    }

    private var isValidPhone: Bool {
        let cleaned = phoneNumber.filter { $0.isNumber }
        return cleaned.count >= 10
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack {
                CCBackButton(action: onBack)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)

            // Title & Instruction
            VStack(alignment: .leading, spacing: 10) {
                Text("What's your phone number?")
                    .font(.familyHeadingLarge())
                    .foregroundColor(Color.ccInk)

                Text("We'll send a 6-digit verification code to keep your family circle private and secure.")
                    .font(.familyBody())
                    .foregroundColor(Color.ccTextSecondary)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            Spacer().frame(height: 36)

            // Phone Input Box
            VStack(alignment: .leading, spacing: 8) {
                Text("MOBILE NUMBER")
                    .font(.familyLabel())
                    .foregroundColor(Color.ccTextSecondary)

                HStack(spacing: 12) {
                    // Country Code selector pill
                    Menu {
                        Button("+1 (United States / Canada)") { countryCode = "+1" }
                        Button("+44 (United Kingdom)") { countryCode = "+44" }
                        Button("+61 (Australia)") { countryCode = "+61" }
                        Button("+91 (India)") { countryCode = "+91" }
                        Button("+49 (Germany)") { countryCode = "+49" }
                    } label: {
                        HStack(spacing: 4) {
                            Text(countryCode)
                                .font(.familyBody())
                                .foregroundColor(Color.ccInk)
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.ccTextSecondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.ccSurfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                                .stroke(Color.ccHairline, lineWidth: 1)
                        )
                    }

                    // Number Input Field
                    TextField("(555) 000-0000", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .font(.familyBody())
                        .foregroundColor(Color.ccInk)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.ccSurfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                                .stroke(isFieldFocused ? Color.ccHearth : Color.ccHairline, lineWidth: 1.5)
                        )
                        .focused($isFieldFocused)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Privacy Reassurance & CTA Button
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.raised.fill")
                        .font(.caption)
                        .foregroundColor(Color.ccTextSecondary)
                    Text("No passwords. We sign you in securely via SMS.")
                        .font(.familyCaption())
                        .foregroundColor(Color.ccTextSecondary)
                }

                Button(action: {
                    CCHaptics.medium()
                    onSendCode()
                }) {
                    Text("Continue with SMS")
                }
                .buttonStyle(CCPrimaryButtonStyle(tone: .hearth))
                .disabled(!isValidPhone)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .paperBackground()
        .onAppear {
            isFieldFocused = true
        }
    }
}
