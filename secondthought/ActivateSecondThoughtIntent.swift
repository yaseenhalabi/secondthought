import AppIntents
import SwiftUI
import UIKit

struct ActivateSecondThoughtIntent: AppIntent {
    static var title: LocalizedStringResource = "Activate Second Thought"
    static var description = IntentDescription("Activate Second Thought for an app")
    static var supportedModes: IntentModes = [.background, .foreground(.dynamic)]
    
    @Parameter(title: "URL Scheme", description: "Enter the app's URL scheme (e.g. instagram://)")
    var urlScheme: String
    
    func perform() async throws -> some IntentResult {
        let currentScheme = UserDefaults.standard.string(forKey: "selectedAppScheme") ?? ""
        let timestampKey = "schemeLastUpdated_\(urlScheme)"
        let lastUpdated = UserDefaults.standard.double(forKey: timestampKey)
        let now = Date().timeIntervalSince1970
        let timeSinceUpdate = now - lastUpdated
        let cooldownPeriod: Double = 10.0 // 10 seconds
        
        print("🔵 INTENT START:")
        print("  Input urlScheme: '\(urlScheme)'")
        print("  Per-app timestamp key: '\(timestampKey)'")
        print("  Current scheme in UserDefaults: '\(currentScheme)'")
        print("  Last updated timestamp: \(lastUpdated)")
        print("  Current timestamp: \(now)")
        print("  Time since update: \(timeSinceUpdate) seconds")
        print("  Cooldown period: \(cooldownPeriod) seconds")
        
        // Simple logic: Allow first-time use OR require cooldown for subsequent uses
        let isFirstTime = lastUpdated == 0.0
        let cooldownPassed = timeSinceUpdate > cooldownPeriod
        
        print("  Is first time (timestamp = 0): \(isFirstTime)")
        print("  Cooldown passed: \(cooldownPassed)")
        
        let shouldUpdate = isFirstTime || cooldownPassed
        print("  Should update: \(shouldUpdate)")
        
        if shouldUpdate {
            print("🟢 PROCEEDING - Saving URL scheme: \(urlScheme)")
            UserDefaults.standard.set(urlScheme, forKey: "selectedAppScheme")
            UserDefaults.standard.set(now, forKey: timestampKey)
            print("  Saved scheme: '\(urlScheme)'")
            print("  Saved timestamp: \(now) to key: '\(timestampKey)'")
            
            do {
                print("  Calling continueInForeground...")
                try await continueInForeground(alwaysConfirm: false)
                print("  continueInForeground completed")
            } catch {
                print("  ERROR: Couldn't bring app to foreground: \(error)")
            }
        } else {
            print("🔴 BLOCKED - Skipping due to cooldown")
        }
        
        print("🔵 INTENT END\n")
        return .result()
    }
}
