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
    
    // Violation: Senior Audit - @State with Reference Type
    @State private var session = TestObject()
    
    // Violation: Naming convention
    @State private var showDrawer = false
    
    // Violation: force unwrapping
    var optionalValue: String? = "Testing"
    
    var body: some View {
        
        // Violation: Performance Audit - Heavy computation in body
        let items = Array(0...100).filter { $0 % 2 == 0 }.map { "\($0)" }
        
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Violation: Magic number in view
                Text("OTP Drawer Sample: \(optionalValue!)") 
                    .padding(500)
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
// Trigger review
