//
//  AdaptiveBottomDrawer.swift
//  OTPEmbedDrawer
//

import SwiftUI

struct DrawerView<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    @State private var contentHeight: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                // Background Dim
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                    .transition(.opacity)
                
                GeometryReader { proxy in
                    let screenHeight = proxy.size.height
                    let safeAreaBottom = proxy.safeAreaInsets.bottom
                    let maxHeight = screenHeight * 0.8
                    
                    // The actual height of the drawer visible area
                    let visibleHeight = min(contentHeight + 40 + safeAreaBottom, maxHeight)
                    
                    VStack(spacing: 0) {
                        // Handle
                        Capsule()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 40, height: 5)
                            .padding(.top, 10)
                            .padding(.bottom, 10)
                        
                        // Content
                        ScrollView(contentHeight > (maxHeight - 40 - safeAreaBottom) ? .vertical : []) {
                            content
                                .background(
                                    GeometryReader { contentProxy in
                                        Color.clear.onAppear {
                                            contentHeight = contentProxy.size.height
                                        }
                                        .onChange(of: contentProxy.size.height) { _, newValue in
                                            contentHeight = newValue
                                        }
                                    }
                                )
                        }
                        .frame(maxHeight: maxHeight - 40 - safeAreaBottom)
                        
                        Spacer(minLength: 0)
                    }
                    .frame(width: proxy.size.width)
                    .frame(height: screenHeight) // FULL SCREEN HEIGHT to prevent gap at bottom
                    .background(Color(UIColor.systemBackground))
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 10)
                    // Offset the entire full-height container so only the top 'visibleHeight' shows
                    .offset(y: (screenHeight - visibleHeight) + max(dragOffset, 0))
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation.height
                            }
                            .onEnded { value in
                                if value.translation.height > 100 || value.predictedEndTranslation.height > 200 {
                                    dismiss()
                                }
                            }
                    )
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPresented)
        .onChange(of: isPresented) { oldValue, newValue in
            if !newValue {
                // Reset height when dismissed to ensure fresh measurement next time
                contentHeight = 0
            }
        }
    }
    
    private func dismiss() {
        withAnimation {
            isPresented = false
        }
    }
}

public extension View {
    func adaptiveDrawer<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ZStack {
            self
            DrawerView(isPresented: isPresented, content: content())
        }
    }
}
