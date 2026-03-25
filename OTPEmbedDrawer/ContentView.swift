//
//  ContentView.swift
//  OTPEmbedDrawer
//
//  Created by Jeevan Pandey on 03/03/26.
//

import SwiftUI

struct ContentView: View {
    
    @State private var showDrawer = false
    
    var body: some View {
        
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("OTP Drawer Sample")
                    .font(.title)
                    .fontWeight(.bold)
                
                Button(action: {
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
            // Content will auto-resize or scroll
            OTPView()
        }
    }
}
