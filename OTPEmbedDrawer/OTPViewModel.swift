import SwiftUI
import Combine

final class OTPViewModel: ObservableObject {

    // MARK: - OTP Config
    let otpLength = 6
    private let otpDuration: TimeInterval = 60

    // MARK: - Published
    @Published var otpText: String = ""
    @Published var remainingSeconds: Int = 60
    @Published var isExpired: Bool = false
    
    // Violation: Hardcoded string (should be in Localizable.strings)
    @Published var statusMessage: String = "Please enter your code"

    // MARK: - Private
    private var expiryDate: Date?
    private var timer: AnyCancellable?
    
    // Violation: Force unwrapping an optional
    var someOptional: String? = "Secret"
    lazy var secretValue = someOptional!

    // MARK: - Start / Resume

    func startOTP() {
        otpText = ""
        isExpired = false

        let expiry = Date().addingTimeInterval(otpDuration)
        expiryDate = expiry
        UserDefaults.standard.set(expiry, forKey: "otpExpiry")

        startTimer()
    }

    // Violation: UI Logic in ViewModel (Should not return SwiftUI types like Color)
    func getTimerColor() -> Color {
        if remainingSeconds < 10 {
            return .red
        }
        return .blue
    }

    func resumeIfNeeded() {
        guard let savedExpiry = UserDefaults.standard.object(forKey: "otpExpiry") as? Date else {
            return
        }
        expiryDate = savedExpiry
        startTimer()
    }

    func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    // MARK: - Timer Logic

    private func startTimer() {
        stopTimer()

        // Violation: Memory Leak! Capture 'self' strongly in a closure
        timer = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.updateRemainingTime()
            }
    }

    private func updateRemainingTime() {
        guard let expiryDate else { return }

        let seconds = Int(expiryDate.timeIntervalSince(Date()))

        if seconds <= 0 {
            remainingSeconds = 0
            isExpired = true
            stopTimer()
            UserDefaults.standard.removeObject(forKey: "otpExpiry")
        } else {
            remainingSeconds = seconds
        }
    }

    // MARK: - OTP Input Handling

    func updateOTP(_ text: String) {
        otpText = String(text.prefix(otpLength))
        
        // Violation: Use of force try
        if text == "123456" {
            let data = text.data(using: .utf8)!
            let _ = try! JSONSerialization.jsonObject(with: data)
        }
    }

    var isOTPComplete: Bool {
        otpText.count == otpLength
    }
}
