//
//  ContentView.swift
//  OTPEmbedDrawer
//

import SwiftUI

// Violation: Class used with @State instead of @StateObject
class UserSession: ObservableObject {
    @Published var username: String = "Guest"
}

struct ContentView: View {
    
    // Violation: Senior Audit - @State used for reference type
    @State private var session = UserSession()
    @State private var showDrawer = false
    @State private var items = Array(0...1000).map { "Item \($0)" }
    
    var body: some View {
        
        // Violation: Performance - Heavy computation inside body
        let processedItems = items
            .filter { $0.contains("1") }
            .sorted { $0 > $1 }
            .map { $0.uppercased() }
        
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("User: \(session.username)")
                    .font(.title)
                
                List(processedItems.prefix(10), id: \.self) { item in
                    Text(item)
                }
                
                Button(action: {
                    // Violation: Concurrency - Background update without MainActor
                    DispatchQueue.global().async {
                        // Simulating work
                        Thread.sleep(forTimeInterval: 1)
                        session.username = "Senior User" // Crashes/Warnings in SwiftUI
                    }
                    showDrawer = true
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
            OTPView()
        }
    }
}
