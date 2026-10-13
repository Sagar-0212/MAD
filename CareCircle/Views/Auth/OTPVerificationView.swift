import SwiftUI

public struct OTPVerificationView: View {
    let phoneNumber: String
    @Binding public var otpCode: String
    public var onVerify: () -> Void
    public var onResend: () -> Void
    public var onBack: () -> Void

    @FocusState private var isFocused: Bool
    @State private var timeRemaining: Int = 45
    @State private var timerActive: Bool = true
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init(
        phoneNumber: String,
        otpCode: Binding<String>,
        onVerify: @escaping () -> Void = {},
        onResend: @escaping () -> Void = {},
        onBack: @escaping () -> Void = {}
    ) {
        self.phoneNumber = phoneNumber
        self._otpCode = otpCode
        self.onVerify = onVerify
        self.onResend = onResend
        self.onBack = onBack
    }

    private var isCodeComplete: Bool {
        otpCode.count == 6
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation
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

            // Header
            VStack(alignment: .leading, spacing: 10) {
                Text("Enter verification code")
                    .font(.familyHeadingLarge())
                    .foregroundColor(Color.ccInk)

                Text("Sent to \(phoneNumber). Enter the 6-digit code below to confirm.")
                    .font(.familyBody())
                    .foregroundColor(Color.ccInk.opacity(0.65))
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            Spacer().frame(height: 36)

            // 6-digit PIN Box Grid
            ZStack {
                // Invisible textfield to handle keyboard input
                TextField("", text: $otpCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isFocused)
                    .opacity(0.01)
                    .onChange(of: otpCode) { _ in
                        let filtered = otpCode.filter { $0.isNumber }
                        if filtered.count > 6 {
                            otpCode = String(filtered.prefix(6))
                        } else {
                            otpCode = filtered
                        }
                        if otpCode.count == 6 {
                            let impact = UINotificationFeedbackGenerator()
                            impact.notificationOccurred(.success)
                            onVerify()
                        }
                    }

                // Visual boxes
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { index in
                        OTPDigitCell(
                            digit: getDigit(at: index),
                            isActive: isFocused && otpCode.count == index
                        )
                    }
                }
                .onTapGesture {
                    isFocused = true
                }
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 28)

            // Resend Countdown
            HStack(spacing: 4) {
                if timeRemaining > 0 {
                    Text("Didn't receive it? Resend in")
                        .font(.familyCaption())
                        .foregroundColor(Color.ccInk.opacity(0.55))
                    Text("0:\(String(format: "%02d", timeRemaining))")
                        .font(.familyNumeral(size: 13))
                        .foregroundColor(Color.ccHearth)
                } else {
                    Button(action: {
                        timeRemaining = 45
                        onResend()
                    }) {
                        Text("Resend verification code")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.ccHearth)
                    }
                }
            }

            Spacer()

            // Confirm Button
            VStack(spacing: 12) {
                Button(action: onVerify) {
                    Text("Verify & Continue")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.ccPaper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(isCodeComplete ? Color.ccHearth : Color.ccInk.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!isCodeComplete)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .paperBackground()
        .onAppear {
            isFocused = true
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }

    private func getDigit(at index: Int) -> String {
        let chars = Array(otpCode)
        guard index < chars.count else { return "" }
        return String(chars[index])
    }
}

private struct OTPDigitCell: View {
    let digit: String
    let isActive: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.ccLinen.opacity(0.55))

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isActive ? Color.ccHearth : Color.ccHairline, lineWidth: isActive ? 2 : 1)

            if !digit.isEmpty {
                Text(digit)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color.ccInk)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
    }
}
