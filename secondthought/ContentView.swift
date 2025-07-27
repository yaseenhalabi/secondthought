//
//  ContentView.swift
//  secondthought
//
//  Created by Yaseen Halabi on 7/26/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showContinueScreen = false
    @State private var urlScheme = ""
    
    var body: some View {
        VStack {
            if showContinueScreen {
                ContinueScreen(urlScheme: urlScheme)
            } else {
                Text("Second thought")
                    .font(.largeTitle)
                    .padding()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            handleAppBecameActive()
        }
    }
    
    private func handleAppBecameActive() {
        let savedScheme = UserDefaults.standard.string(forKey: "selectedAppScheme") ?? ""
        let savedTimestamp = UserDefaults.standard.double(forKey: "schemeLastUpdated")
        
        print("🟡 APP BECAME ACTIVE:")
        print("  Found scheme in UserDefaults: '\(savedScheme)'")
        print("  Found timestamp in UserDefaults: \(savedTimestamp)")
        
        if !savedScheme.isEmpty {
            print("🟢 APP: Scheme found, proceeding to clear and show continue screen")
            
            // Clear UserDefaults BEFORE showing continue screen
            UserDefaults.standard.set("", forKey: "selectedAppScheme")
            UserDefaults.standard.set(0.0, forKey: "schemeLastUpdated")
            print("  APP: Cleared selectedAppScheme")
            print("  APP: Cleared schemeLastUpdated")
            
            // Set state to show continue screen
            urlScheme = savedScheme
            showContinueScreen = true
            print("  APP: Set showContinueScreen = true with scheme: '\(savedScheme)'")
        } else {
            print("🔴 APP: No scheme found, showing home screen")
            showContinueScreen = false
        }
        print("🟡 APP BECAME ACTIVE END\n")
    }
}

struct ContinueScreen: View {
    let urlScheme: String
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Ready to continue?")
                .font(.title)
            
            Button("Continue") {
                openApp()
            }
            .font(.title2)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
    
    @MainActor
    private func openApp() {
        print("🟠 CONTINUE BUTTON PRESSED:")
        print("  About to open URL scheme: '\(urlScheme)'")
        
        guard let url = URL(string: urlScheme) else { 
            print("  ERROR: Invalid URL scheme")
            return 
        }
        
        Task {
            print("  Opening URL: \(url)")
            await UIApplication.shared.open(url)
            print("  UIApplication.open completed")
            
            // Set a brief cooldown to prevent immediate re-triggering
            let now = Date().timeIntervalSince1970
            UserDefaults.standard.set(now, forKey: "schemeLastUpdated")
            print("  Set cooldown timestamp after opening app: \(now)")
        }
        print("🟠 CONTINUE BUTTON END\n")
    }
}

#Preview {
    ContentView()
}
