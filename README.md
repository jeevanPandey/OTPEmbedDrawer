# OTPEmbedDrawer

A modern SwiftUI implementation of an adaptive bottom drawer featuring a custom OTP verification flow. This project demonstrates how to build a "Maps-like" bottom-up controller that dynamically adjusts to its content.

## 🚀 Features

- **Adaptive Bottom Drawer**: 
    - Automatically adjusts height based on its content.
    - Caps at 80% of screen height with internal scrolling for taller content.
    - Smooth "spring" animations for a native feel.
    - Gesture-based interactions (drag-to-dismiss).
- **Custom OTP Input Flow**:
    - Multi-box OTP entry field.
    - Auto-focus and auto-dismiss keyboard on completion.
    - Keyboard accessory bar with a "Done" button.
- **Modern Architecture**:
    - Clean separation of concerns (MVVM).
    - Centralized configuration via `AppConstants`.
    - Highly reusable `View` modifiers.

## 📸 Screenshots

| Initial State | OTP Drawer |
| --- | --- |
| ![Main Screen](docs/screenshots/main_screen.jpg) | ![OTP Drawer](docs/screenshots/otp_drawer.jpg) |

*(Note: Please replace the placeholder paths above with actual screenshot files in your repository)*

## 🛠 Project Structure

```text
OTPEmbedDrawer/
├── Drawer/
│   └── AdaptiveBottomDrawer.swift  # Core drawer implementation & modifiers
├── AppConstants.swift              # Centralized UI & Layout constants
├── ContentView.swift               # Main landing page
├── OTPView.swift                   # OTP UI & timer logic
├── OTPViewModel.swift              # OTP state management
└── OTPInputView.swift              # Custom 6-digit input component
```

## 🏗 Requirements

- iOS 17.0+
- Xcode 15.0+
- SwiftUI

## 📖 How to Use the Drawer

You can easily wrap any view in the adaptive drawer using the provided view modifier:

```swift
YourView()
    .adaptiveDrawer(isPresented: $showDrawer) {
        YourDrawerContent()
    }
```

## ✅ Code Quality

This project follows a strict [iOS Code Review Checklist](codereview_ios.md) covering:
- Architecture & SwiftUI best practices.
- State management and data flow.
- Performance and memory optimization.
- Accessibility & Localization standards.
