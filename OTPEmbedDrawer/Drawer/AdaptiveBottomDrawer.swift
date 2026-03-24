//
//  AdaptiveBottomDrawer.swift
//  OTPEmbedDrawer
//
//  Created by Jeevan Pandey on 03/03/26.
//

import SwiftUI

struct AdaptiveBottomDrawer<Content: View>: View {
    
    @Binding var isPresented: Bool
    let config: AdaptiveBottomDrawerConfiguration
    let content: Content
    
    @GestureState private var dragOffset: CGFloat = 0
    @State private var currentHeight: CGFloat = 0
    
    init(
        isPresented: Binding<Bool>,
        config: AdaptiveBottomDrawerConfiguration,
        @ViewBuilder content: () -> Content
    ) {
        _isPresented = isPresented
        self.config = config
        self.content = content()
    }
    
    var body: some View {
        
        GeometryReader { proxy in
            
            let screenHeight = proxy.size.height
            let width = proxy.size.width
            
            ZStack(alignment: .bottom) {
                
                // Background dim
                if isPresented {
                    Color.black.opacity(config.dimOpacity)
                        .ignoresSafeArea()
                        .onTapGesture { isPresented = false }
                }
                
                if isPresented {
                    drawer(
                        proxy: proxy,
                        screenHeight: screenHeight,
                        width: width
                    )
                }
            }
            .onChange(of: isPresented) { presented in
                if presented {
                    initializeHeight(screenHeight: screenHeight)
                }
            }
            .animation(.easeOut(duration: 0.25), value: isPresented)
        }
        .ignoresSafeArea()
    }
}


private extension AdaptiveBottomDrawer {
    
    func drawer(
        proxy: GeometryProxy,
        screenHeight: CGFloat,
        width: CGFloat
    ) -> some View {
        
        let minOffset = screenHeight - currentHeight
        
        return VStack(spacing: 0) {
            
            DrawerHandleView(
                width: width - (config.horizontalPadding * 2),
                config: config
            )
            
            content
                .padding(.horizontal, config.horizontalPadding)
                .padding(.bottom, proxy.safeAreaInsets.bottom)
        }
        .frame(width: width)
        .frame(height: currentHeight, alignment: .top)
        .background(config.backgroundColor)
        .clipShape(
            RoundedCorner(
                radius: config.cornerRadius,
                corners: [.topLeft, .topRight]
            )
        )
        .offset(y: max(minOffset + dragOffset, 0))
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.height
                }
                .onEnded { value in
                    
                    let newHeight = currentHeight - value.translation.height
                    
                    if newHeight < minimumHeight(screenHeight) * 0.7 {
                        isPresented = false
                        return
                    }
                    
                    currentHeight = nearestDetent(
                        to: newHeight,
                        screenHeight: screenHeight
                    )
                }
        )
    }
}

private extension AdaptiveBottomDrawer {
    
    func initializeHeight(screenHeight: CGFloat) {
        currentHeight = minimumHeight(screenHeight)
    }
    
    func minimumHeight(_ screenHeight: CGFloat) -> CGFloat {
        config.detents
            .map { resolveDetent($0, screenHeight) }
            .sorted()
            .first ?? screenHeight * 0.4
    }
    
    func nearestDetent(
        to height: CGFloat,
        screenHeight: CGFloat
    ) -> CGFloat {
        
        let heights = config.detents
            .map { resolveDetent($0, screenHeight) }
        
        return heights.min(by: {
            abs($0 - height) < abs($1 - height)
        }) ?? height
    }
    
    func resolveDetent(
        _ detent: DrawerDetent,
        _ screenHeight: CGFloat
    ) -> CGFloat {
        switch detent {
        case .height(let h): return h
        case .fraction(let f): return screenHeight * f
        case .full: return screenHeight
        }
    }
}
