//
//  ContentView.swift
//  secondthought
//
//  Created by Yaseen Halabi on 7/26/25.
//

import SwiftUI
import DeviceActivity
import FamilyControls

struct ContentView: View {
    @State private var showContinueScreen = false
    @State private var urlScheme = ""
    @State private var hasRequestedPermissions = false
    
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
        .onAppear {
            requestPermissionsIfNeeded()
        }
    }
    
    private func handleAppBecameActive() {
        let savedScheme = UserDefaults.standard.string(forKey: "selectedAppScheme") ?? ""
        let timestampKey = savedScheme.isEmpty ? "N/A" : "schemeLastUpdated_\(savedScheme)"
        let savedTimestamp = savedScheme.isEmpty ? 0.0 : UserDefaults.standard.double(forKey: timestampKey)
        
        print("🟡 APP BECAME ACTIVE:")
        print("  Found scheme in UserDefaults: '\(savedScheme)'")
        print("  Per-app timestamp key: '\(timestampKey)'")
        print("  Found timestamp in UserDefaults: \(savedTimestamp)")
        
        if !savedScheme.isEmpty {
            print("🟢 APP: Scheme found, proceeding to clear and show continue screen")
            
            // Clear UserDefaults BEFORE showing continue screen
            UserDefaults.standard.set("", forKey: "selectedAppScheme")
            UserDefaults.standard.set(0.0, forKey: timestampKey)
            print("  APP: Cleared selectedAppScheme")
            print("  APP: Cleared \(timestampKey)")
            
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
    
    private func requestPermissionsIfNeeded() {
        // Only request once per app session
        guard !hasRequestedPermissions else { return }
        
        // Check if we already have permission
        let authStatus = AuthorizationCenter.shared.authorizationStatus
        print("🔐 PERMISSION CHECK:")
        print("  Current authorization status: \(authStatus)")
        
        if authStatus == .notDetermined {
            print("🟡 REQUESTING Screen Time permissions...")
            hasRequestedPermissions = true
            
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    print("🟢 Screen Time permission GRANTED")
                    handlePermissionGranted()
                } catch {
                    print("🔴 Screen Time permission DENIED: \(error)")
                    handlePermissionDenied()
                }
            }
        } else if authStatus == .approved {
            print("🟢 Screen Time permissions already granted")
            handlePermissionGranted()
        } else {
            print("🔴 Screen Time permissions denied or restricted")
            handlePermissionDenied()
        }
    }
    
    private func handlePermissionGranted() {
        print("✅ DeviceActivity API is now available")
        // Future: Initialize DeviceActivity monitoring here
    }
    
    private func handlePermissionDenied() {
        print("❌ DeviceActivity API not available - limited functionality")
        // Future: Show user message about limited functionality
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
            let timestampKey = "schemeLastUpdated_\(urlScheme)"
            UserDefaults.standard.set(now, forKey: timestampKey)
            print("  Set cooldown timestamp after opening app: \(now) to key: '\(timestampKey)'")
        }
        print("🟠 CONTINUE BUTTON END\n")
    }
}

#Preview {
    ContentView()
}
