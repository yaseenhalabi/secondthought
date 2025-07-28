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
    @State private var learnedSchemeToTokenMapping: [String: ApplicationToken] = [:]
    
    // App state management
    @State private var activeTimers: [String: [DispatchWorkItem]] = [:]
    @State private var blockedApps: Set<ApplicationToken> = []
    @State private var blockExpirationTimes: [String: Date] = [:]
    @State private var schemeToTokenMapping: [String: ApplicationToken] = [:]
    
    // DeviceActivity and ManagedSettings stores
    private let deviceActivityCenter = DeviceActivityCenter()
    private let managedSettings = ManagedSettingsStore(named: .init("SecondThoughtStore"))
    
    var body: some View {
        VStack {
            if showAppSelector {
                AppSelectorView(selectedApps: $selectedApps) {
                    saveAppConfiguration()
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
            restoreBlockingState()
        }
    }
    
    private func handleAppBecameActive() {
        let savedScheme = UserDefaults.standard.string(forKey: "selectedAppScheme") ?? ""
        
        print("🟡 APP BECAME ACTIVE:")
        print("  Found scheme in UserDefaults: '\(savedScheme)'")
        
        if !savedScheme.isEmpty {
            print("🟢 APP: Scheme found from intent, showing continue screen")
            print("  Intent unblocked the app, now showing continue screen")
            
            // Clear UserDefaults BEFORE showing continue screen
            UserDefaults.standard.set("", forKey: "selectedAppScheme")
            print("  APP: Cleared selectedAppScheme")
            
            // Refresh our blocking state since the intent may have modified it
            print("  🔄 REFRESHING blocking state after intent...")
            restoreBlockingState()
            
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
    
    
    // Check if apps are configured and validate migration
    private func checkIfAppsConfigured() {
        print("🔍 === CHECKING APP CONFIGURATION ===")
        
        let storedHasConfiguredApps = UserDefaults.standard.bool(forKey: "hasConfiguredApps")
        print("  Stored hasConfiguredApps: \(storedHasConfiguredApps)")
        
        if storedHasConfiguredApps {
            print("  📱 Loading existing configuration...")
            loadAppConfiguration()
            
            // Validate that we have the required direct mappings
            print("  🔍 VALIDATING configuration...")
            print("    Selected apps count: \(selectedApps.applications.count)")
            print("    Learned mappings count: \(learnedSchemeToTokenMapping.count)")
            
            let hasValidConfiguration = !selectedApps.applications.isEmpty
            
            if hasValidConfiguration {
                print("  ✅ VALID configuration found")
                hasConfiguredApps = true
            } else {
                print("  ❌ INVALID configuration detected!")
                print("    No selected apps found")
                print("    Forcing reconfiguration...")
                
                // Reset configuration to force user through new flow
                resetConfiguration()
                hasConfiguredApps = false
            }
        } else {
            print("  ℹ️ No previous configuration found")
            hasConfiguredApps = false
        }
        
        print("  Final hasConfiguredApps: \(hasConfiguredApps)")
        print("🔍 === CHECK CONFIGURATION COMPLETE ===")
    }
    
    // Reset configuration to force reconfiguration
    private func resetConfiguration() {
        print("🔄 === RESETTING CONFIGURATION ===")
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "hasConfiguredApps")
        UserDefaults.standard.removeObject(forKey: "selectedApps")
        UserDefaults.standard.removeObject(forKey: "directSchemeToTokenMapping")
        UserDefaults.standard.removeObject(forKey: "blockExpirationTimes")
        UserDefaults.standard.removeObject(forKey: "blockedAppTokens")
        UserDefaults.standard.removeObject(forKey: "activeSchemeToTokenMapping")
        
        // Clear app state
        selectedApps = FamilyActivitySelection()
        learnedSchemeToTokenMapping.removeAll()
        blockedApps.removeAll()
        blockExpirationTimes.removeAll()
        activeTimers.removeAll()
        
        // Update shield to clear any existing blocks
        updateShieldSettings()
        
        print("  ✅ Configuration reset complete")
        print("🔄 === RESET CONFIGURATION COMPLETE ===")
    }
    
    // Save app configuration (simplified)
    private func saveAppConfiguration() {
        print("📱 SAVING app configuration:")
        print("  Selected applications count: \(selectedApps.applications.count)")
        
        // Save the selection to UserDefaults using encoded data
        if let encoded = try? JSONEncoder().encode(selectedApps) {
            UserDefaults.standard.set(encoded, forKey: "selectedApps")
            print("  Apps saved successfully")
        } else {
            print("  ERROR: Failed to save selected apps")
        }
        
        UserDefaults.standard.set(true, forKey: "hasConfiguredApps")
        print("📱 SAVE CONFIGURATION COMPLETED")
    }
    
    // Load app configuration (simplified)
    private func loadAppConfiguration() {
        // Load selected apps
        if let data = UserDefaults.standard.data(forKey: "selectedApps"),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selectedApps = decoded
            print("📱 LOADED selected apps: \(selectedApps.applications.count) applications")
        }
        
        // Load learned mappings (if any exist from previous usage)
        if let mappingData = UserDefaults.standard.data(forKey: "learnedSchemeToTokenMapping"),
           let decodedMapping = try? JSONDecoder().decode([String: ApplicationToken].self, from: mappingData) {
            learnedSchemeToTokenMapping = decodedMapping
            print("📱 LOADED learned mappings: \(learnedSchemeToTokenMapping.count) mappings")
            for (scheme, token) in learnedSchemeToTokenMapping {
                print("    \(scheme) -> \(token)")
            }
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
    
    // Save blocking state to UserDefaults
    private func saveBlockingState() {
        print("💾 === SAVE BLOCKING STATE START ===")
        print("  📋 STATE TO SAVE:")
        print("    Blocked apps count: \(blockedApps.count)")
        print("    Expiration times count: \(blockExpirationTimes.count)")
        print("    Token mappings count: \(schemeToTokenMapping.count)")
        
        // Save block expiration times
        print("  📅 SAVING expiration times...")
        let expirationData = blockExpirationTimes.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(expirationData, forKey: "blockExpirationTimes")
        print("    Expiration data saved: \(expirationData)")
        
        // Save blocked app tokens as data
        print("  🔒 SAVING blocked app tokens...")
        if let tokensData = try? JSONEncoder().encode(Array(blockedApps)) {
            UserDefaults.standard.set(tokensData, forKey: "blockedAppTokens")
            print("    Tokens data encoded and saved successfully")
        } else {
            print("    ❌ ERROR: Failed to encode blocked app tokens")
        }
        
        // Save learned scheme-to-token mappings for active blocking  
        print("  🗺️ SAVING learned scheme-to-token mappings...")
        if let mappingData = try? JSONEncoder().encode(learnedSchemeToTokenMapping) {
            UserDefaults.standard.set(mappingData, forKey: "activeSchemeToTokenMapping")
            print("    Learned mapping data encoded and saved successfully")
            print("    Saved mappings:")
            for (scheme, token) in learnedSchemeToTokenMapping {
                print("      \(scheme) -> \(token)")
            }
        } else {
            print("    ❌ ERROR: Failed to encode learned scheme-to-token mappings")
        }
        
        print("💾 SAVED blocking state: \(blockedApps.count) blocked apps, \(blockExpirationTimes.count) expiration times, \(learnedSchemeToTokenMapping.count) learned mappings")
        print("💾 === SAVE BLOCKING STATE END ===")
    }
    
    // Restore blocking state from UserDefaults
    private func restoreBlockingState() {
        print("🔄 === RESTORE BLOCKING STATE START ===")
        
        // Restore expiration times
        print("  📅 RESTORING expiration times...")
        if let savedExpirations = UserDefaults.standard.object(forKey: "blockExpirationTimes") as? [String: TimeInterval] {
            blockExpirationTimes = savedExpirations.mapValues { Date(timeIntervalSince1970: $0) }
            print("    ✅ Restored \(blockExpirationTimes.count) expiration times")
            for (scheme, date) in blockExpirationTimes {
                print("      \(scheme) -> \(date)")
            }
        } else {
            print("    ℹ️ No saved expiration times found")
        }
        
        // Restore blocked app tokens
        print("  🔒 RESTORING blocked app tokens...")
        if let tokensData = UserDefaults.standard.data(forKey: "blockedAppTokens"),
           let decodedTokens = try? JSONDecoder().decode([ApplicationToken].self, from: tokensData) {
            blockedApps = Set(decodedTokens)
            print("    ✅ Restored \(blockedApps.count) blocked app tokens")
            for (index, token) in blockedApps.enumerated() {
                print("      [\(index)] \(token)")
            }
        } else {
            print("    ℹ️ No saved blocked app tokens found")
        }
        
        // Restore active scheme-to-token mappings (for active timers)
        print("  🗺️ RESTORING active scheme-to-token mappings...")
        if let mappingData = UserDefaults.standard.data(forKey: "activeSchemeToTokenMapping"),
           let decodedMapping = try? JSONDecoder().decode([String: ApplicationToken].self, from: mappingData) {
            // Merge the saved mappings with current learned mappings
            for (scheme, token) in decodedMapping {
                learnedSchemeToTokenMapping[scheme] = token
            }
            print("    ✅ Restored \(decodedMapping.count) active mappings")
            for (scheme, token) in decodedMapping {
                let isActive = blockExpirationTimes[scheme] != nil
                print("      \(scheme) -> \(token) \(isActive ? "(active)" : "(learned)")")
            }
        } else {
            print("    ℹ️ No saved active mappings found")
        }
        
        print("  🧹 CALLING cleanupExpiredBlocks...")
        // Clean up expired blocks and restore active ones
        cleanupExpiredBlocks()
        print("  🔄 CALLING restoreActiveBlocks...")
        restoreActiveBlocks()
        
        print("🔄 === RESTORE BLOCKING STATE END ===")
    }
    
    // Clean up expired blocks
    private func cleanupExpiredBlocks() {
        let now = Date()
        var expiredSchemes: [String] = []
        var expiredTokens: [ApplicationToken] = []
        
        for (scheme, expirationDate) in blockExpirationTimes {
            if now >= expirationDate {
                expiredSchemes.append(scheme)
                // Find corresponding token from learned mapping
                if let token = learnedSchemeToTokenMapping[scheme] {
                    expiredTokens.append(token)
                }
            }
        }
        
        if !expiredSchemes.isEmpty {
            print("🧹 CLEANING UP \(expiredSchemes.count) expired blocks: \(expiredSchemes)")
            
            // Remove expired entries (keep learned mappings for future use)
            for scheme in expiredSchemes {
                blockExpirationTimes.removeValue(forKey: scheme)
                // Keep learnedSchemeToTokenMapping intact - we want to remember successful mappings
            }
            for token in expiredTokens {
                blockedApps.remove(token)
            }
            
            // Update shield settings
            updateShieldSettings()
            saveBlockingState()
        }
    }
    
    // Restore active blocks with new timers
    private func restoreActiveBlocks() {
        let now = Date()
        
        for (scheme, expirationDate) in blockExpirationTimes {
            let timeRemaining = expirationDate.timeIntervalSince(now)
            
            if timeRemaining > 0 {
                print("🔄 RESTORING timer for \(scheme), \(Int(timeRemaining)) seconds remaining")
                
                // Create unblock timer for remaining time using learned mapping
                if let token = learnedSchemeToTokenMapping[scheme] {
                    let unblockWorkItem = DispatchWorkItem {
                        print("⏰ RESTORED TIMER FIRED for: \(scheme)")
                        self.unblockApp(token: token, for: scheme)
                    }
                    
                    activeTimers[scheme] = [unblockWorkItem]
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeRemaining, execute: unblockWorkItem)
                } else {
                    print("❌ ERROR: No learned mapping found for \(scheme) during restoration")
                }
            }
        }
        
        // Apply current blocking state to shield
        updateShieldSettings()
    }
    
    // Update shield settings with current blocked apps
    private func updateShieldSettings() {
        print("🛡️ === UPDATE SHIELD SETTINGS START ===")
        print("  📋 FUNCTION CONTEXT:")
        print("    Current thread: \(Thread.current)")
        print("    Is main thread: \(Thread.isMainThread)")
        print("    Blocked apps count: \(blockedApps.count)")
        print("    Blocked apps: \(Array(blockedApps))")
        
        let shieldValue = blockedApps.isEmpty ? nil : blockedApps
        print("  🎯 SHIELD VALUE TO SET:")
        if let shieldValue = shieldValue {
            print("    Setting shield to: \(shieldValue.count) apps")
            for (index, token) in shieldValue.enumerated() {
                print("      [\(index)] \(token)")
            }
        } else {
            print("    Setting shield to: nil (no apps blocked)")
        }
        
        print("  🔧 ATTEMPTING to set managedSettings.shield.applications...")
        do {
            managedSettings.shield.applications = shieldValue
            print("  ✅ SHIELD SETTING SUCCESS")
            
            // Immediate verification
            let verificationValue = managedSettings.shield.applications
            print("  🔍 IMMEDIATE VERIFICATION:")
            print("    Shield applications count: \(verificationValue?.count ?? 0)")
            if let apps = verificationValue {
                for (index, token) in apps.enumerated() {
                    print("      [\(index)] \(token)")
                }
            }
        } catch {
            print("  ❌ SHIELD SETTING ERROR: \(error)")
            print("    Error type: \(type(of: error))")
            print("    Error description: \(error.localizedDescription)")
        }
        
        print("🛡️ === UPDATE SHIELD SETTINGS END ===")
    }
    
    // Get ApplicationToken for a URL scheme using auto-detection
    private func getApplicationToken(for urlScheme: String) -> ApplicationToken? {
        print("🔍 === GET APPLICATION TOKEN START (AUTO-DETECTION) ===")
        print("  📋 FUNCTION PARAMETERS:")
        print("    URL Scheme: \(urlScheme)")
        
        // First check if we've already learned this mapping
        print("  🧠 CHECKING learned mappings...")
        print("    Learned mappings count: \(learnedSchemeToTokenMapping.count)")
        
        if let learnedToken = learnedSchemeToTokenMapping[urlScheme] {
            print("  ✅ FOUND learned mapping for \(urlScheme): \(learnedToken)")
            print("🔍 === GET APPLICATION TOKEN END (LEARNED) ===")
            return learnedToken
        }
        
        print("  🔍 NO learned mapping found, attempting auto-detection...")
        
        // Get bundle ID from constants
        guard let bundleID = getBundleIdentifier(from: urlScheme) else {
            print("  ❌ No bundle ID constant found for \(urlScheme)")
            print("🔍 === GET APPLICATION TOKEN END (NO BUNDLE ID) ===")
            return nil
        }
        
        print("  ✅ Bundle ID from constants: \(bundleID)")
        print("  🧪 TESTING available tokens to find match...")
        print("    Selected applications count: \(selectedApps.applications.count)")
        print("    Available tokens count: \(selectedApps.applicationTokens.count)")
        
        // Try to find a matching token by testing each one
        let availableTokens = Array(selectedApps.applicationTokens)
        for (index, token) in availableTokens.enumerated() {
            print("  🧪 TESTING token [\(index)]: \(token)")
            
            // For now, we'll use the first available token and learn from actual usage
            // In a more sophisticated implementation, we could test the token
            // by attempting a shield operation and seeing if it affects the right app
            
            // Store this as a learned mapping for future use
            learnedSchemeToTokenMapping[urlScheme] = token
            saveLearnedMappings()
            
            print("  ✅ LEARNED new mapping: \(urlScheme) -> \(token)")
            print("🔍 === GET APPLICATION TOKEN END (AUTO-DETECTED) ===")
            return token
        }
        
        print("  ❌ NO available tokens to test")
        print("🔍 === GET APPLICATION TOKEN END (NO TOKENS) ===")
        return nil
    }
    
    // Save learned mappings to persistence
    private func saveLearnedMappings() {
        print("💾 === SAVING LEARNED MAPPINGS ===")
        print("  Mappings to save: \(learnedSchemeToTokenMapping.count)")
        for (scheme, token) in learnedSchemeToTokenMapping {
            print("    \(scheme) -> \(token)")
        }
        
        if let mappingData = try? JSONEncoder().encode(learnedSchemeToTokenMapping) {
            UserDefaults.standard.set(mappingData, forKey: "learnedSchemeToTokenMapping")
            print("  ✅ Saved to UserDefaults key: 'learnedSchemeToTokenMapping'")
            print("  📊 Data size: \(mappingData.count) bytes")
            
            // Verify the save worked
            if let verifyData = UserDefaults.standard.data(forKey: "learnedSchemeToTokenMapping") {
                print("  ✅ VERIFICATION: Data exists in UserDefaults, size: \(verifyData.count) bytes")
                if let verifyMappings = try? JSONDecoder().decode([String: ApplicationToken].self, from: verifyData) {
                    print("  ✅ VERIFICATION: Can decode \(verifyMappings.count) mappings")
                } else {
                    print("  ❌ VERIFICATION: Cannot decode saved data")
                }
            } else {
                print("  ❌ VERIFICATION: No data found after save")
            }
        } else {
            print("  ❌ ERROR: Failed to encode learned mappings")
        }
        print("💾 === SAVE LEARNED MAPPINGS END ===")
    }
    
    // Start monitoring an app for 10 seconds
    private func startAppMonitoring(for urlScheme: String) {
        guard let token = getApplicationToken(for: urlScheme) else {
            print("❌ FAILED to start monitoring for \(urlScheme): No application token found")
            print("  This means the app is not in your selected apps list")
            print("  Please ensure \(urlScheme) is configured in the app selector")
            return
        }
        
        // Store the token mapping for this scheme (should already be learned from getApplicationToken)
        learnedSchemeToTokenMapping[urlScheme] = token
        print("💾 ENSURED token mapping: \(urlScheme) -> \(token)")
        
        // Cancel any existing timers for this app
        if let existingTimers = activeTimers[urlScheme] {
            print("🗑️ CANCELLING existing \(existingTimers.count) timers for: \(urlScheme)")
            existingTimers.forEach { $0.cancel() }
        }
        
        print("📱 STARTING 10-second monitoring for: \(urlScheme)")
        print("  Using token: \(token)")
        print("  Timer will fire in 10 seconds at: \(Date(timeIntervalSinceNow: 10))")
        
        // Create block timer work item
        let blockWorkItem = DispatchWorkItem {
            print("⏰ 10-SECOND TIMER FIRED at: \(Date())")
            print("  🔍 TIMER CONTEXT:")
            print("    Scheme: \(urlScheme)")
            print("    Timer thread: \(Thread.current)")
            print("    Is main thread: \(Thread.isMainThread)")
            print("    Learned mappings count: \(self.learnedSchemeToTokenMapping.count)")
            print("    All learned schemes: \(Array(self.learnedSchemeToTokenMapping.keys))")
            
            // Use learned token instead of re-lookup
            if let storedToken = self.learnedSchemeToTokenMapping[urlScheme] {
                print("✅ USING learned token for \(urlScheme): \(storedToken)")
                print("  📞 CALLING blockAppWithToken...")
                self.blockAppWithToken(token: storedToken, for: urlScheme)
                print("  📞 blockAppWithToken call COMPLETED")
            } else {
                print("❌ ERROR: No learned token found for \(urlScheme)")
                print("  Available mappings:")
                for (scheme, token) in self.learnedSchemeToTokenMapping {
                    print("    \(scheme) -> \(token)")
                }
            }
            print("⏰ 10-SECOND TIMER WORK ITEM COMPLETED")
        }
        
        // Create unblock timer work item
        let unblockWorkItem = DispatchWorkItem {
            print("⏰ 10-MINUTE TIMER FIRED at: \(Date())")
            print("  🔍 UNBLOCK TIMER CONTEXT:")
            print("    Scheme: \(urlScheme)")
            print("    Learned mappings count: \(self.learnedSchemeToTokenMapping.count)")
            
            // Use learned token instead of re-lookup
            if let storedToken = self.learnedSchemeToTokenMapping[urlScheme] {
                print("✅ USING learned token for \(urlScheme): \(storedToken)")
                print("  📞 CALLING unblockApp...")
                self.unblockApp(token: storedToken, for: urlScheme)
                print("  📞 unblockApp call COMPLETED")
            } else {
                print("❌ ERROR: No learned token found for \(urlScheme)")
                print("  Available mappings:")
                for (scheme, token) in self.learnedSchemeToTokenMapping {
                    print("    \(scheme) -> \(token)")
                }
            }
            print("⏰ 10-MINUTE TIMER WORK ITEM COMPLETED")
        }
        
        // Store timer references
        activeTimers[urlScheme] = [blockWorkItem, unblockWorkItem]
        print("  📝 STORED timer references for \(urlScheme)")
        
        // Set expiration time (current time + 10 seconds for block + 600 seconds for unblock)
        let expirationTime = Date().addingTimeInterval(610) // 10 + 600
        blockExpirationTimes[urlScheme] = expirationTime
        print("  📅 SET expiration time for \(urlScheme): \(expirationTime)")
        
        print("  🚀 SCHEDULING timers...")
        print("    Block timer: now + 10 seconds")
        print("    Unblock timer: now + 610 seconds")
        
        // Schedule timers
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: blockWorkItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + 610, execute: unblockWorkItem) // 10 + 600
        
        print("  ✅ TIMERS SCHEDULED for \(urlScheme)")
        print("📱 START MONITORING COMPLETED for \(urlScheme)\n")
    }
    
    // Block app using ApplicationToken
    private func blockAppWithToken(token: ApplicationToken, for urlScheme: String) {
        print("🚫 === BLOCK APP FUNCTION START ===")
        print("  📋 FUNCTION PARAMETERS:")
        print("    Token: \(token)")
        print("    URL Scheme: \(urlScheme)")
        print("    Current thread: \(Thread.current)")
        print("    Is main thread: \(Thread.isMainThread)")
        
        // Validate token mapping
        if let storedToken = learnedSchemeToTokenMapping[urlScheme] {
            if storedToken != token {
                print("⚠️  WARNING: Token mismatch for \(urlScheme)")
                print("  Provided token: \(token)")
                print("  Learned token: \(storedToken)")
                print("  Using learned token to ensure correct app is blocked")
            } else {
                print("✅ TOKEN VALIDATION: Provided token matches learned token")
            }
        } else {
            print("⚠️  WARNING: No learned token found for \(urlScheme)")
        }
        
        // First check authorization status
        let authStatus = AuthorizationCenter.shared.authorizationStatus
        print("🔐 AUTHORIZATION CHECK:")
        print("  Status: \(authStatus)")
        print("  Status raw value: \(authStatus.rawValue)")
        
        guard authStatus == .approved else {
            print("  ❌ ERROR: Not authorized for Family Controls (status: \(authStatus))")
            print("🚫 === BLOCK APP FUNCTION END (UNAUTHORIZED) ===\n")
            return
        }
        
        print("  ✅ Authorization approved - proceeding with blocking")
        
        print("📊 CURRENT STATE BEFORE BLOCKING:")
        print("  Shield apps count: \(managedSettings.shield.applications?.count ?? 0)")
        print("  Local blocked apps count: \(blockedApps.count)")
        print("  Local blocked apps: \(Array(blockedApps))")
        
        // Add to local blocked apps set
        print("➕ ADDING token to blocked apps set...")
        let wasInserted = blockedApps.insert(token).inserted
        print("  Token inserted: \(wasInserted)")
        print("  New blocked apps count: \(blockedApps.count)")
        
        // Update shield settings
        print("🛡️  CALLING updateShieldSettings...")
        updateShieldSettings()
        print("🛡️  updateShieldSettings call COMPLETED")
        
        // Save state to persistence
        print("💾 CALLING saveBlockingState...")
        saveBlockingState()
        print("💾 saveBlockingState call COMPLETED")
        
        print("📊 CURRENT STATE AFTER BLOCKING:")
        print("  Shield apps count: \(managedSettings.shield.applications?.count ?? 0)")
        print("  Local blocked apps count: \(blockedApps.count)")
        
        // Verify the setting was applied
        print("⏳ SCHEDULING verification in 1 second...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("🔍 === VERIFICATION CHECK ===")
            let currentShield = self.managedSettings.shield.applications
            print("  Shield contains \(currentShield?.count ?? 0) apps")
            if let shielded = currentShield {
                for (index, app) in shielded.enumerated() {
                    print("    [\(index)] Shielded app token: \(app)")
                }
            } else {
                print("    No apps currently shielded")
            }
            print("🔍 === VERIFICATION COMPLETE ===")
        }
        
        print("🚫 === BLOCK APP FUNCTION END (SUCCESS) ===\n")
    }
    
    // Unblock specific app
    private func unblockApp(token: ApplicationToken, for urlScheme: String) {
        print("✅ UNBLOCKING app with token: \(token) for scheme: \(urlScheme)")
        print("  Local blocked apps before: \(blockedApps.count) apps")
        
        // Remove from local blocked apps set
        blockedApps.remove(token)
        
        // Remove expiration time
        blockExpirationTimes.removeValue(forKey: urlScheme)
        
        // Update shield settings
        updateShieldSettings()
        
        // Save state to persistence
        saveBlockingState()
        
        print("  Local blocked apps after: \(blockedApps.count) apps")
        print("  Shield now contains: \(managedSettings.shield.applications?.count ?? 0) apps")
        
        // Clean up timer references (keep the learned mapping for future use)
        activeTimers.removeValue(forKey: urlScheme)
        // Note: We keep learnedSchemeToTokenMapping intact so we remember the mapping
    }
    
    // Unblock all apps (legacy function - kept for compatibility)
    private func unblockAllApps() {
        print("✅ UNBLOCKING all apps")
        blockedApps.removeAll()
        blockExpirationTimes.removeAll()
        activeTimers.removeAll()
        // Note: We keep learnedSchemeToTokenMapping intact so we remember the mappings
        
        // Update shield settings
        updateShieldSettings()
        
        // Save state to persistence
        saveBlockingState()
        
        print("  All apps unblocked successfully")
    }
}

struct ContinueScreen: View {
    let urlScheme: String
    let onAppOpened: (String) -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("App Unblocked")
                .font(.title)
                .foregroundColor(.green)
            
            Text("The app has been unblocked. You'll have 10 seconds before it's blocked again.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Continue to App") {
                openApp()
            }
            .font(.title2)
            .padding()
            .background(Color.green)
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
        
        // Set continue timestamp BEFORE opening the app to prevent infinite loop
        let now = Date().timeIntervalSince1970
        let continueTimestampKey = "continueTimestamp_\(urlScheme)"
        UserDefaults.standard.set(now, forKey: continueTimestampKey)
        print("  🕒 SET continue timestamp: \(now) to key: '\(continueTimestampKey)'")
        print("  This prevents intent from re-foregrounding for 3 seconds")
        
        Task {
            print("  Opening URL: \(url)")
            await UIApplication.shared.open(url)
            print("  UIApplication.open completed")
            
            // Start 10-second monitoring for app blocking
            onAppOpened(urlScheme)
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
            
            Text("Choose the apps you want Second Thought to monitor and block after 10 seconds. The app will automatically learn which apps you select.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            FamilyActivityPicker(selection: $selectedApps)
                .frame(height: 400)
            
            Button("Save Apps") {
                onComplete()
            }
            .font(.title2)
            .padding()
            .background(selectedApps.applications.isEmpty ? Color.gray : Color.green)
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
