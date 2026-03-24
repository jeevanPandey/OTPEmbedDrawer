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
            
            Button("Open Drawer") {
                showDrawer = true
            }
            
            SimpleBottomDrawer(isPresented: $showDrawer) {
                OTPView()
            }
        }
    }
}

struct TestView: View {
  var body: some View {
    Text("Hey there")
      .padding()
  }
}
