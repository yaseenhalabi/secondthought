import AppIntents
import SwiftUI
import UIKit
import FamilyControls
import ManagedSettings

struct ActivateSecondThoughtIntent: AppIntent {
    static var title: LocalizedStringResource = "Activate Second Thought"
    static var description = IntentDescription("Activate Second Thought for an app")
    static var supportedModes: IntentModes = [.background, .foreground(.dynamic)]
    
    @Parameter(title: "URL Scheme", description: "Enter the app's URL scheme (e.g. instagram://)")
    var urlScheme: String
    
    func perform() async throws -> some IntentResult {
        let now = Date().timeIntervalSince1970
        
        print("🔵 INTENT START:")
        print("  Input urlScheme: '\(urlScheme)'")
        print("  Current timestamp: \(now)")
        
        // Always unblock the app first
        print("🔓 UNBLOCKING app for scheme: \(urlScheme)")
        await unblockAppForScheme(urlScheme)
        
        // Check if user recently continued this app (3-second cooldown)
        let continueKey = "continueTimestamp_\(urlScheme)"
        let lastContinueTime = UserDefaults.standard.double(forKey: continueKey)
        let timeSinceContinue = now - lastContinueTime
        let continueCooldownPeriod: Double = 3.0 // 3 seconds
        
        print("📅 CONTINUE COOLDOWN CHECK:")
        print("  Continue timestamp key: '\(continueKey)'")
        print("  Last continue time: \(lastContinueTime)")
        print("  Time since continue: \(timeSinceContinue) seconds")
        print("  Continue cooldown period: \(continueCooldownPeriod) seconds")
        
        let recentlyContinued = lastContinueTime > 0 && timeSinceContinue < continueCooldownPeriod
        print("  Recently continued: \(recentlyContinued)")
        
        if recentlyContinued {
            print("🟡 SKIPPING foreground - User recently continued this app")
            print("  App was unblocked but SecondThought won't foreground")
        } else {
            print("🟢 PROCEEDING - Saving URL scheme and foregrounding SecondThought")
            UserDefaults.standard.set(urlScheme, forKey: "selectedAppScheme")
            print("  Saved scheme: '\(urlScheme)'")
            
            do {
                print("  Calling continueInForeground...")
                try await continueInForeground(alwaysConfirm: false)
                print("  continueInForeground completed")
            } catch {
                print("  ERROR: Couldn't bring app to foreground: \(error)")
            }
        }
        
        print("🔵 INTENT END\n")
        return .result()
    }
    
    // Unblock the app for the given URL scheme
    private func unblockAppForScheme(_ urlScheme: String) async {
        print("🔓 === UNBLOCK APP FOR SCHEME START ===")
        print("  URL Scheme: \(urlScheme)")
        
        // Get the application token for this scheme
        guard let token = getApplicationTokenForScheme(urlScheme) else {
            print("  ❌ No application token found for scheme: \(urlScheme)")
            print("🔓 === UNBLOCK APP FOR SCHEME END (NO TOKEN) ===")
            return
        }
        
        print("  ✅ Found token for scheme: \(token)")
        
        // Load current blocking state
        var blockedApps = loadBlockedApps()
        print("  📊 Current blocked apps count: \(blockedApps.count)")
        
        // Remove this app from blocked apps
        let wasRemoved = blockedApps.remove(token) != nil
        print("  🗑️ Removed from blocked apps: \(wasRemoved)")
        
        if wasRemoved {
            // Update the shield settings
            let managedSettings = ManagedSettingsStore(named: .init("SecondThoughtStore"))
            do {
                managedSettings.shield.applications = blockedApps.isEmpty ? nil : blockedApps
                print("  🛡️ Shield updated successfully")
                print("  📊 Shield now contains: \(blockedApps.count) apps")
                
                // Save the updated blocked apps
                saveBlockedApps(blockedApps)
                print("  💾 Updated blocked apps saved")
            } catch {
                print("  ❌ ERROR updating shield: \(error)")
            }
        }
        
        print("🔓 === UNBLOCK APP FOR SCHEME END ===")
    }
    
    // Get application token for URL scheme using learned mappings
    private func getApplicationTokenForScheme(_ urlScheme: String) -> ApplicationToken? {
        // Load learned mappings
        guard let mappingData = UserDefaults.standard.data(forKey: "learnedSchemeToTokenMapping"),
              let learnedMappings = try? JSONDecoder().decode([String: ApplicationToken].self, from: mappingData) else {
            print("  ❌ No learned mappings found")
            return nil
        }
        
        print("  📊 Available learned mappings: \(learnedMappings.count)")
        for (scheme, token) in learnedMappings {
            let isMatch = scheme == urlScheme
            print("    \(scheme) -> \(token) \(isMatch ? "← MATCH!" : "")")
        }
        
        return learnedMappings[urlScheme]
    }
    
    // Load blocked apps from UserDefaults
    private func loadBlockedApps() -> Set<ApplicationToken> {
        guard let tokensData = UserDefaults.standard.data(forKey: "blockedAppTokens"),
              let decodedTokens = try? JSONDecoder().decode([ApplicationToken].self, from: tokensData) else {
            return Set<ApplicationToken>()
        }
        return Set(decodedTokens)
    }
    
    // Save blocked apps to UserDefaults
    private func saveBlockedApps(_ blockedApps: Set<ApplicationToken>) {
        if let tokensData = try? JSONEncoder().encode(Array(blockedApps)) {
            UserDefaults.standard.set(tokensData, forKey: "blockedAppTokens")
        }
    }
}
