//
//  ContentView.swift
//  secondthought
//
//  Created by Yaseen Halabi on 7/26/25.
//

import SwiftUI
import DeviceActivity
import FamilyControls
import ManagedSettings

struct ContentView: View {
    @State private var showContinueScreen = false
    @State private var urlScheme = ""
    @State private var hasRequestedPermissions = false
    @State private var showAppSelector = false
    @State private var selectedApps = FamilyActivitySelection()
    @State private var hasConfiguredApps = false
    
    // DeviceActivity and ManagedSettings stores
    private let deviceActivityCenter = DeviceActivityCenter()
    private let managedSettings = ManagedSettingsStore(named: .init("SecondThoughtStore"))
    
    var body: some View {
        VStack {
            if showAppSelector {
                AppSelectorView(selectedApps: $selectedApps) {
                    saveSelectedApps()
                    showAppSelector = false
                    hasConfiguredApps = true
                }
            } else if showContinueScreen {
                ContinueScreen(urlScheme: urlScheme, onAppOpened: startAppMonitoring)
            } else {
                VStack(spacing: 20) {
                    Text("Second thought")
                        .font(.largeTitle)
                        .padding()
                    
                    if !hasConfiguredApps {
                        Button("Configure Apps") {
                            showAppSelector = true
                        }
                        .font(.title2)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            handleAppBecameActive()
        }
        .onAppear {
            requestPermissionsIfNeeded()
            checkIfAppsConfigured()
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
    
    // Map URL schemes to bundle identifiers
    private func getBundleIdentifier(from urlScheme: String) -> String? {
        let schemeMapping: [String: String] = [
            "instagram://": "com.burbn.instagram",
            "snapchat://": "com.toyopagroup.picaboo",
            "tiktok://": "com.zhiliaoapp.musically",
            "youtube://": "com.google.ios.youtube",
            "twitter://": "com.atebits.Tweetie2",
            "facebook://": "com.facebook.Facebook",
            "whatsapp://": "net.whatsapp.WhatsApp",
            "spotify://": "com.spotify.client",
            "reddit://": "com.reddit.Reddit"
        ]
        return schemeMapping[urlScheme]
    }
    
    
    // Check if apps are configured
    private func checkIfAppsConfigured() {
        hasConfiguredApps = UserDefaults.standard.bool(forKey: "hasConfiguredApps")
        if hasConfiguredApps {
            loadSelectedApps()
        }
    }
    
    // Save selected apps to UserDefaults
    private func saveSelectedApps() {
        print("📱 SAVING selected apps:")
        print("  Selected applications count: \(selectedApps.applications.count)")
        
        // Save the selection to UserDefaults using encoded data
        if let encoded = try? JSONEncoder().encode(selectedApps) {
            UserDefaults.standard.set(encoded, forKey: "selectedApps")
            UserDefaults.standard.set(true, forKey: "hasConfiguredApps")
            print("  Apps saved successfully")
        } else {
            print("  ERROR: Failed to save selected apps")
        }
    }
    
    // Load selected apps from UserDefaults
    private func loadSelectedApps() {
        guard let data = UserDefaults.standard.data(forKey: "selectedApps"),
              let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            print("  No saved app selection found")
            return
        }
        
        selectedApps = decoded
        print("📱 LOADED selected apps: \(selectedApps.applications.count) applications")
    }
    
    // Get ApplicationToken for a URL scheme
    private func getApplicationToken(for urlScheme: String) -> ApplicationToken? {
        guard let bundleID = getBundleIdentifier(from: urlScheme) else {
            print("⚠️  No bundle ID found for URL scheme: \(urlScheme)")
            return nil
        }
        
        print("🔍 SEARCHING for token with bundle ID: \(bundleID)")
        print("  Available applications: \(selectedApps.applications.count)")
        print("  Available tokens: \(selectedApps.applicationTokens.count)")
        
        // Try to find matching application first
        for (index, application) in selectedApps.applications.enumerated() {
            print("  App \(index): \(application.bundleIdentifier ?? "unknown")")
            if application.bundleIdentifier == bundleID {
                print("✅ FOUND matching application at index \(index)")
                // Get corresponding token at same index
                let tokens = Array(selectedApps.applicationTokens)
                if index < tokens.count {
                    print("✅ RETURNING token at index \(index)")
                    return tokens[index]
                }
            }
        }
        
        print("❌ NO MATCHING TOKEN found for bundle ID: \(bundleID)")
        print("   Falling back to first available token")
        return selectedApps.applicationTokens.first
    }
    
    // Start monitoring an app for 20 seconds
    private func startAppMonitoring(for urlScheme: String) {
        guard let token = getApplicationToken(for: urlScheme) else {
            print("⚠️  No application token found for URL scheme: \(urlScheme)")
            return
        }
        
        print("📱 STARTING 20-second monitoring for: \(urlScheme)")
        print("  Using token: \(token)")
        print("  Timer will fire in 20 seconds at: \(Date(timeIntervalSinceNow: 20))")
        
        // Start 20-second timer to block the app
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            print("⏰ 20-SECOND TIMER FIRED at: \(Date())")
            self.blockAppWithToken(token: token)
            
            // Optional: Unblock after some time (e.g., 10 minutes)
            DispatchQueue.main.asyncAfter(deadline: .now() + 600) {
                print("⏰ 10-MINUTE TIMER FIRED at: \(Date())")
                self.unblockAllApps()
            }
        }
    }
    
    // Block app using ApplicationToken
    private func blockAppWithToken(token: ApplicationToken) {
        // First check authorization status
        let authStatus = AuthorizationCenter.shared.authorizationStatus
        print("🚫 BLOCKING app with token: \(token)")
        print("  Authorization status: \(authStatus)")
        
        guard authStatus == .approved else {
            print("  ❌ ERROR: Not authorized for Family Controls (status: \(authStatus))")
            return
        }
        
        print("  Current shield settings before: \(managedSettings.shield.applications?.count ?? 0) apps")
        
        do {
            managedSettings.shield.applications = Set([token])
            print("  ✅ Shield settings applied successfully")
        } catch {
            print("  ❌ ERROR applying shield settings: \(error)")
            return
        }
        
        print("  Current shield settings after: \(managedSettings.shield.applications?.count ?? 0) apps")
        
        // Verify the setting was applied
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let currentShield = self.managedSettings.shield.applications
            print("  ✅ VERIFICATION: Shield contains \(currentShield?.count ?? 0) apps")
            if let shielded = currentShield {
                for app in shielded {
                    print("    Shielded app token: \(app)")
                }
            }
        }
    }
    
    // Unblock all apps
    private func unblockAllApps() {
        print("✅ UNBLOCKING all apps")
        managedSettings.shield.applications = nil
        print("  All apps unblocked successfully")
    }
}

struct ContinueScreen: View {
    let urlScheme: String
    let onAppOpened: (String) -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Ready to continue?")
                .font(.title)
            
            Text("You'll have 20 seconds before the app is blocked")
                .font(.caption)
                .foregroundColor(.secondary)
            
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
            
            // Start 20-second monitoring for app blocking
            onAppOpened(urlScheme)
            
            // Set a brief cooldown to prevent immediate re-triggering
            let now = Date().timeIntervalSince1970
            let timestampKey = "schemeLastUpdated_\(urlScheme)"
            UserDefaults.standard.set(now, forKey: timestampKey)
            print("  Set cooldown timestamp after opening app: \(now) to key: '\(timestampKey)'")
        }
        print("🟠 CONTINUE BUTTON END\n")
    }
}

struct AppSelectorView: View {
    @Binding var selectedApps: FamilyActivitySelection
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Apps to Monitor")
                .font(.title)
                .padding()
            
            Text("Choose the apps you want Second Thought to monitor and block after 20 seconds")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            FamilyActivityPicker(selection: $selectedApps)
                .frame(height: 400)
            
            Button("Save Selection") {
                onComplete()
            }
            .font(.title2)
            .padding()
            .background(selectedApps.applications.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(selectedApps.applications.isEmpty)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
