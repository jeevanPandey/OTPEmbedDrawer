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

    // MARK: - Private
    private var expiryDate: Date?
    private var timer: AnyCancellable?

    // MARK: - Start / Resume

    func startOTP() {
        otpText = ""
        isExpired = false

        let expiry = Date().addingTimeInterval(otpDuration)
        expiryDate = expiry
        UserDefaults.standard.set(expiry, forKey: "otpExpiry")

        startTimer()
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

        timer = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateRemainingTime()
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
    }

    var isOTPComplete: Bool {
        otpText.count == otpLength
    }
}
