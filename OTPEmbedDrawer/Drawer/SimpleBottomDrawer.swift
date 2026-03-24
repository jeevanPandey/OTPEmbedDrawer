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
        
        if isPresented {
            GeometryReader { proxy in
                
                ZStack(alignment: .bottom) {
                    
                    // Dim background
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            isPresented = false
                        }
                    
                    // Drawer
                    VStack(spacing: 0) {
                        
                        Capsule()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 60, height: 6)
                            .padding(.vertical, 12)
                        
                        content
                            .padding(.horizontal, 16)
                            .padding(.bottom, proxy.safeAreaInsets.bottom)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(
                        maxHeight: proxy.size.height,
                        alignment: .top
                    )
                    .background(Color.white)
                    .cornerRadius(20)
                    .offset(y: max(dragOffset, 0))
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation.height
                            }
                            .onEnded { value in
                                if value.translation.height > 120 {
                                    isPresented = false
                                }
                            }
                    )
                }
            }
            .transition(.move(edge: .bottom))
            .animation(.easeOut(duration: 0.25), value: isPresented)
        }
    }
}



public struct BottomDrawer<SheetContent: View>: View {
    
    @Binding var isPresented: Bool
    private let sheetContent: () -> SheetContent
    
    @GestureState private var dragOffset: CGFloat = 0
    
    public init(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> SheetContent
    ) {
        _isPresented = isPresented
        self.sheetContent = content
    }
    
    public var body: some View {
        
        if isPresented {
            GeometryReader { proxy in
                
                ZStack(alignment: .bottom) {
                    
                    // Dim background
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            isPresented = false
                        }
                    
                    // Drawer
                    VStack(spacing: 0) {
                        
                        // Grabber
                        Capsule()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 60, height: 6)
                            .padding(.vertical, 12)
                        
                        sheetContent()
                            .padding(.horizontal, 16)
                            .padding(.bottom, proxy.safeAreaInsets.bottom)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(20)
                    .offset(y: max(dragOffset, 0))
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation.height
                            }
                            .onEnded { value in
                                if value.translation.height > 120 {
                                    isPresented = false
                                }
                            }
                    )
                }
            }
            .transition(.move(edge: .bottom))
            .animation(.easeOut(duration: 0.25), value: isPresented)
        }
    }
}


public extension View {
    func bottomDrawer<SheetContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        
        self.overlay(
            BottomDrawer(
                isPresented: isPresented,
                content: content
            )
        )
    }
}
