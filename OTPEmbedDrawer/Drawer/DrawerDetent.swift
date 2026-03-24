//
//  DrawerDetent.swift
//  OTPEmbedDrawer
//
//  Created by Jeevan Pandey on 03/03/26.
//

import SwiftUI

public enum DrawerDetent: Equatable {
    case height(CGFloat)     // Fixed height
    case fraction(CGFloat)   // % of screen height
    case full                // Full screen
}

public struct AdaptiveBottomDrawerConfiguration {
    
    public var cornerRadius: CGFloat = 20
    public var backgroundColor: Color = Color(.systemBackground)
    public var dimOpacity: Double = 0.35
    
    public var handleHeight: CGFloat = 5
    public var handleTopPadding: CGFloat = 8
    public var handleBottomPadding: CGFloat = 12
    
    public var horizontalPadding: CGFloat = 16
    
    public var detents: [DrawerDetent] = [
        .fraction(0.35),
        .fraction(0.7),
        .full
    ]
    
    public init() {}
}


