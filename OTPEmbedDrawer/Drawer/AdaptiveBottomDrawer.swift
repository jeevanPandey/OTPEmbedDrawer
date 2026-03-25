//
//  AdaptiveBottomDrawer.swift
//  OTPEmbedDrawer
//

import SwiftUI

/// A container view that provides an adaptive bottom drawer behavior.
struct DrawerView<Content: View>: View {
    
    @Binding var isPresented: Bool
    private let content: Content
    
    @State private var contentHeight: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                dimmedBackground
                
                GeometryReader { proxy in
                    let screenHeight = proxy.size.height
                    let safeAreaBottom = proxy.safeAreaInsets.bottom
                    let maxHeight = screenHeight * AppConstants.Drawer.maxHeightMultiplier
                    
                    // Total height including handle and safe area
                    let totalHeaderHeight = AppConstants.Drawer.handleHeight + AppConstants.Drawer.handleTopPadding + AppConstants.Drawer.handleBottomPadding
                    let visibleHeight = min(contentHeight + totalHeaderHeight + safeAreaBottom, maxHeight)
                    
                    VStack(spacing: 0) {
                        drawerHandle
                        
                        drawerContent(maxContentHeight: maxHeight - totalHeaderHeight - safeAreaBottom)
                        
                        Spacer(minLength: 0)
                    }
                    .frame(width: proxy.size.width)
                    .frame(height: screenHeight)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: AppConstants.Drawer.cornerRadius, topTrailingRadius: AppConstants.Drawer.cornerRadius))
                    .shadow(color: .black.opacity(AppConstants.Drawer.shadowOpacity), radius: AppConstants.Drawer.shadowRadius)
                    .offset(y: (screenHeight - visibleHeight) + max(dragOffset, 0))
                    .gesture(dragGesture)
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .animation(.spring(response: AppConstants.Drawer.springResponse, dampingFraction: AppConstants.Drawer.springDamping), value: isPresented)
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                contentHeight = 0
            }
        }
    }
    
    // MARK: - Subviews
    
    private var dimmedBackground: some View {
        Color.black.opacity(AppConstants.Drawer.backgroundOpacity)
            .ignoresSafeArea()
            .onTapGesture { dismiss() }
            .transition(.opacity)
    }
    
    private var drawerHandle: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.4))
            .frame(width: AppConstants.Drawer.handleWidth, height: AppConstants.Drawer.handleHeight)
            .padding(.top, AppConstants.Drawer.handleTopPadding)
            .padding(.bottom, AppConstants.Drawer.handleBottomPadding)
    }
    
    private func drawerContent(maxContentHeight: CGFloat) -> some View {
        ScrollView(contentHeight > maxContentHeight ? .vertical : []) {
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
        .frame(maxHeight: maxContentHeight)
    }
    
    // MARK: - Interactions
    
    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                if value.translation.height > AppConstants.Drawer.dragDismissThreshold || 
                   value.predictedEndTranslation.height > AppConstants.Drawer.velocityDismissThreshold {
                    dismiss()
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
    /// Wraps the view in an adaptive bottom drawer.
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether the drawer is presented.
    ///   - content: A closure that returns the content to be displayed inside the drawer.
    func adaptiveDrawer<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ZStack {
            self
            DrawerView(isPresented: isPresented, content: content)
        }
    }
}
