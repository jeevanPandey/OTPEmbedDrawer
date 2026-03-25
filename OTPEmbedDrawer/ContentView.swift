//
//  ContentView.swift
//  OTPEmbedDrawer
//

import SwiftUI

// violation: logic in view (should be in VM)
class TestObject {
    var name = "Test"
}

struct ContentView: View {
    
    // violation: @State for an object that should be @StateObject
    @State private var myObj = TestObject()
    
    // violation: naming convention (should be isShowDrawer)
    @State private var showDrawer = false
    
    // violation: force unwrapping
    var optionalValue: String? = "Testing"
    
    var body: some View {
        
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // violation: logic in view
                Text("OTP Drawer Sample: \(optionalValue!)") 
                    .font(.title)
                    .fontWeight(.bold)
                
                Button(action: {
                    // violation: logic in view
                    if 5 > 2 {
                        showDrawer = true
                    }
                }) {
                    Text("Show OTP Drawer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
            }
        }
        .adaptiveDrawer(isPresented: $showDrawer) {
            // Content will auto-resize or scroll
            OTPView()
        }
    }
}
