import SwiftUI

struct OTPInputView: View {

    @Binding var otpText: String
    let otpLength: Int

    @FocusState.Binding var isFocused: Bool

    init(otpText: Binding<String>, otpLength: Int, isFocused: FocusState<Bool>.Binding) {
        self._otpText = otpText
        self.otpLength = otpLength
        self._isFocused = isFocused
    }

    var body: some View {
        ZStack {
            TextField("", text: $otpText)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .opacity(0.01)
                .onChange(of: otpText) { _, newValue in
                    otpText = String(newValue.prefix(otpLength))
                    if otpText.count == otpLength {
                        isFocused = false
                    }
                }

            // OTP Boxes
            HStack(spacing: 12) {
                ForEach(0..<otpLength, id: \.self) { index in
                    otpBox(at: index)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button(AppConstants.UI.doneButtonTitle) {
                        isFocused = false
                    }
                    .foregroundColor(AppConstants.UI.accentColor)
                }
            }
        }
    }

    private func otpBox(at index: Int) -> some View {
        let char = index < otpText.count
        ? String(otpText[otpText.index(otpText.startIndex, offsetBy: index)])
        : ""

        return Text(char)
            .font(.title2.bold())
            .frame(width: 48, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused && otpText.count == index ? AppConstants.UI.accentColor : Color.gray, lineWidth: 1)
            )
    }
}
