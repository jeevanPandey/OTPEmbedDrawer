//
//  AdaptiveBottomDrawer.swift
//  OTPEmbedDrawer
//

import SwiftUI

private enum DrawerConstants {
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
                    let maxHeight = screenHeight * DrawerConstants.maxHeightMultiplier
                    
                    // Total height including handle and safe area
                    let totalHeaderHeight = DrawerConstants.handleHeight + DrawerConstants.handleTopPadding + DrawerConstants.handleBottomPadding
                    let visibleHeight = min(contentHeight + totalHeaderHeight + safeAreaBottom, maxHeight)
                    
                    VStack(spacing: 0) {
                        drawerHandle
                        
                        drawerContent(maxContentHeight: maxHeight - totalHeaderHeight - safeAreaBottom)
                        
                        Spacer(minLength: 0)
                    }
                    .frame(width: proxy.size.width)
                    .frame(height: screenHeight)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: DrawerConstants.cornerRadius, topTrailingRadius: DrawerConstants.cornerRadius))
                    .shadow(color: .black.opacity(DrawerConstants.shadowOpacity), radius: DrawerConstants.shadowRadius)
                    .offset(y: (screenHeight - visibleHeight) + max(dragOffset, 0))
                    .gesture(dragGesture)
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .animation(.spring(response: DrawerConstants.springResponse, dampingFraction: DrawerConstants.springDamping), value: isPresented)
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                contentHeight = 0
            }
        }
    }
    
    // MARK: - Subviews
    
    private var dimmedBackground: some View {
        Color.black.opacity(DrawerConstants.backgroundOpacity)
            .ignoresSafeArea()
            .onTapGesture { dismiss() }
            .transition(.opacity)
    }
    
    private var drawerHandle: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.4))
            .frame(width: DrawerConstants.handleWidth, height: DrawerConstants.handleHeight)
            .padding(.top, DrawerConstants.handleTopPadding)
            .padding(.bottom, DrawerConstants.handleBottomPadding)
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
                if value.translation.height > DrawerConstants.dragDismissThreshold || 
                   value.predictedEndTranslation.height > DrawerConstants.velocityDismissThreshold {
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
