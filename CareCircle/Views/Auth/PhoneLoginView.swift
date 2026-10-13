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
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(Color.ccInk)
                }
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
                    .foregroundColor(Color.ccInk.opacity(0.65))
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            Spacer().frame(height: 36)

            // Phone Input Box
            VStack(alignment: .leading, spacing: 8) {
                Text("MOBILE NUMBER")
                    .font(.familyNumeral(size: 11))
                    .foregroundColor(Color.ccInk.opacity(0.45))
                    .tracking(1.2)

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
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.ccInk)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.ccInk.opacity(0.4))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.ccLinen)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    // Number Input Field
                    TextField("(555) 000-0000", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(Color.ccInk)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.ccLinen.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
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
                        .font(.system(size: 12))
                        .foregroundColor(Color.ccInk.opacity(0.4))
                    Text("No passwords. We sign you in securely via SMS.")
                        .font(.familyCaption())
                        .foregroundColor(Color.ccInk.opacity(0.5))
                }

                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onSendCode()
                }) {
                    Text("Continue with SMS")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.ccPaper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(isValidPhone ? Color.ccHearth : Color.ccInk.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
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
