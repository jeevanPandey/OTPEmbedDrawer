//
//  OTPView.swift
//  OTPSample
//
//  Created by Jeevan Pandey on 10/01/26.
//

import SwiftUI

struct OTPView: View {
    @StateObject private var viewModel = OTPViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var isOTPFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isOTPFieldFocused = false
                }
            VStack(spacing: 24) {
                Text("Verify OTP")
                    .font(.title.bold())

                OTPInputView(
                    otpText: $viewModel.otpText,
                    otpLength: viewModel.otpLength,
                    isFocused: $isOTPFieldFocused
                )

                Text(timerText)
                    .font(.headline)
                    .foregroundColor(viewModel.isExpired ? .red : .blue)

                Button("Resend OTP") {
                    viewModel.startOTP()
                }
                .disabled(!viewModel.isExpired)
                .opacity(viewModel.isExpired ? 1 : 0.4)

                Button("Verify OTP") {
                    print("OTP Entered:", viewModel.otpText)
                }
                .disabled(!viewModel.isOTPComplete)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            .onAppear {
                viewModel.resumeIfNeeded()
                if viewModel.remainingSeconds == 60 {
                    viewModel.startOTP()
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    viewModel.resumeIfNeeded()
                } else if phase == .background {
                    viewModel.stopTimer()
                }
            }
        }
    }

    private var timerText: String {
        viewModel.isExpired
        ? "OTP Expired"
        : String(format: "00:%02d", viewModel.remainingSeconds)
    }
}

