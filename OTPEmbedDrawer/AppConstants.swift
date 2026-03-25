//
//  AppConstants.swift
//  OTPEmbedDrawer
//

import SwiftUI

enum AppConstants {
    enum Drawer {
        static let backgroundOpacity: Double = 0.3
        static let handleWidth: CGFloat = 40
        static let handleHeight: CGFloat = 5
        static let handleTopPadding: CGFloat = 10
        static let handleBottomPadding: CGFloat = 10
        static let maxHeightMultiplier: CGFloat = 0.8
        static let cornerRadius: CGFloat = 20
        static let shadowRadius: CGFloat = 10
        static let shadowOpacity: Double = 0.1
        static let dragDismissThreshold: CGFloat = 100
        static let velocityDismissThreshold: CGFloat = 200
        static let springResponse: Double = 0.35
        static let springDamping: Double = 0.8
    }
    
    enum UI {
        static let doneButtonTitle: String = "Done"
        static let accentColor: Color = .blue
    }
}
