//
//  RoundedCorner.swift
//  OTPEmbedDrawer
//
//  Created by Jeevan Pandey on 03/03/26.
//

import SwiftUI

struct DrawerHandleView: View {
    
    let width: CGFloat
    let config: AdaptiveBottomDrawerConfiguration
    
    var body: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.5))
            .frame(width: width, height: config.handleHeight)
            .padding(.top, config.handleTopPadding)
            .padding(.bottom, config.handleBottomPadding)
    }
}

public extension View {
    func adaptiveBottomDrawer<Content: View>(
        isPresented: Binding<Bool>,
        config: AdaptiveBottomDrawerConfiguration = .init(),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        
        self.overlay(
            AdaptiveBottomDrawer(
                isPresented: isPresented,
                config: config,
                content: content
            )
        )
    }
}

struct RoundedCorner: Shape {
    
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
