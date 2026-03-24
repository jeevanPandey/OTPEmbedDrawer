//
//  SimpleBottomDrawer.swift
//  OTPEmbedDrawer
//
//  Created by Jeevan Pandey on 03/03/26.
//

import SwiftUI

struct SimpleBottomDrawer<Content: View>: View {
    
    @Binding var isPresented: Bool
    let content: Content
    
    @GestureState private var dragOffset: CGFloat = 0
    
    init(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        _isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                // Dim background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }
                    .transition(.opacity)
                
                // Drawer
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 40, height: 5)
                        .padding(.vertical, 8)
                    
                    content
                        .padding(.bottom, 20) // Extra padding for safe area handled by VStack
                }
                .frame(maxWidth: .infinity)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                        .fill(Color(UIColor.systemBackground))
                )
                .offset(y: max(dragOffset, 0))
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.height
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                withAnimation {
                                    isPresented = false
                                }
                            }
                        }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea()
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPresented)
    }
}

public extension View {
    func simpleBottomDrawer<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ZStack {
            self
            SimpleBottomDrawer(isPresented: isPresented, content: content)
        }
    }
}
